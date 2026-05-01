"""
Bitta web-admin: `/admin` brauzer orqali, ma'lumotlar `/api/v1/admin/*` orqali.
Flutter ilovada alohida admin ekrani yo‘q — barcha boshqaruv shu yerda.
"""
from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter(prefix="/admin", tags=["admin panel"])

LOGIN_PAGE = """<!DOCTYPE html>
<html lang="uz">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>SuperApp Admin</title>
<style>
body{font-family:system-ui,-apple-system,sans-serif;display:flex;justify-content:center;align-items:center;min-height:100vh;margin:0;background:#f0f2f5}
form{background:#fff;padding:40px;border-radius:12px;box-shadow:0 2px 12px rgba(0,0,0,0.1);width:min(340px,92vw)}
input{display:block;width:100%;padding:10px;margin:8px 0 16px;border:1px solid #ddd;border-radius:6px;box-sizing:border-box}
button{width:100%;padding:10px;background:#4285F4;color:#fff;border:0;border-radius:6px;cursor:pointer;font-size:15px}
#error{color:#e74c3c;margin-top:8px;font-size:14px}
</style></head>
<body>
<form id="f"><h2 style="margin-top:0">Admin panel</h2>
<label>Telefon</label><input id="phone" placeholder="Telefon" value="admin" autocomplete="username">
<label>Parol</label><input id="pass" type="password" placeholder="Parol" value="admin123" autocomplete="current-password">
<button type="submit">Kirish</button><div id="error"></div></form>
<script>
f.onsubmit=async e=>{e.preventDefault();error.textContent='';
let r=await fetch('/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},
body:JSON.stringify({phone:phone.value,password:pass.value})});
if(r.ok){let d=await r.json();localStorage.setItem('at',d.access_token);location='/admin'}
else{error.textContent="Noto'g'ri telefon yoki parol"}}
</script></body></html>"""

DASHBOARD = """<!DOCTYPE html>
<html lang="uz"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>SuperApp Admin</title>
<style>:root{--p:#4285F4;--bg:#f5f6fa;--w:#fff;--t:#2d3436;--b:#dfe6e9}
*{box-sizing:border-box}body{font-family:system-ui,-apple-system,sans-serif;margin:0;background:var(--bg);color:var(--t);min-height:100vh}
nav{background:var(--w);padding:0 24px;height:56px;display:flex;align-items:center;justify-content:space-between;box-shadow:0 1px 4px rgba(0,0,0,.08);flex-wrap:wrap;gap:8px}
nav h1{font-size:18px;color:var(--p);margin:0}nav button{background:0;border:1px solid var(--b);padding:6px 14px;border-radius:6px;cursor:pointer;font-size:14px}
main{max-width:1200px;margin:24px auto;padding:0 16px}
.tabs{display:flex;gap:6px;margin-bottom:16px;flex-wrap:wrap}
.tabs button{padding:10px 16px;border:1px solid var(--b);background:var(--w);cursor:pointer;font-size:14px;border-radius:8px}
.tabs button.active{background:var(--p);color:#fff;border-color:var(--p)}
.grid-stats{display:grid;grid-template-columns:repeat(auto-fill,minmax(160px,1fr));gap:12px;margin-bottom:16px}
.stat{padding:14px;background:var(--w);border-radius:10px;box-shadow:0 1px 6px rgba(0,0,0,.06)}
.stat span{display:block;color:#636e72;font-size:12px}.stat strong{font-size:22px;color:var(--p)}
.row-status{display:flex;flex-wrap:wrap;gap:8px;margin-bottom:14px;font-size:13px}.row-status span{background:var(--w);padding:4px 10px;border-radius:20px;border:1px solid var(--b)}
.card{background:var(--w);border-radius:10px;box-shadow:0 1px 6px rgba(0,0,0,.06);overflow:hidden;margin-bottom:16px}
.card h3{margin:0 0 12px;font-size:16px;color:var(--p)}.pad{padding:14px}
table{width:100%;border-collapse:collapse}th,td{padding:10px 12px;text-align:left;border-bottom:1px solid var(--b);font-size:13px;vertical-align:top}
th{background:#f8f9fa;font-weight:600}.badge{padding:3px 8px;border-radius:12px;font-size:11px;white-space:nowrap}
.badge.pending{background:#ffeaa7;color:#b8860b}.badge.confirmed{background:#74b9ff;color:#fff}
.badge.in_progress{background:#a29bfe;color:#fff}.badge.completed{background:#55efc4;color:#006c4e}.badge.cancelled{background:#fab1a0;color:#d63031}
select,input{padding:8px 10px;border:1px solid var(--b);border-radius:6px;font-size:13px;background:var(--w);width:100%;max-width:100%}
textarea{min-height:56px;width:100%;max-width:100%;padding:8px;font-size:13px;border:1px solid var(--b);border-radius:6px;resize:vertical}
button.sm,.btn{padding:6px 12px;border:1px solid var(--b);border-radius:6px;background:var(--w);cursor:pointer;font-size:13px}
.btn.primary{background:var(--p);color:#fff;border-color:var(--p)}
.form-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(200px,1fr));gap:10px;margin-top:10px;align-items:end}
.form-grid label{font-size:12px;color:#636e72;display:block;margin-bottom:4px}
.pagination{display:flex;justify-content:center;gap:6px;padding:14px;flex-wrap:wrap}
.hidden{display:none!important}.muted{color:#888;font-size:13px}
</style></head>
<body>
<nav><h1>SuperApp Admin</h1><button type="button" onclick="logout()">Chiqish</button></nav>
<main>
<div class="tabs">
<button class="active" type="button" data-tab="dash">Ko'rsatkichlar</button>
<button type="button" data-tab="orders">Buyurtmalar</button>
<button type="button" data-tab="providers">Provayderlar</button>
<button type="button" data-tab="categories">Kategoriyalar</button>
</div>

<div id="tab-dash" class="tab">
<div class="grid-stats" id="statsGrid"><div class="muted pad">Yuklanmoqda…</div></div>
<div class="card pad"><h3>Buyurtmalar status bo'yicha</h3><div class="row-status" id="statusBreak"></div></div>
</div>

<div id="tab-orders" class="tab hidden">
<div class="card pad">
<div class="form-grid" style="align-items:end">
<div><label>Status</label><select id="ostatus"><option value="">Barcha status</option>
<option value="pending">Kutilmoqda</option><option value="confirmed">Tasdiqlangan</option>
<option value="in_progress">Jarayonda</option><option value="completed">Yakunlangan</option><option value="cancelled">Bekor</option></select></div>
<div><label>Kategoriya</label><select id="ocategory"><option value="">Barcha</option></select></div>
<div><button type="button" class="btn primary" onclick="loadOrders()">Filtrlash</button></div>
</div>
<table><thead><tr><th>ID</th><th>Xizmat</th><th>Narx</th><th>Status</th><th>Sana</th><th>Foydal.</th><th>Amal</th></tr></thead>
<tbody id="otbody"></tbody></table>
<div id="opages" class="pagination"></div>
</div></div>

<div id="tab-providers" class="tab hidden">
<div class="card pad">
<h3>Yangi provayder</h3>
<div class="form-grid">
<div><label>Kategoriya *</label><select id="pnew_cat"><option value="">—</option></select></div>
<div><label>Nomi *</label><input id="pnew_name" placeholder="Masalan Oq saroy"></div>
<div><label>Telefon *</label><input id="pnew_phone" placeholder="+998901234567"></div>
<div><label>Manzil *</label><input id="pnew_addr" placeholder="Toshkent, ..."></div>
<div><label>Kenglik (lat)</label><input id="pnew_lat" type="number" step="any" value="41.2995"></div>
<div><label>Uzunlik (lng)</label><input id="pnew_lng" type="number" step="any" value="69.2401"></div>
</div><p class="muted">Ixtiyoriy: <input id="pnew_cover" placeholder="Cover image URL (ixt.)" style="max-width:100%"></p>
<button type="button" class="btn primary" onclick="createProvider()" style="margin-top:12px">Qo'shish</button>
</div>
<div class="card pad"><h3>Royxat</h3>
<table><thead><tr><th>ID</th><th>Nomi</th><th>Kategoriya</th><th>Manzil</th><th>Tel.</th><th>Reyt.</th><th>Holat</th><th>Amal</th></tr></thead>
<tbody id="ptbody"></tbody></table>
</div></div>

<div id="tab-categories" class="tab hidden">
<div class="card pad">
<h3>Yangi kategoriya</h3>
<div class="form-grid">
<div><label>Kalit (key) *</label><input id="c_key" placeholder="football"></div>
<div><label>Sarlavha (uz) *</label><input id="c_title" placeholder="Futbol maydonlari"></div>
<div><label>Taglavha</label><input id="c_sub" placeholder="Yaqin maydonlarni toping"></div>
<div><label>Ikon (nom)</label><input id="c_icon" placeholder="sports_soccer"></div>
<div><label>Rang</label><input id="c_color" type="color" value="#4285F4" style="height:40px;padding:4px"></div>
</div>
<button type="button" class="btn primary" onclick="createCategory()" style="margin-top:12px">Yaratish</button>
</div>
<div class="card pad"><h3>Mavjud kategoriyalar va variantlar</h3><div id="catList" class="muted">Yuklanmoqda…</div></div>
</div>
</main>
<script>
const API='/api/v1';
let at=localStorage.getItem('at');
if(!at)location='/admin/login';
let h={Authorization:'Bearer '+at,'Content-Type':'application/json'};
let oPage=1,_catsById={};

async function api(url,opt={}){const r=await fetch(url,{headers:h,...opt});if(r.status===401){localStorage.removeItem('at');location='/admin/login'}return r}
function logout(){localStorage.removeItem('at');location='/admin/login'}

async function loadCategoriesGlobal(){
const r=await api(API+'/categories');if(!r.ok)return;
const cats=await r.json();_catsById={};
const opts='<option value="">Barcha</option>'+cats.map(c=>{ _catsById[c.id]=c;return '<option value="'+c.id+'">'+esc(c.title_uz)+'</option>'}).join('');
document.getElementById('ocategory').innerHTML=opts;
document.getElementById('pnew_cat').innerHTML='<option value="">—</option>'+cats.map(c=>'<option value="'+c.id+'">'+esc(c.title_uz)+'</option>').join('');
return cats;
}
function esc(s){if(s==null)return'';return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/"/g,'&quot;')}

function showTab(name){
document.querySelectorAll('.tabs button').forEach(x=>x.classList.toggle('active',x.dataset.tab===name));
document.querySelectorAll('.tab').forEach(t=>t.classList.add('hidden'));
document.getElementById('tab-'+name).classList.remove('hidden');
if(name==='dash')loadStats();
else if(name==='orders')loadOrders();
else if(name==='providers')loadProviders();
else if(name==='categories')loadCategoriesTab();
}
document.querySelectorAll('.tabs button').forEach(b=>{b.onclick=()=>showTab(b.dataset.tab)});

async function loadStats(){
const r=await api(API+'/admin/stats');if(!r.ok)return;
const s=await r.json();
document.getElementById('statsGrid').innerHTML=
'<div class="stat"><span>Buyurtmalar</span><strong>'+s.orders_total+'</strong></div>'+
'<div class="stat"><span>Provayderlar</span><strong>'+s.providers+'</strong></div>'+
'<div class="stat"><span>Foydalanuvchilar</span><strong>'+s.users+'</strong></div>'+
'<div class="stat"><span>Kategoriyalar</span><strong>'+s.categories+'</strong></div>';
const br=document.getElementById('statusBreak');br.innerHTML='';
for(const[k,v] of Object.entries(s.orders_by_status||{})){br.innerHTML+='<span><b>'+k+'</b>: '+v+'</span>';}
}

async function loadOrders(p=1){oPage=p;
await loadCategoriesGlobal();
const s=document.getElementById('ostatus').value;
const c=document.getElementById('ocategory').value;
let url=API+'/admin/orders?page='+p+'&per_page=15';if(s)url+='&status='+encodeURIComponent(s);if(c)url+='&category_id='+encodeURIComponent(c);
const r=await api(url);const d=await r.json();
let row='';(d.items||[]).forEach(o=>{row+='<tr><td>'+o.id+'</td><td>'+esc(o.service_name)+'</td><td>'+(o.price??'')+" so'm</td>"+
'<td><span class="badge '+o.status+'">'+(o.status||'')+'</span></td><td>'+esc(o.date||'')+'</td><td>'+(o.user_id??'')+'</td>'+
'<td><select onchange="changeStatus('+o.id+',this.value)"><option value="">Status</option>'+
'<option value="confirmed">Tasdiqlash</option><option value="in_progress">Jarayon</option>'+
'<option value="completed">Yakunlash</option><option value="cancelled">Bekor</option></select></td></tr>'});
document.getElementById('otbody').innerHTML=row||'<tr><td colspan="7">Buyurtmalar yo\'q</td></tr>';
let pg='';const pages=d.pages||1;for(let i=1;i<=pages;i++){pg+='<button type="button" class="sm'+(i===p?' btn primary':'')+'" onclick="loadOrders('+i+')">'+i+'</button>'}
document.getElementById('opages').innerHTML=pg;
}
async function changeStatus(id,st){if(!st)return;await api(API+'/admin/orders/'+id+'/status',{method:'PATCH',body:JSON.stringify({status:st})});loadOrders(oPage)}

async function loadProviders(){
await loadCategoriesGlobal();
const r=await api(API+'/providers?per_page=200');const d=await r.json();
let html='';(d.items||[]).forEach(p=>{
const cn=_catsById[p.category_id]?_catsById[p.category_id].title_uz:('#'+p.category_id);
html+='<tr><td>'+p.id+'</td><td>'+esc(p.name)+'</td><td>'+esc(cn)+'</td><td>'+esc(p.address)+'</td><td>'+esc(p.phone)+'</td><td>'+(p.rating??'')+'</td>'+
'<td><button type="button" class="sm" onclick="toggleProv('+p.id+','+(p.is_active?'false':'true')+')">'+(p.is_active?'Faol':'O‘ch')+'</button></td>'+
'<td><button type="button" class="sm" onclick="delProvider('+p.id+')">O‘chirish</button></td></tr>'});
document.getElementById('ptbody').innerHTML=html||'<tr><td colspan="8">Provayderlar yo\'q</td></tr>';
}
async function toggleProv(id,nextActive){await api(API+'/admin/providers/'+id,{method:'PATCH',body:JSON.stringify({is_active:nextActive==='true'})});loadProviders()}
async function delProvider(id){if(!confirm('Provayderni o‘chirish?'))return;await api(API+'/admin/providers/'+id,{method:'DELETE'});loadProviders()}
async function createProvider(){
const category_id=parseInt(document.getElementById('pnew_cat').value,10);if(!category_id){alert('Kategoriya tanlang');return}
const name=document.getElementById('pnew_name').value.trim();const phone=document.getElementById('pnew_phone').value.trim();const address=document.getElementById('pnew_addr').value.trim();
if(!name||!phone||!address){alert('Nomi, telefon va manzil majburiy');return}
const lat=parseFloat(document.getElementById('pnew_lat').value)||41.2995;const lng=parseFloat(document.getElementById('pnew_lng').value)||69.2401;
const cover=document.getElementById('pnew_cover').value.trim()||null;
const body={category_id,name,phone,address,lat,lng};if(cover)body.cover_image=cover;
const r=await api(API+'/admin/providers',{method:'POST',body:JSON.stringify(body)});
if(r.ok){['pnew_name','pnew_phone','pnew_addr','pnew_cover'].forEach(id=>document.getElementById(id).value='');loadProviders()}
else{const err=await r.json().catch(()=>({}));alert(err.detail||(r.status+' xato'));}}

async function loadCategoriesTab(){
const r=await api(API+'/categories');const cats=await r.json();
let out='';for(const c of cats){
const vr=await api(API+'/categories/'+c.id+'/variants');const vars=await vr.json();
let vrows='<table style="margin:8px 0;font-size:12px;background:#fafafa"><thead><tr><th>Variant</th><th>Baza narx</th></tr></thead><tbody>';
vars.forEach(v=>{vrows+='<tr><td>'+esc(v.label_uz)+'</td><td>'+(v.base_price??0)+"</td></tr>"});
vrows+='</tbody></table>';
out+='<div style="border-bottom:1px solid var(--b);padding:12px 0"><strong>'+esc(c.title_uz)+'</strong> <span class="muted">('+esc(c.key)+')</span>'+
'<div class="form-grid" style="margin-top:8px"><div><label>Variant nomi</label><input id="vl_'+c.id+'" placeholder="Standart"></div>'+
'<div><label>Baza narx</label><input id="vp_'+c.id+'" type="number" step="0.01" value="0"></div>'+
'<div><button type="button" class="btn primary" onclick="addVariant('+c.id+')">Variant qo\'shish</button></div></div>'+vrows+'</div>';
}
document.getElementById('catList').innerHTML=out||'<p class="muted">Kategoriyalar yo\'q</p>';
}
async function createCategory(){
const key=document.getElementById('c_key').value.trim();const title_uz=document.getElementById('c_title').value.trim();
if(!key||!title_uz){alert('Kalit va sarlavha majburiy');return}
const icon=document.getElementById('c_icon').value.trim()||'category';const accent_color=document.getElementById('c_color').value;
const subtitle_uz=document.getElementById('c_sub').value.trim()||null;
const r=await api(API+'/admin/categories',{method:'POST',body:JSON.stringify({key,title_uz,subtitle_uz,icon,accent_color})});
if(!r.ok){alert((await r.json().catch(()=>({}))).detail||'Xato');return}
['c_key','c_title','c_sub'].forEach(id=>document.getElementById(id).value='');loadCategoriesTab();loadCategoriesGlobal();
}
async function addVariant(cid){
const label_uz=document.getElementById('vl_'+cid).value.trim();if(!label_uz){alert('Variant nomini kiriting');return}
const base_price=parseFloat(document.getElementById('vp_'+cid).value)||0;
const r=await api(API+'/admin/categories/'+cid+'/variants',{method:'POST',body:JSON.stringify({label_uz,base_price})});
if(r.ok){document.getElementById('vl_'+cid).value='';loadCategoriesTab()}
else alert('Variant qo‘shilmadi');
}

;(async ()=>{await loadCategoriesGlobal();loadStats();})();
</script></body></html>"""


@router.get("/login", response_class=HTMLResponse)
async def admin_login_page():
    return HTMLResponse(LOGIN_PAGE)


@router.get("", response_class=HTMLResponse)
async def admin_dashboard_page():
    return HTMLResponse(DASHBOARD)
