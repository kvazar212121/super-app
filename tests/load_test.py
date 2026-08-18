#!/usr/bin/env python3
"""YUKLAMA TESTI — tizim nechta foydalanuvchini ko'tara oladi.

Nega kerak: "1 mln foydalanuvchi ko'taradimi?" degan savolga taxmin
bilan javob berib bo'lmaydi. Bu skript HAQIQIY so'rovlar yuborib
o'lchaydi: javob vaqti, sig'im (RPS), xatolar ulushi.

O'lchanadigan qismlar:
  1. Oddiy o'qish (health) — tarmoq va nginx chegarasi
  2. Autentifikatsiyali o'qish — baza bilan ishlash
  3. Qidiruv (og'ir so'rov) — indeks va JOIN yuklamasi
  4. WebSocket — bir vaqtda nechta ulanish

Ishlatish:
    python3 tests/load_test.py --url https://hubservis.uz --users 50
    python3 tests/load_test.py --url http://127.0.0.1:8000 --users 200

⚠️ ISHCHI serverda yurgizishdan oldin o'ylang: bu haqiqiy yuklama.
   Tungi vaqtda yoki alohida stend'da yurgizing.
"""
from __future__ import annotations

import argparse
import asyncio
import json
import statistics
import sys
import time

try:
    import httpx
except ImportError:
    print("httpx kerak: pip install httpx")
    sys.exit(1)


class Natija:
    """Bitta bosqich o'lchovlari."""

    def __init__(self, nom: str):
        self.nom = nom
        self.vaqtlar: list[float] = []
        self.xatolar: list[str] = []
        self.boshlandi = time.time()

    def qosh(self, davomiylik: float, xato: str | None = None):
        if xato:
            self.xatolar.append(xato)
        else:
            self.vaqtlar.append(davomiylik)

    def hisobot(self) -> dict:
        umumiy_vaqt = max(time.time() - self.boshlandi, 0.001)
        jami = len(self.vaqtlar) + len(self.xatolar)
        v = sorted(self.vaqtlar)
        return {
            "nom": self.nom,
            "jami": jami,
            "muvaffaqiyat": len(self.vaqtlar),
            "xato": len(self.xatolar),
            "xato_ulushi": (len(self.xatolar) / jami * 100) if jami else 0,
            "rps": jami / umumiy_vaqt,
            "ortacha_ms": (statistics.mean(v) * 1000) if v else 0,
            "median_ms": (statistics.median(v) * 1000) if v else 0,
            "p95_ms": (v[int(len(v) * 0.95)] * 1000) if len(v) > 20 else
                      ((v[-1] * 1000) if v else 0),
            "eng_uzun_ms": (v[-1] * 1000) if v else 0,
            "xato_namuna": self.xatolar[:3],
        }


async def _urin(client: httpx.AsyncClient, natija: Natija, metod: str,
                yol: str, **kw) -> None:
    boshi = time.perf_counter()
    try:
        r = await client.request(metod, yol, **kw)
        davom = time.perf_counter() - boshi
        if r.status_code >= 500:
            natija.qosh(davom, f"HTTP {r.status_code}")
        elif r.status_code == 429:
            natija.qosh(davom, "429 rate-limit")
        else:
            natija.qosh(davom)
    except Exception as exc:
        natija.qosh(time.perf_counter() - boshi, f"{type(exc).__name__}")


async def bosqich(nom: str, url: str, yol: str, foydalanuvchi: int,
                  takror: int, headers: dict | None = None) -> dict:
    """Bir nechta "foydalanuvchi" bir vaqtda so'rov yuboradi."""
    natija = Natija(nom)
    limits = httpx.Limits(max_connections=foydalanuvchi + 10,
                          max_keepalive_connections=foydalanuvchi)

    async with httpx.AsyncClient(base_url=url, timeout=30.0,
                                 limits=limits, headers=headers or {},
                                 verify=False) as client:
        async def ishchi():
            for _ in range(takror):
                await _urin(client, natija, "GET", yol)

        await asyncio.gather(*[ishchi() for _ in range(foydalanuvchi)])

    return natija.hisobot()


async def ws_bosqich(url: str, token: str, soni: int) -> dict:
    """Bir vaqtda nechta WebSocket ulanishi ushlab turiladi."""
    try:
        import websockets
    except ImportError:
        return {"nom": "WebSocket", "xato_namuna": ["websockets kerak"],
                "jami": 0, "muvaffaqiyat": 0, "xato": 0,
                "xato_ulushi": 0, "rps": 0, "ortacha_ms": 0,
                "median_ms": 0, "p95_ms": 0, "eng_uzun_ms": 0}

    natija = Natija("WebSocket ulanish")
    ws_url = url.replace("https://", "wss://").replace("http://", "ws://")
    ws_url = f"{ws_url}/api/v1/calls/ws?token={token}"

    ochiq = []

    async def ulan():
        boshi = time.perf_counter()
        try:
            ws = await websockets.connect(ws_url, open_timeout=20)
            ochiq.append(ws)
            natija.qosh(time.perf_counter() - boshi)
        except Exception as exc:
            natija.qosh(time.perf_counter() - boshi, f"{type(exc).__name__}")

    await asyncio.gather(*[ulan() for _ in range(soni)])
    # Ulanishlar TIRIK turganini tekshiramiz (server ularni uzmaydimi).
    await asyncio.sleep(3)
    # `websockets` 13+ da `closed` yo'q — `state` bilan tekshiramiz.
    def _tirikmi(w) -> bool:
        holat = getattr(w, "state", None)
        if holat is not None:
            return getattr(holat, "name", str(holat)) == "OPEN"
        return not getattr(w, "closed", True)

    tirik = sum(1 for w in ochiq if _tirikmi(w))
    for w in ochiq:
        try:
            await w.close()
        except Exception:
            pass

    h = natija.hisobot()
    h["tirik_ulanish"] = tirik
    return h


def chop(h: dict) -> None:
    print(f"\n── {h['nom']}")
    print(f"   so'rov      : {h['jami']}")
    print(f"   muvaffaqiyat: {h['muvaffaqiyat']}  |  xato: {h['xato']} "
          f"({h['xato_ulushi']:.1f}%)")
    print(f"   sig'im      : {h['rps']:.1f} so'rov/sek")
    print(f"   javob vaqti : o'rtacha {h['ortacha_ms']:.0f} ms")
    print(f"                 median {h['median_ms']:.0f} ms · "
          f"p95 {h['p95_ms']:.0f} ms · eng uzun {h['eng_uzun_ms']:.0f} ms")
    if h.get("tirik_ulanish") is not None:
        print(f"   tirik WS    : {h['tirik_ulanish']}")
    if h["xato_namuna"]:
        print(f"   xatolar     : {h['xato_namuna']}")


async def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--url", default="http://127.0.0.1:8000")
    p.add_argument("--users", type=int, default=30,
                   help="bir vaqtda so'rov yuboruvchilar soni")
    p.add_argument("--repeat", type=int, default=5,
                   help="har biri nechta so'rov yuboradi")
    p.add_argument("--phone", default="+998901234567")
    p.add_argument("--code", default="111111")
    p.add_argument("--ws", type=int, default=0,
                   help="nechta WebSocket ulanishi sinaladi")
    args = p.parse_args()

    print(f"YUKLAMA TESTI → {args.url}")
    print(f"  {args.users} ta parallel foydalanuvchi × {args.repeat} so'rov")

    hisobotlar = []

    # 1) Eng yengil yo'l — tarmoq va nginx chegarasi.
    hisobotlar.append(await bosqich(
        "Health (autentifikatsiyasiz)", args.url, "/api/v1/health",
        args.users, args.repeat))

    # 2) Token olamiz.
    token = ""
    async with httpx.AsyncClient(base_url=args.url, timeout=30.0,
                                 verify=False) as c:
        try:
            r = await c.post("/api/v1/auth/otp/verify",
                             json={"phone": args.phone, "code": args.code})
            token = r.json().get("access_token", "")
        except Exception as exc:
            print(f"  ⚠️ token olinmadi: {exc}")

    if token:
        h = {"Authorization": f"Bearer {token}"}

        # 3) Bazadan o'qish.
        hisobotlar.append(await bosqich(
            "Provayderlar ro'yxati (baza)", args.url,
            "/api/v1/providers?limit=20", args.users, args.repeat, h))

        # 4) Og'ir so'rov: qidiruv + masofa hisobi.
        hisobotlar.append(await bosqich(
            "Savdo qidiruvi (og'ir)", args.url,
            "/api/v1/marketplace/search?category=telefon&lat=41.3&lng=69.24",
            args.users, args.repeat, h))

        # 5) Ilova ochilishida chaqiriladigan yo'l.
        hisobotlar.append(await bosqich(
            "Bo'limlar bayrog'i (kesh)", args.url,
            "/api/v1/config/features", args.users, args.repeat))

        if args.ws:
            hisobotlar.append(await ws_bosqich(args.url, token, args.ws))
    else:
        print("  ⚠️ autentifikatsiyali bosqichlar o'tkazib yuborildi")

    for h in hisobotlar:
        chop(h)

    # ── Xulosa ───────────────────────────────────────────────────────
    print("\n" + "=" * 60)
    yomon = [h for h in hisobotlar if h["xato_ulushi"] > 1
             or h["p95_ms"] > 1000]
    if yomon:
        print("DIQQAT — quyidagilar chegaraga yaqin:")
        for h in yomon:
            print(f"  • {h['nom']}: xato {h['xato_ulushi']:.1f}%, "
                  f"p95 {h['p95_ms']:.0f} ms")
    else:
        print("Barcha bosqichlar sog'lom (xato < 1%, p95 < 1000 ms)")

    jami_rps = sum(h["rps"] for h in hisobotlar if h["muvaffaqiyat"])
    print(f"\nUmumiy o'lchangan sig'im: ~{jami_rps:.0f} so'rov/sek")
    print(json.dumps(hisobotlar, ensure_ascii=False, indent=1)[:0] or "", end="")


if __name__ == "__main__":
    asyncio.run(main())
