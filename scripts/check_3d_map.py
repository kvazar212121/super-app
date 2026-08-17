#!/usr/bin/env python3
"""3D xarita HAQIQATAN binolarni ko'taradimi — brauzerda RENDER qilib tekshiradi.

Nega bu skript bor:
    Foydalanuvchi birinchi urinishni rad etdi: "sen shunchaki chiqarib
    berilayotgan xaritani qiyshaytirib qo'ygansan xolos". Haq edi.
    Shundan keyin kod testlari ("pitch bormi?", "style to'g'rimi?")
    yetarli emasligi ayon bo'ldi: ular soxta 3D ni ham o'tkazib
    yuborardi.

    Bu skript ilovadagi AYNAN sozlamalar (streets-v4, pitch=60,
    zoom=16.5) bilan xaritani haqiqiy brauzerda render qiladi va
    MapLibre'ning o'zidan so'raydi: nechta bino ko'rinmoqda,
    balandliklari qanday, kamera qanday egilgan.

Ishlatish:
    python3 scripts/check_3d_map.py                 # kalit .env.local dan
    MAPTILER_KEY=... python3 scripts/check_3d_map.py

Chrome (yoki chromium) talab qiladi. Bo'lmasa SKIP bo'ladi.
"""
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import http.server
import socketserver

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Ilovadagi qiymatlar bilan MOS bo'lishi shart — ular shu yerdan
# emas, manba kodidan o'qiladi, shunda kod o'zgarsa test ham
# o'zgargan qiymatni sinaydi.
NAV_EKRAN = os.path.join(ROOT, "lib/screens/navigation_3d_screen.dart")
KONFIG = os.path.join(ROOT, "lib/config/map_config.dart")

ok, fail = [], []


def check(name, cond, detail=""):
    (ok if cond else fail).append(f"{name}{'' if cond else ': ' + detail}")


def kalit() -> str:
    k = os.environ.get("MAPTILER_KEY", "")
    if k:
        return k
    env = os.path.join(ROOT, ".env.local")
    if os.path.exists(env):
        for line in open(env):
            if line.startswith("MAPTILER_KEY="):
                return line.split("=", 1)[1].strip()
    return ""


def kod_qiymati(fayl: str, naqsh: str, nom: str):
    """Manba kodidan sonli/matnli qiymatni o'qiydi."""
    m = re.search(naqsh, open(fayl).read())
    if not m:
        check(f"{nom} manba kodidan o'qildi", False, f"topilmadi: {naqsh}")
        return None
    return m.group(1)


def chrome() -> str | None:
    for c in ("google-chrome", "chromium", "chromium-browser"):
        p = shutil.which(c)
        if p:
            return p
    return None


HTML = """<!DOCTYPE html>
<html><head><meta charset="utf-8"/>
<script src="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.js"></script>
<link href="https://unpkg.com/maplibre-gl@4.7.1/dist/maplibre-gl.css" rel="stylesheet"/>
<style>body{margin:0}#m{width:900px;height:700px}</style></head>
<body><div id="m"></div>
<script>
const map = new maplibregl.Map({
  container: 'm',
  style: 'STYLE_URL',
  center: [69.2401, 41.3110],
  zoom: ZOOM,
  pitch: PITCH,
  bearing: 45,
});
map.on('load', () => setTimeout(() => {
  const ext = map.getStyle().layers.filter(l => l.type === 'fill-extrusion');
  let b = [];
  try { b = map.queryRenderedFeatures({layers: ext.map(l => l.id)}); } catch (e) {}
  const natija = {
    ok: true,
    ext_layers: ext.map(l => l.id),
    buildings: b.length,
    heights: b.map(f => f.properties.height).filter(h => h).slice(0, 20),
    pitch: map.getPitch(),
    zoom: map.getZoom(),
  };
  const d = document.createElement('pre');
  d.id = 'natija';
  d.style.cssText = 'position:absolute;top:0;left:0;background:#fff;z-index:9';
  d.textContent = ['<<N', JSON.stringify(natija), 'N>>'].join('');
  document.body.appendChild(d);
}, 4000));
map.on('error', e => {
  const d = document.createElement('pre');
  d.textContent = ['<<N', JSON.stringify({ok: false, xato: String(e.error && e.error.message)}), 'N>>'].join('');
  document.body.appendChild(d);
});
</script></body></html>
"""


def main():
    k = kalit()
    if not k:
        print("SKIP: MAPTILER_KEY yo'q (.env.local yoki muhit o'zgaruvchisi)")
        return 0

    ch = chrome()
    if not ch:
        print("SKIP: Chrome/Chromium topilmadi")
        return 0

    # Ilovadagi haqiqiy qiymatlar
    pitch = kod_qiymati(NAV_EKRAN, r"_pitch\s*=\s*([\d.]+)", "pitch")
    zoom = kod_qiymati(NAV_EKRAN, r"initZoom:\s*([\d.]+)", "zoom")
    style = kod_qiymati(KONFIG, r"String style = '([\w-]+)'", "style")
    if not (pitch and zoom and style):
        return 1

    check("ilovada 3D style ishlatiladi (v4)", style.endswith("-v4"), style)
    check("pitch 3D uchun yetarli", float(pitch) >= 45, pitch)
    check("zoom binolar ko'rinadigan darajada (>=15)",
          float(zoom) >= 15, zoom)

    style_url = f"https://api.maptiler.com/maps/{style}/style.json?key={k}"
    html = (HTML.replace("STYLE_URL", style_url)
                .replace("PITCH", pitch)
                .replace("ZOOM", zoom))

    tmp = tempfile.mkdtemp(prefix="map3d_")
    with open(os.path.join(tmp, "index.html"), "w") as f:
        f.write(html)

    os.chdir(tmp)
    handler = http.server.SimpleHTTPRequestHandler
    socketserver.TCPServer.allow_reuse_address = True
    srv = socketserver.TCPServer(("127.0.0.1", 0), handler)
    port = srv.server_address[1]
    threading.Thread(target=srv.serve_forever, daemon=True).start()

    shot = os.path.join(tmp, "shot.png")
    dump = os.path.join(tmp, "dump.txt")
    try:
        with open(dump, "w") as out:
            subprocess.run([
                ch, "--headless", "--disable-gpu", "--no-sandbox",
                "--use-gl=swiftshader", "--enable-unsafe-swiftshader",
                "--window-size=900,700", "--virtual-time-budget=60000",
                f"--screenshot={shot}", "--dump-dom",
                f"http://127.0.0.1:{port}/index.html",
            ], stdout=out, stderr=subprocess.DEVNULL, timeout=180)
    except subprocess.TimeoutExpired:
        check("brauzer render qildi", False, "vaqt tugadi")
        return xulosa()
    finally:
        srv.shutdown()

    matn = open(dump).read() if os.path.exists(dump) else ""
    # Belgi DOM ichida kodlangan holda keladi (&lt;&lt;N...)
    m = re.search(r"(?:&lt;|<)&lt;?N(\{.*?\})N(?:&gt;|>)", matn, re.S)
    check("brauzer natija qaytardi", m is not None,
          "xarita yuklanmadi yoki JS xatosi")
    if not m:
        return xulosa()

    # DOM'da &quot; kabi HTML belgilar kodlangan bo'ladi.
    import html as _html
    xom = _html.unescape(m.group(1))
    try:
        r = json.loads(xom)
    except json.JSONDecodeError as exc:
        check("natijani o'qish", False, f"{exc}: {xom[:120]}")
        return xulosa()
    check("xarita xatosiz yuklandi", r.get("ok") is True,
          str(r.get("xato"))[:120])
    if not r.get("ok"):
        return xulosa()

    check("3D binolar qatlami FAOL",
          "Building 3D" in (r.get("ext_layers") or []),
          str(r.get("ext_layers")))

    binolar = r.get("buildings", 0)
    check("ekranda binolar HAQIQATAN render qilinmoqda",
          binolar > 10, f"faqat {binolar} ta")

    h = r.get("heights") or []
    check("binolarda haqiqiy balandlik bor (3D hajm)",
          len(h) > 5 and max(h) > 10,
          f"{len(h)} ta, eng balandi {max(h) if h else 0}m")

    check("kamera egilgan (tepadan ko'rinish EMAS)",
          abs(r.get("pitch", 0) - float(pitch)) < 1,
          f"kutilgan {pitch}, keldi {r.get('pitch')}")
    check("zoom kod bilan mos",
          abs(r.get("zoom", 0) - float(zoom)) < 0.1,
          f"kutilgan {zoom}, keldi {r.get('zoom')}")

    if os.path.exists(shot) and os.path.getsize(shot) > 100_000:
        check("render bo'sh emas (skrinshot to'lgan)", True)
        saqla = os.path.join(ROOT, "build", "map3d_tekshiruv.png")
        os.makedirs(os.path.dirname(saqla), exist_ok=True)
        shutil.copy(shot, saqla)
        print(f"Skrinshot: {saqla}")
    else:
        check("render bo'sh emas (skrinshot to'lgan)", False,
              "rasm juda kichik — xarita chizilmagan")

    return xulosa()


def xulosa():
    print()
    for x in ok:
        print("  ✓", x)
    if fail:
        print(f"\nYIQILDI ({len(fail)}):")
        for x in fail:
            print("  ✗", x)
        return 1
    print(f"\nOK: {len(ok)} ta tekshiruv o'tdi")
    return 0


sys.exit(main())
