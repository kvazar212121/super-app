/* global document, localStorage, location, fetch, alert, confirm */
const API = "/api/v1";
let at = localStorage.getItem("at");
if (!at) {
  location.assign("/admin/login");
}
const h = { Authorization: "Bearer " + at, "Content-Type": "application/json" };
let oPage = 1;
let _catsById = {};

async function api(url, opt = {}) {
  const r = await fetch(url, { headers: h, ...opt });
  if (r.status === 401) {
    localStorage.removeItem("at");
    location.assign("/admin/login");
  }
  return r;
}

function logout() {
  localStorage.removeItem("at");
  location.assign("/admin/login");
}

async function loadCategoriesGlobal() {
  const r = await api(API + "/categories");
  if (!r.ok) return;
  const cats = await r.json();
  _catsById = {};
  const opts =
    '<option value="">Barcha</option>' +
    cats
      .map((c) => {
        _catsById[c.id] = c;
        return '<option value="' + c.id + '">' + esc(c.title_uz) + "</option>";
      })
      .join("");
  document.getElementById("ocategory").innerHTML = opts;
  document.getElementById("pnew_cat").innerHTML =
    '<option value="">—</option>' +
    cats
      .map((c) => '<option value="' + c.id + '">' + esc(c.title_uz) + "</option>")
      .join("");
  return cats;
}

function esc(s) {
  if (s == null) return "";
  return String(s)
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/"/g, "&quot;");
}

function showTab(name) {
  document.querySelectorAll(".tabs button").forEach((x) => {
    x.classList.toggle("active", x.dataset.tab === name);
  });
  document.querySelectorAll(".tab").forEach((t) => t.classList.add("hidden"));
  document.getElementById("tab-" + name).classList.remove("hidden");
  if (name === "dash") loadStats();
  else if (name === "orders") loadOrders();
  else if (name === "providers") loadProviders();
  else if (name === "categories") loadCategoriesTab();
}

document.querySelectorAll(".tabs button").forEach((b) => {
  b.onclick = () => showTab(b.dataset.tab);
});

async function loadStats() {
  const r = await api(API + "/admin/stats");
  if (!r.ok) return;
  const s = await r.json();
  document.getElementById("statsGrid").innerHTML =
    '<div class="stat"><span>Buyurtmalar</span><strong>' +
    s.orders_total +
    "</strong></div>" +
    '<div class="stat"><span>Provayderlar</span><strong>' +
    s.providers +
    "</strong></div>" +
    '<div class="stat"><span>Foydalanuvchilar</span><strong>' +
    s.users +
    "</strong></div>" +
    '<div class="stat"><span>Kategoriyalar</span><strong>' +
    s.categories +
    "</strong></div>";
  const br = document.getElementById("statusBreak");
  br.innerHTML = "";
  for (const [k, v] of Object.entries(s.orders_by_status || {})) {
    br.innerHTML += "<span><b>" + k + "</b>: " + v + "</span>";
  }
}

async function loadOrders(p = 1) {
  oPage = p;
  await loadCategoriesGlobal();
  const s = document.getElementById("ostatus").value;
  const c = document.getElementById("ocategory").value;
  let url = API + "/admin/orders?page=" + p + "&per_page=15";
  if (s) url += "&status=" + encodeURIComponent(s);
  if (c) url += "&category_id=" + encodeURIComponent(c);
  const r = await api(url);
  const d = await r.json();
  let row = "";
  (d.items || []).forEach((o) => {
    row +=
      "<tr><td>" +
      o.id +
      "</td><td>" +
      esc(o.service_name) +
      "</td><td>" +
      (o.price ?? "") +
      " so'm</td>" +
      '<td><span class="badge ' +
      o.status +
      '">' +
      (o.status || "") +
      "</span></td><td>" +
      esc(o.date || "") +
      "</td><td>" +
      (o.user_id ?? "") +
      "</td>" +
      '<td><select onchange="changeStatus(' +
      o.id +
      ',this.value)"><option value="">Status</option>' +
      '<option value="confirmed">Tasdiqlash</option><option value="in_progress">Jarayon</option>' +
      '<option value="completed">Yakunlash</option><option value="cancelled">Bekor</option></select></td></tr>';
  });
  document.getElementById("otbody").innerHTML =
    row || "<tr><td colspan=\"7\">Buyurtmalar yo'q</td></tr>";
  let pg = "";
  const pages = d.pages || 1;
  for (let i = 1; i <= pages; i++) {
    pg +=
      '<button type="button" class="sm' +
      (i === p ? " btn primary" : "") +
      '" onclick="loadOrders(' +
      i +
      ')">' +
      i +
      "</button>";
  }
  document.getElementById("opages").innerHTML = pg;
}

async function changeStatus(id, st) {
  if (!st) return;
  await api(API + "/admin/orders/" + id + "/status", {
    method: "PATCH",
    body: JSON.stringify({ status: st }),
  });
  loadOrders(oPage);
}

async function loadProviders() {
  await loadCategoriesGlobal();
  const r = await api(API + "/providers?per_page=200");
  const d = await r.json();
  let html = "";
  (d.items || []).forEach((p) => {
    const cn = _catsById[p.category_id]
      ? _catsById[p.category_id].title_uz
      : "#" + p.category_id;
    html +=
      "<tr><td>" +
      p.id +
      "</td><td>" +
      esc(p.name) +
      "</td><td>" +
      esc(cn) +
      "</td><td>" +
      esc(p.address) +
      "</td><td>" +
      esc(p.phone) +
      "</td><td>" +
      (p.rating ?? "") +
      "</td>" +
      '<td><button type="button" class="sm" onclick="toggleProv(' +
      p.id +
      "," +
      (p.is_active ? "false" : "true") +
      ')">' +
      (p.is_active ? "Faol" : "O‘ch") +
      "</button></td>" +
      '<td><button type="button" class="sm" onclick="delProvider(' +
      p.id +
      ')">O\'chirish</button></td></tr>';
  });
  document.getElementById("ptbody").innerHTML =
    html || '<tr><td colspan="8">Provayderlar yo\'q</td></tr>';
}

async function toggleProv(id, nextActive) {
  await api(API + "/admin/providers/" + id, {
    method: "PATCH",
    body: JSON.stringify({ is_active: nextActive === "true" }),
  });
  loadProviders();
}

async function delProvider(id) {
  if (!confirm("Provayderni o‘chirish?")) return;
  await api(API + "/admin/providers/" + id, { method: "DELETE" });
  loadProviders();
}

async function createProvider() {
  const category_id = parseInt(document.getElementById("pnew_cat").value, 10);
  if (!category_id) {
    alert("Kategoriya tanlang");
    return;
  }
  const name = document.getElementById("pnew_name").value.trim();
  const phone = document.getElementById("pnew_phone").value.trim();
  const address = document.getElementById("pnew_addr").value.trim();
  if (!name || !phone || !address) {
    alert("Nomi, telefon va manzil majburiy");
    return;
  }
  const lat = parseFloat(document.getElementById("pnew_lat").value) || 41.2995;
  const lng = parseFloat(document.getElementById("pnew_lng").value) || 69.2401;
  const cover = document.getElementById("pnew_cover").value.trim() || null;
  const body = { category_id, name, phone, address, lat, lng };
  if (cover) body.cover_image = cover;
  const r = await api(API + "/admin/providers", {
    method: "POST",
    body: JSON.stringify(body),
  });
  if (r.ok) {
    ["pnew_name", "pnew_phone", "pnew_addr", "pnew_cover"].forEach(
      (id) => (document.getElementById(id).value = "")
    );
    loadProviders();
  } else {
    const err = await r.json().catch(() => ({}));
    alert(err.detail || r.status + " xato");
  }
}

async function loadCategoriesTab() {
  const r = await api(API + "/categories");
  const cats = await r.json();
  let out = "";
  for (const c of cats) {
    const vr = await api(API + "/categories/" + c.id + "/variants");
    const vars = await vr.json();
    let vrows =
      '<table style="margin:8px 0;font-size:12px;background:#fafafa"><thead><tr><th>Variant</th><th>Baza narx</th></tr></thead><tbody>';
    vars.forEach((v) => {
      vrows +=
        "<tr><td>" +
        esc(v.label_uz) +
        "</td><td>" +
        (v.base_price ?? 0) +
        "</td></tr>";
    });
    vrows += "</tbody></table>";
    out +=
      '<div style="border-bottom:1px solid var(--b);padding:12px 0"><strong>' +
      esc(c.title_uz) +
      '</strong> <span class="muted">(' +
      esc(c.key) +
      ")</span>" +
      '<div class="form-grid" style="margin-top:8px"><div><label>Variant nomi</label><input id="vl_' +
      c.id +
      '" placeholder="Standart"></div>' +
      '<div><label>Baza narx</label><input id="vp_' +
      c.id +
      '" type="number" step="0.01" value="0"></div>' +
      '<div><button type="button" class="btn primary" onclick="addVariant(' +
      c.id +
      ')">Variant qo\'shish</button></div></div>' +
      vrows +
      "</div>";
  }
  document.getElementById("catList").innerHTML =
    out || '<p class="muted">Kategoriyalar yo\'q</p>';
}

async function createCategory() {
  const key = document.getElementById("c_key").value.trim();
  const title_uz = document.getElementById("c_title").value.trim();
  if (!key || !title_uz) {
    alert("Kalit va sarlavha majburiy");
    return;
  }
  const icon = document.getElementById("c_icon").value.trim() || "category";
  const accent_color = document.getElementById("c_color").value;
  const subtitle_uz = document.getElementById("c_sub").value.trim() || null;
  const r = await api(API + "/admin/categories", {
    method: "POST",
    body: JSON.stringify({
      key,
      title_uz,
      subtitle_uz,
      icon,
      accent_color,
    }),
  });
  if (!r.ok) {
    alert((await r.json().catch(() => ({}))).detail || "Xato");
    return;
  }
  ["c_key", "c_title", "c_sub"].forEach(
    (id) => (document.getElementById(id).value = "")
  );
  loadCategoriesTab();
  loadCategoriesGlobal();
}

async function addVariant(cid) {
  const label_uz = document.getElementById("vl_" + cid).value.trim();
  if (!label_uz) {
    alert("Variant nomini kiriting");
    return;
  }
  const base_price = parseFloat(document.getElementById("vp_" + cid).value) || 0;
  const r = await api(API + "/admin/categories/" + cid + "/variants", {
    method: "POST",
    body: JSON.stringify({ label_uz, base_price }),
  });
  if (r.ok) {
    document.getElementById("vl_" + cid).value = "";
    loadCategoriesTab();
  } else {
    alert("Variant qo'shilmadi");
  }
}

(async () => {
  await loadCategoriesGlobal();
  loadStats();
})();
