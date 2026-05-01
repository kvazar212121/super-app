from fastapi import APIRouter
from fastapi.responses import HTMLResponse

router = APIRouter(prefix="/admin", tags=["admin panel"])

LOGIN_PAGE = """<!DOCTYPE html>
<html lang="uz">
<head><meta charset="UTF-8"><title>SuperApp Admin</title>
<style>body{font-family:system-ui;display:flex;justify-content:center;align-items:center;height:100vh;background:#f0f2f5}
form{background:#fff;padding:40px;border-radius:12px;box-shadow:0 2px 12px rgba(0,0,0,0.1)}
input{display:block;width:280px;padding:10px;margin:8px 0 16px;border:1px solid #ddd;border-radius:6px}
button{width:100%;padding:10px;background:#4285F4;color:#fff;border:0;border-radius:6px;cursor:pointer}
#error{color:#e74c3c;margin-top:8px}</style></head>
<body>
<form id="f"><h2>Admin panel</h2>
<input id="phone" placeholder="Telefon" value="admin">
<input id="pass" type="password" placeholder="Parol" value="admin123">
<button type="submit">Kirish</button><div id="error"></div></form>
<script>
f.onsubmit=async e=>{e.preventDefault()
let r=await fetch('/api/v1/auth/login',{method:'POST',headers:{'Content-Type':'application/json'},
body:JSON.stringify({phone:phone.value,password:pass.value})})
if(r.ok){let d=await r.json();localStorage.setItem('at',d.access_token);location='/admin'}
else{error.textContent='Noto‘g‘ri telefon yoki parol'}}
</script></body></html>"""

DASHBOARD = """<!DOCTYPE html>
<html lang="uz"><head><meta charset="UTF-8"><title>SuperApp Admin</title>
<style>:root{--p:#4285F4;--bg:#f5f6fa;--w:#fff;--t:#2d3436;--b:#dfe6e9}
*{box-sizing:border-box}body{font-family:system-ui;margin:0;background:var(--bg);color:var(--t)}
nav{background:var(--w);padding:0 24px;height:56px;display:flex;align-items:center;justify-content:space-between;box-shadow:0 1px 4px rgba(0,0,0,0.08)}
nav h1{font-size:18px;color:var(--p)}nav button{background:0;border:1px solid var(--b);padding:6px 14px;border-radius:6px;cursor:pointer}
main{max-width:1100px;margin:24px auto;padding:0 16px}
.tabs{display:flex;gap:0;margin-bottom:20px}.tabs button{padding:10px 22px;border:1px solid var(--b);background:var(--w);cursor:pointer;font-size:14px}
.tabs button.active{background:var(--p);color:#fff;border-color:var(--p)}
.card{background:var(--w);border-radius:10px;box-shadow:0 1px 6px rgba(0,0,0,0.06);overflow:hidden}
table{width:100%;border-collapse:collapse}th,td{padding:10px 14px;text-align:left;border-bottom:1px solid var(--b);font-size:13px}
th{background:#f8f9fa;font-weight:600}.badge{padding:3px 8px;border-radius:12px;font-size:11px}
.badge.pending{background:#ffeaa7;color:#d68910}.badge.confirmed{background:#74b9ff;color:#fff}
.badge.in_progress{background:#a29bfe;color:#fff}.badge.completed{background:#55efc4;color:#006c4e}.badge.cancelled{background:#fab1a0;color:#d63031}
select,button.sm{padding:4px 8px;border:1px solid var(--b);border-radius:4px;font-size:12px;cursor:pointer;background:var(--w)}
.pagination{display:flex;justify-content:center;gap:6px;padding:16px}.pagination button{padding:6px 12px;border:1px solid var(--b);border-radius:4px;background:var(--w);cursor:pointer}
.loading{text-align:center;padding:40px;color:#888}</style></head>
<body>
<nav><h1>SuperApp Admin</h1><button onclick="logout()">Chiqish</button></nav>
<main>
<div class="tabs">
<button class="active" data-tab="orders">Buyurtmalar</button>
<button data-tab="providers">Provayderlar</button>
</div>
<div id="tab-orders" class="tab"><div class="card">
<div style="padding:12px 14px;display:flex;gap:10px;flex-wrap:wrap">
<select id="ostatus"><option value="">Barcha status</option>
<option value="pending">Kutilmoqda</option><option value="confirmed">Tasdiqlangan</option>
<option value="in_progress">Jarayonda</option><option value="completed">Yakunlangan</option><option value="cancelled">Bekor qilingan</option></select>
<button class="sm" onclick="loadOrders()">Filtrlash</button>
</div>
<table><thead><tr><th>ID</th><th>Xizmat</th><th>Narx</th><th>Status</th><th>Sana</th><th>Amal</th></tr></thead>
<tbody id="otbody"></tbody></table>
<div id="opages" class="pagination"></div></div></div>
<div id="tab-providers" class="tab" style="display:none"><div class="card">
<table><thead><tr><th>ID</th><th>Nomi</th><th>Kategoriya</th><th>Manzil</th><th>Reyting</th><th>Faol</th><th>Amal</th></tr></thead>
<tbody id="ptbody"></tbody></table>
</div></div></main>
<script>
const API='/api/v1';
let at=localStorage.getItem('at');
if(!at)location='/admin/login';
let h={Authorization:'Bearer '+at,'Content-Type':'application/json'};
let oPage=1,pPage=1;

async function api(url,opt={}){let r=await fetch(url,{headers:h,...opt});if(r.status===401){localStorage.clear();location='/admin/login'}return r}

function logout(){localStorage.clear();location='/admin/login'}

// tabs
document.querySelectorAll('.tabs button').forEach(b=>b.onclick=()=>{
document.querySelectorAll('.tabs button').forEach(x=>x.classList.remove('active'));
b.classList.add('active');
document.querySelectorAll('.tab').forEach(t=>t.style.display='none');
document.getElementById('tab-'+b.dataset.tab).style.display='';if(b.dataset.tab==='orders')loadOrders();else loadProviders()});

// orders
async function loadOrders(p=1){oPage=p;
let s=document.getElementById('ostatus').value;
let url=API+'/admin/orders?page='+p+'&per_page=15';
if(s)url+='&status='+s;
let r=await api(url);let d=await r.json();
let h='';d.items.forEach(o=>{h+=`<tr><td>${o.id}</td><td>${o.service_name}</td><td>${o.price} so'm</td>
<td><span class="badge ${o.status}">${o.status}</span></td><td>${o.date||''}</td>
<td><select onchange="changeStatus(${o.id},this.value)"><option value="">O'zgartirish</option>
<option value="confirmed">Tasdiqlash</option><option value="in_progress">Jarayonga</option>
<option value="completed">Yakunlash</option><option value="cancelled">Bekor qilish</option></select></td></tr>`});
otbody.innerHTML=h||'<tr><td colspan=6>Buyurtmalar topilmadi</td></tr>';
let pg='';for(let i=1;i<=d.pages;i++)pg+=`<button onclick="loadOrders(${i})" style="${i===p?'background:var(--p);color:#fff':''}">${i}</button>`;
opages.innerHTML=pg}

async function changeStatus(id,s){if(!s)return;
await api(API+'/admin/orders/'+id+'/status',{method:'PATCH',body:JSON.stringify({status:s})});loadOrders(oPage)}

// providers
async function loadProviders(){
let r=await api(API+'/providers?per_page=100');let d=await r.json();
let h='';d.items.forEach(p=>{h+=`<tr><td>${p.id}</td><td>${p.name}</td><td>${p.category_id}</td><td>${p.address}</td><td>${p.rating}</td><td>${p.is_active?'✅':'❌'}</td>
<td><button class="sm" onclick="delProvider(${p.id})">O'chirish</button></td></tr>`});
ptbody.innerHTML=h||'<tr><td colspan=7>Provayderlar topilmadi</td></tr>'}

async function delProvider(id){if(!confirm('Provayderni o‘chirishni xohlaysizmi?'))return;
await api(API+'/admin/providers/'+id,{method:'DELETE'});loadProviders()}

loadOrders();
</script></body></html>"""


@router.get("/login", response_class=HTMLResponse)
async def admin_login():
    return HTMLResponse(LOGIN_PAGE)


@router.get("", response_class=HTMLResponse)
async def admin_dashboard():
    return HTMLResponse(DASHBOARD)