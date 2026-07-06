import { API_BASE, api } from '../api.js';
import { showToast } from '../ui.js';

async function renderPremium() {
    var cfg = { price: 0, duration_days: 30, features: [] };
    try { var r = await window.api(window.API_BASE + '/premium/config'); if (r && r.ok) cfg = await r.json(); } catch (e) {}
    var payments = [];
    try { var rp = await window.api(window.API_BASE + '/premium/payments'); if (rp && rp.ok) { var d = await rp.json(); payments = d.payments || []; } } catch (e) {}

    // Premium funksiyalar (belgilash)
    var featRows = (cfg.features || []).map(function (f) {
        var stId = 'prem_' + f.key + '_state';
        return '<div class="setting-row"><div class="setting-info"><div class="setting-label">' + (f.label || f.key) + '</div></div>' +
            '<div class="setting-control" style="display:flex;align-items:center;gap:10px;">' +
            '<span id="' + stId + '" style="font-size:13px;font-weight:700;color:' + (f.premium ? '#7c3aed' : '#94a3b8') + ';">' + (f.premium ? 'PREMIUM' : 'Bepul') + '</span>' +
            '<label class="toggle-switch"><input type="checkbox" id="prem_' + f.key + '" onchange="updPremState(this,\'' + stId + '\')"' + (f.premium ? ' checked' : '') + '><span class="toggle-slider"></span></label>' +
            '</div></div>';
    }).join('');

    // To'lovlar jadvali
    var payRows = payments.map(function (p) {
        var t = p.created_at ? new Date(p.created_at).toLocaleString() : '';
        var st = p.status === 'confirmed' ? '<span style="color:#16a34a;font-weight:700;">Tasdiqlangan</span>' :
                 p.status === 'rejected' ? '<span style="color:#dc2626;">Rad etilgan</span>' :
                 '<span style="color:#d97706;font-weight:700;">Kutilmoqda</span>';
        var actions = p.status === 'pending' ?
            '<button class="btn btn-sm btn-primary" onclick="confirmPayment(' + p.id + ')">✅ Tasdiqlash</button> ' +
            '<button class="btn btn-sm" onclick="rejectPayment(' + p.id + ')">❌</button>' : '';
        return '<tr><td>' + p.id + '</td><td>' + (p.user_name || '#' + p.user_id) + '<br><small>' + (p.user_phone || '') + '</small></td>' +
            '<td>' + (p.amount || 0).toLocaleString() + " so'm</td><td>" + p.duration_days + ' kun</td><td>' + p.method + '</td><td>' + st + '</td>' +
            '<td style="font-size:12px;">' + t + '</td><td>' + actions + '</td></tr>';
    }).join('');

    mainContent.innerHTML =
        '<div class="page-header"><h1 class="page-title">Premium obuna</h1>' +
        '<p class="page-subtitle">Narx, premium funksiyalar va to\'lovlarni boshqarish</p></div>' +

        '<div class="card"><div class="card-body">' +
        '<h3 class="settings-section-title">💎 Obuna sozlamalari</h3>' +
        '<div class="setting-row"><div class="setting-info"><div class="setting-label">Oylik narx (so\'m)</div>' +
        '<div class="setting-description">Foydalanuvchi premium uchun to\'laydigan summa</div></div>' +
        '<div class="setting-control"><input type="number" class="form-input" id="prem_price" value="' + (cfg.price || 0) + '" style="width:160px;"></div></div>' +
        '<div class="setting-row"><div class="setting-info"><div class="setting-label">Muddat (kun)</div></div>' +
        '<div class="setting-control"><input type="number" class="form-input" id="prem_days" value="' + (cfg.duration_days || 30) + '" style="width:120px;"></div></div>' +
        '<div style="padding-top:12px;"><button class="btn btn-primary" onclick="savePremiumConfig()">💾 Saqlash</button></div>' +
        '</div></div>' +

        '<div class="card"><div class="card-body">' +
        '<h3 class="settings-section-title">🔒 Premium funksiyalar</h3>' +
        '<p class="setting-description" style="margin-bottom:10px;">PREMIUM qilingan bo\'lim faqat obunachilar uchun ochiladi. Oddiy foydalanuvchi obuna taklifini ko\'radi.</p>' +
        featRows +
        '<div style="padding-top:12px;"><button class="btn btn-primary" onclick="savePremiumFeatures()">💾 Funksiyalarni saqlash</button></div>' +
        '</div></div>' +

        '<div class="card"><div class="card-body">' +
        '<h3 class="settings-section-title">💳 To\'lovlar (tasdiqlash)</h3>' +
        '<div style="max-height:420px;overflow-y:auto;"><table class="data-table"><thead><tr><th>ID</th><th>Foydalanuvchi</th><th>Summa</th><th>Muddat</th><th>Usul</th><th>Holat</th><th>Sana</th><th>Amal</th></tr></thead><tbody>' +
        (payRows || '<tr><td colspan="8">To\'lov yo\'q</td></tr>') + '</tbody></table></div>' +
        '</div></div>';
}

function updPremState(cb, spanId) {
    var s = document.getElementById(spanId);
    if (s) { s.textContent = cb.checked ? 'PREMIUM' : 'Bepul'; s.style.color = cb.checked ? '#7c3aed' : '#94a3b8'; }
}
function savePremiumConfig() {
    var body = JSON.stringify({
        price: parseFloat(document.getElementById('prem_price').value) || 0,
        duration_days: parseInt(document.getElementById('prem_days').value) || 30
    });
    window.api(window.API_BASE + '/premium/config', { method: 'PUT', body: body })
        .then(function (r) { window.showToast(r && r.ok ? 'Saqlandi ✅' : 'Xatolik', r && r.ok ? 'success' : 'error'); });
}
function savePremiumFeatures() {
    var keys = ['plans', 'finance', 'shopping', 'services', 'calorie', 'fitness', 'alarm', 'ai_chat'];
    var features = [];
    keys.forEach(function (k) {
        var el = document.getElementById('prem_' + k);
        if (el) features.push({ key: k, premium: el.checked });
    });
    window.api(window.API_BASE + '/premium/config', { method: 'PUT', body: JSON.stringify({ features: features }) })
        .then(function (r) { window.showToast(r && r.ok ? 'Funksiyalar saqlandi ✅' : 'Xatolik', r && r.ok ? 'success' : 'error'); });
}
function confirmPayment(id) {
    window.api(window.API_BASE + '/premium/payments/' + id + '/confirm', { method: 'POST' })
        .then(function (r) { window.showToast(r && r.ok ? 'Tasdiqlandi ✅ Premium ochildi' : 'Xatolik', r && r.ok ? 'success' : 'error'); renderPremium(); });
}
function rejectPayment(id) {
    if (!confirm('To\'lovni rad etasizmi?')) return;
    window.api(window.API_BASE + '/premium/payments/' + id + '/reject', { method: 'POST' })
        .then(function (r) { window.showToast(r && r.ok ? 'Rad etildi' : 'Xatolik', r && r.ok ? 'success' : 'error'); renderPremium(); });
}

export { renderPremium };
window.renderPremium = renderPremium;
window.updPremState = updPremState;
window.savePremiumConfig = savePremiumConfig;
window.savePremiumFeatures = savePremiumFeatures;
window.confirmPayment = confirmPayment;
window.rejectPayment = rejectPayment;
