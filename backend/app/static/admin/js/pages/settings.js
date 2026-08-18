import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// AI bo'limlari ta'riflari (kalit -> ko'rinadigan nom)
var AI_FEATURES = [
    { key: 'vision', label: 'Rasm tahlili (Vision)', hint: 'Kaloriya hisoblagich va budilnik rasm-vazifasi' },
    { key: 'chat', label: 'AI Yordamchi (Chat/Agent)', hint: 'Suhbat, budilnik va bron qilish' },
    { key: 'translate', label: 'Tarjima', hint: 'Fitnes mashqlari tarjimasi' }
];

// ===== PAGE: SETTINGS =====
async function renderSettings() {
    var f = { maintenance_mode: false, registration_open: true, default_lead_fee: 5000, support_phone: '+998 71 200 00 00', support_telegram: '@superapp_support' };
    var ai = null;
    var flags = [];
    var cats = [];
    try { const r = await window.api(window.API_BASE + '/settings'); if (r && r.ok) f = await r.json(); } catch(e) {}
    try { const r = await window.api(window.API_BASE + '/ai-config'); if (r && r.ok) ai = await r.json(); } catch(e) {}
    try { const r = await window.api(window.API_BASE + '/feature-flags'); if (r && r.ok) { const d = await r.json(); flags = d.flags || []; } } catch(e) {}
    // Saqlash funksiyasi alohida (global) bo'lgani uchun kalitlarni
    // shu yerda saqlab qo'yamiz — aks holda u ro'yxatni ko'rmaydi.
    window.__featureFlagKeys = flags.map(function(f) { return f.key; });
    try { const r = await window.api(window.API_BASE + '/category-flags'); if (r && r.ok) { const d = await r.json(); cats = d.categories || []; } } catch(e) {}
    window.__catKeys = cats.map(function(c){ return c.key; });
    // Savdo (marketplace) raqamli sozlamalari: muddat, e'lon soni,
    // rasm chegarasi, uzaytirish narxi. Yoqish/o'chirish esa yuqoridagi
    // "Ilova bo'limlari" ro'yxatida (marketplace kaliti).
    var market = [];
    try { const r = await window.api(window.API_BASE + '/marketplace-settings'); if (r && r.ok) { const d = await r.json(); market = d.settings || []; } } catch(e) {}
    window.__marketKeys = market.map(function(m){ return m.key; });

    // AI provayderlar holati: kalit bor-yo'qligi, zaxira tartibi.
    var aiProv = null;
    try { const r = await window.api(window.API_BASE + '/ai-providers'); if (r && r.ok) aiProv = await r.json(); } catch(e) {}

    var legal = [];
    try { const r = await window.api(window.API_BASE + '/legal'); if (r && r.ok) { const d = await r.json(); legal = d.docs || []; } } catch(e) {}

    // ── AI provayderlar (kalit + zaxira) ──
    var aiProvHtml = '';
    if (aiProv) {
        var labels = aiProv.labels || {};
        var visionOk = aiProv.vision_capable || [];
        // Kalitlar (provayder bo'yicha, funksiyadan mustaqil)
        var kalitlar = {};
        (aiProv.features || []).forEach(function(f) {
            (f.providers || []).forEach(function(p) { kalitlar[p.key] = p; });
        });
        var keyRows = '';
        Object.keys(kalitlar).forEach(function(k) {
            var p = kalitlar[k];
            var holat = p.has_key
                ? '<span style="color:#16a34a;font-weight:700;">✓ ' + window.escapeHtml(p.key_preview || '') + '</span>'
                : '<span style="color:#dc2626;font-weight:700;">kalit yo\'q</span>';
            keyRows +=
                '<div class="setting-row">' +
                    '<div class="setting-info">' +
                        '<div class="setting-label">' + window.escapeHtml(labels[k] || k) + '</div>' +
                        '<div class="setting-description">' + holat +
                            (visionOk.indexOf(k) >= 0 ? ' · rasmni ko\'radi 🖼' : ' · faqat matn') +
                        '</div>' +
                    '</div>' +
                    '<div class="setting-control" style="display:flex;gap:6px;">' +
                        '<input type="password" class="form-input" id="aikey_' + k + '" placeholder="yangi kalit" style="width:210px;">' +
                        '<button class="btn btn-primary" onclick="saveAiKey(\'' + k + '\')">💾</button>' +
                        '<button class="btn" onclick="testAiKey(\'' + k + '\')">🔍 Test</button>' +
                    '</div>' +
                '</div>' +
                '<div id="aitest_' + k + '" style="font-size:12px;padding:0 0 8px 4px;"></div>';
        });

        // Zaxira tartibi (funksiya bo'yicha)
        var orderRows = '';
        (aiProv.features || []).forEach(function(f) {
            var mavjud = (f.order || []).join(', ');
            orderRows +=
                '<div class="setting-row">' +
                    '<div class="setting-info">' +
                        '<div class="setting-label">' + f.feature + ' — urinish tartibi</div>' +
                        '<div class="setting-description">Birinchisi ishlamasa keyingisiga o\'tadi. Hozir: <b>' +
                            window.escapeHtml(mavjud || 'kalit yo\'q') + '</b></div>' +
                    '</div>' +
                    '<div class="setting-control" style="display:flex;gap:6px;">' +
                        '<input type="text" class="form-input" id="aiorder_' + f.feature + '" value="' + window.escapeHtml(mavjud) + '" placeholder="gemini, openai, groq" style="width:240px;">' +
                        '<button class="btn btn-primary" onclick="saveAiOrder(\'' + f.feature + '\')">💾</button>' +
                    '</div>' +
                '</div>';
        });

        aiProvHtml =
            '<div class="card">' +
                '<div class="card-body">' +
                    '<div class="settings-section">' +
                        '<h3 class="settings-section-title">🔑 AI kalitlari va zaxira provayderlar</h3>' +
                        '<p class="setting-description" style="margin-bottom:12px;">Kalit shu yerdan kiritiladi va <b>server qayta ishga tushirilmasdan</b> ~2 soniyada kuchga kiradi. Kiritilgan kalit <code>.env</code> dagisidan ustun turadi. Bo\'sh saqlansa yana <code>.env</code> ishlaydi.</p>' +
                        keyRows +
                        '<h3 class="settings-section-title" style="margin-top:18px;">🔁 Zaxira tartibi</h3>' +
                        '<p class="setting-description" style="margin-bottom:12px;">Provayder band bo\'lsa (masalan Gemini <code>503 high demand</code>) tizim avtomatik keyingisiga o\'tadi. Vergul bilan yozing. Rasm tahlilida faqat rasmni ko\'radigan provayderlar ishlatiladi.</p>' +
                        orderRows +
                    '</div>' +
                '</div>' +
            '</div>';
    }

    var marketRows = '';
    market.forEach(function(m) {
        marketRows +=
            '<div class="setting-row">' +
                '<div class="setting-info">' +
                    '<div class="setting-label">' + window.escapeHtml(m.label || m.key) + '</div>' +
                    '<div class="setting-description">Standart: ' + m.default + '</div>' +
                '</div>' +
                '<div class="setting-control">' +
                    '<input type="number" class="form-input" id="market_' + m.key + '" value="' + m.value + '" min="0" style="width:120px;">' +
                '</div>' +
            '</div>';
    });

    var providerOptions = (ai && ai.provider_options) ? ai.provider_options : ['openai', 'groq'];

    // AI sozlamalari bo'limi
    var aiRows = '';
    AI_FEATURES.forEach(function(feat) {
        var conf = (ai && ai[feat.key]) ? ai[feat.key] : { provider: 'openai', model: '' };
        var opts = providerOptions.map(function(p) {
            return '<option value="' + p + '"' + (conf.provider === p ? ' selected' : '') + '>' + window.escapeHtml(p) + '</option>';
        }).join('');
        aiRows +=
            '<div class="setting-row">' +
                '<div class="setting-info">' +
                    '<div class="setting-label">' + feat.label + '</div>' +
                    '<div class="setting-description">' + feat.hint + '</div>' +
                '</div>' +
                '<div class="setting-control" style="display:flex; gap:8px;">' +
                    '<select class="form-input" id="ai_' + feat.key + '_provider" style="width:110px;">' + opts + '</select>' +
                    '<input type="text" class="form-input" id="ai_' + feat.key + '_model" value="' + window.escapeHtml(conf.model || '') + '" placeholder="model nomi" style="width:230px;">' +
                '</div>' +
            '</div>';
    });

    // Xizmat kategoriyalari (26 ta) — qatorlar
    var catRows = '';
    cats.forEach(function(c) {
        var stId = 'cat_' + c.key + '_state';
        catRows +=
            '<div class="setting-row">' +
                '<div class="setting-info">' +
                    '<div class="setting-label">' + window.escapeHtml(c.title || c.key) + '</div>' +
                    '<input type="text" class="form-input" id="cat_' + c.key + '_msg" value="' + window.escapeHtml(c.enabled ? '' : (c.message || '')) + '" placeholder="Yopiq bo\'lganda chiqadigan xabar (ixtiyoriy)" style="width:320px; margin-top:6px; font-size:12px;">' +
                '</div>' +
                '<div class="setting-control" style="display:flex; align-items:center; gap:10px;">' +
                    '<span id="' + stId + '" style="font-size:13px; font-weight:700; color:' + (c.enabled ? '#16a34a' : '#dc2626') + ';">' + (c.enabled ? 'Ochiq' : 'Yopiq') + '</span>' +
                    '<label class="toggle-switch">' +
                        '<input type="checkbox" id="cat_' + c.key + '_enabled" onchange="updToggle(this, \'' + stId + '\')"' + (c.enabled ? ' checked' : '') + '>' +
                        '<span class="toggle-slider"></span>' +
                    '</label>' +
                '</div>' +
            '</div>';
    });

    // Ilova bo'limlari (feature flags)
    var flagRows = '';
    flags.forEach(function(fl) {
        var stId = 'flag_' + fl.key + '_state';
        flagRows +=
            '<div class="setting-row">' +
                '<div class="setting-info">' +
                    '<div class="setting-label">' + window.escapeHtml(fl.label || fl.key) + '</div>' +
                    '<input type="text" class="form-input" id="flag_' + fl.key + '_msg" value="' + window.escapeHtml(fl.enabled ? '' : (fl.message || '')) + '" placeholder="Yopiq bo\'lganda chiqadigan xabar (ixtiyoriy)" style="width:320px; margin-top:6px; font-size:12px;">' +
                '</div>' +
                '<div class="setting-control" style="display:flex; align-items:center; gap:10px;">' +
                    '<span id="' + stId + '" style="font-size:13px; font-weight:700; color:' + (fl.enabled ? '#16a34a' : '#dc2626') + ';">' + (fl.enabled ? 'Ochiq' : 'Yopiq') + '</span>' +
                    '<label class="toggle-switch">' +
                        '<input type="checkbox" id="flag_' + fl.key + '_enabled" onchange="updToggle(this, \'' + stId + '\')"' + (fl.enabled ? ' checked' : '') + '>' +
                        '<span class="toggle-slider"></span>' +
                    '</label>' +
                '</div>' +
            '</div>';
    });

    var legalRows = legal.map(function(d){
        var safe = (d.content || '').replace(/</g,'&lt;').replace(/>/g,'&gt;');
        return '<div style="margin-bottom:16px;">' +
            '<label style="display:block;font-weight:700;margin-bottom:6px;">' + window.escapeHtml(d.label) + '</label>' +
            '<textarea class="form-input" id="legal_' + d.key + '" rows="8" style="width:100%;font-size:13px;line-height:1.5;">' + safe + '</textarea>' +
        '</div>';
    }).join('');

    mainContent.innerHTML =
        '<div class="page-header">' +
            '<h1 class="page-title">Sozlamalar</h1>' +
            '<p class="page-subtitle">Platforma parametrlari, AI modellari va bo\'limlarni boshqarish</p>' +
        '</div>' +

        // ── AI Sozlamalari ──
        '<div class="card">' +
            '<div class="card-body">' +
                '<div class="settings-section">' +
                    '<h3 class="settings-section-title">🤖 AI provayder va modellar</h3>' +
                    '<p class="setting-description" style="margin-bottom:12px;">Har bir qism uchun provayder (OpenAI/Groq) va model tanlang. O\'zgarish darhol kuchga kiradi (kod o\'zgartirish shart emas).</p>' +
                    aiRows +
                    '<div style="padding-top:12px;">' +
                        '<button class="btn btn-primary" onclick="saveAiConfig()">💾 AI sozlamalarini saqlash</button>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>' +

        aiProvHtml +

        // ── Ilova bo'limlari (feature flags) ──
        '<div class="card">' +
            '<div class="card-body">' +
                '<div class="settings-section">' +
                    '<h3 class="settings-section-title">📱 Ilova bo\'limlari (yoqish/o\'chirish)</h3>' +
                    '<p class="setting-description" style="margin-bottom:12px;"><b>O\'ng tarafdagi tugmani</b> "Yopiq" qilsangiz — bo\'lim ilovaда "tez orada ishga tushadi" bilan ko\'rinadi. Xabar maydoni ixtiyoriy.</p>' +
                    flagRows +
                    '<div style="padding-top:12px;">' +
                        '<button class="btn btn-primary" onclick="saveFeatureFlags()">💾 Bo\'limlarni saqlash</button>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>' +

        // ── Xizmat kategoriyalari (26 ta) ──
        '<div class="card">' +
            '<div class="card-body">' +
                '<div class="settings-section">' +
                    '<h3 class="settings-section-title">🛠️ Xizmatlar (' + cats.length + ' ta) — yoqish/o\'chirish</h3>' +
                    '<p class="setting-description" style="margin-bottom:12px;"><b>O\'ng tarafdagi tugmani</b> "Yopiq" qilsangiz — xizmat ilovaда "tez orada" bilan ko\'rinadi. Xabar maydoni faqat yopiq holatда ishlatiladi (ixtiyoriy, yozilmasa standart matn chiqadi).</p>' +
                    '<div style="max-height:420px; overflow-y:auto;">' + catRows + '</div>' +
                    '<div style="padding-top:12px;">' +
                        '<button class="btn btn-primary" onclick="saveCategoryFlags()">💾 Xizmatlarni saqlash</button>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>' +

        // ── Savdo (marketplace) ──
        '<div class="card">' +
            '<div class="card-body">' +
                '<div class="settings-section">' +
                    '<h3 class="settings-section-title">🛒 Savdo (e\'lonlar) sozlamalari</h3>' +
                    '<p class="setting-description" style="margin-bottom:12px;">Bo\'limni butunlay yoqish/o\'chirish va premium talab qilish yuqoridagi <b>Ilova bo\'limlari</b> ro\'yxatida («Savdo (e\'lonlar)»). Bu yerda muddat, e\'lon soni, rasm chegarasi va uzaytirish narxi.</p>' +
                    marketRows +
                    '<div style="padding-top:12px;">' +
                        '<button class="btn btn-primary" onclick="saveMarketplaceSettings()">💾 Savdo sozlamalarini saqlash</button>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>' +

        // ── Huquqiy hujjatlar (CMS) ──
        '<div class="card">' +
            '<div class="card-body">' +
                '<div class="settings-section">' +
                    '<h3 class="settings-section-title">📄 Huquqiy hujjatlar</h3>' +
                    '<p class="setting-description" style="margin-bottom:12px;">Foydalanish shartlari, maxfiylik va FAQ matnlari. O\'zgarish darhol ilova (/terms) va veb-saytda ko\'rinadi.</p>' +
                    legalRows +
                    '<div style="padding-top:8px;">' +
                        '<button class="btn btn-primary" onclick="saveLegal()">💾 Hujjatlarni saqlash</button>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>' +

        // ── Tizim sozlamalari ──
        '<div class="card">' +
            '<div class="card-body">' +
                '<div class="settings-section">' +
                    '<h3 class="settings-section-title">Tizim</h3>' +
                    '<div class="setting-row">' +
                        '<div class="setting-info">' +
                            '<div class="setting-label">Maintenance rejimi</div>' +
                            '<div class="setting-description">Yoqilganda platforma vaqtinchalik to\'xtatiladi</div>' +
                        '</div>' +
                        '<div class="setting-control">' +
                            '<label class="toggle-switch"><input type="checkbox" id="settingMaintenance"' + (f.maintenance_mode ? ' checked' : '') + '><span class="toggle-slider"></span></label>' +
                        '</div>' +
                    '</div>' +
                    '<div class="setting-row">' +
                        '<div class="setting-info">' +
                            '<div class="setting-label">Registratsiya ochiq</div>' +
                            '<div class="setting-description">Yangi foydalanuvchilar ro\'yxatdan o\'tishi mumkin</div>' +
                        '</div>' +
                        '<div class="setting-control">' +
                            '<label class="toggle-switch"><input type="checkbox" id="settingRegistration"' + (f.registration_open !== false ? ' checked' : '') + '><span class="toggle-slider"></span></label>' +
                        '</div>' +
                    '</div>' +
                    '<div class="setting-row">' +
                        '<div class="setting-info">' +
                            '<div class="setting-label">Standart lead fee (so\'m)</div>' +
                            '<div class="setting-description">Mijoz topilganda provayder balansidan yechiladigan komissiya. Provayder/kategoriya alohida belgilamasa shu qo\'llanadi.</div>' +
                        '</div>' +
                        '<div class="setting-control"><input type="number" class="form-input" id="settingLeadFee" value="' + (f.default_lead_fee != null ? f.default_lead_fee : 5000) + '" min="0" step="500" style="width:120px;"></div>' +
                    '</div>' +
                    '<div class="setting-row">' +
                        '<div class="setting-info"><div class="setting-label">Support telefon</div></div>' +
                        '<div class="setting-control"><input type="text" class="form-input" id="settingSupportPhone" value="' + window.escapeHtml(f.support_phone || '') + '" style="width:200px;"></div>' +
                    '</div>' +
                    '<div class="setting-row">' +
                        '<div class="setting-info"><div class="setting-label">Support Telegram</div></div>' +
                        '<div class="setting-control"><input type="text" class="form-input" id="settingSupportTelegram" value="' + window.escapeHtml(f.support_telegram || '') + '" style="width:200px;"></div>' +
                    '</div>' +
                    '<div style="padding-top:16px;">' +
                        '<button class="btn btn-primary" onclick="saveSettings()">💾 Saqlash</button>' +
                    '</div>' +
                '</div>' +
            '</div>' +
        '</div>';
}

// Toggle bosilganда "Ochiq/Yopiq" yozuvini yangilaydi
function updToggle(cb, spanId) {
    var s = document.getElementById(spanId);
    if (s) {
        s.textContent = cb.checked ? 'Ochiq' : 'Yopiq';
        s.style.color = cb.checked ? '#16a34a' : '#dc2626';
    }
}

function saveAiConfig() {
    var payload = {};
    AI_FEATURES.forEach(function(feat) {
        payload[feat.key] = {
            provider: document.getElementById('ai_' + feat.key + '_provider').value,
            model: document.getElementById('ai_' + feat.key + '_model').value
        };
    });
    window.api(window.API_BASE + '/ai-config', { method: 'PUT', body: JSON.stringify(payload) })
        .then(function(r) {
            window.showToast(r && r.ok ? 'AI sozlamalari saqlandi ✅' : 'Saqlab bo\'lmadi', r && r.ok ? 'success' : 'error');
        });
}

function saveFeatureFlags() {
    var flagsList = [];
    // DIQQAT: ro'yxat backenddan kelgan flags'дан olinadi. Ilgari
    // qo'lda yozilgan edi va yangi bo'lim qo'shilganda (masalan
    // "jobs") u SAQLANMAY qolardi — admin tugmani bosardi, lekin
    // hech narsa o'zgarmasdi.
    (window.__featureFlagKeys || []).forEach(function(key) {
        var cb = document.getElementById('flag_' + key + '_enabled');
        var msgEl = document.getElementById('flag_' + key + '_msg');
        var premEl = document.getElementById('flag_' + key + '_premium');
        if (cb) {
            flagsList.push({
                key: key,
                enabled: cb.checked,
                message: msgEl ? msgEl.value : '',
                premium: premEl ? premEl.checked : false
            });
        }
    });
    window.api(window.API_BASE + '/feature-flags', { method: 'PUT', body: JSON.stringify({ flags: flagsList }) })
        .then(function(r) {
            window.showToast(r && r.ok ? 'Bo\'limlar saqlandi ✅' : 'Saqlab bo\'lmadi', r && r.ok ? 'success' : 'error');
        });
}

function saveAiKey(provider) {
    var el = document.getElementById('aikey_' + provider);
    if (!el) return;
    window.api(window.API_BASE + '/ai-key', {
        method: 'PUT',
        body: JSON.stringify({ provider: provider, api_key: el.value })
    }).then(function(r) {
        window.showToast(r && r.ok ? 'Kalit saqlandi ✅' : 'Saqlab bo\'lmadi',
                         r && r.ok ? 'success' : 'error');
        if (r && r.ok) { el.value = ''; window.renderSettings(); }
    });
}

function testAiKey(provider) {
    var el = document.getElementById('aikey_' + provider);
    var out = document.getElementById('aitest_' + provider);
    if (out) out.innerHTML = '<span style="color:#64748b;">Tekshirilmoqda…</span>';
    window.api(window.API_BASE + '/ai-test', {
        method: 'POST',
        body: JSON.stringify({ provider: provider, api_key: el ? el.value : '' })
    }).then(function(r) { return r.json(); }).then(function(d) {
        if (!out) return;
        out.innerHTML = '<span style="color:' + (d.ok ? '#16a34a' : '#dc2626') + ';">' +
                        window.escapeHtml(d.message || '') + '</span>';
    }).catch(function() {
        if (out) out.innerHTML = '<span style="color:#dc2626;">Tekshirib bo\'lmadi</span>';
    });
}

function saveAiOrder(feature) {
    var el = document.getElementById('aiorder_' + feature);
    if (!el) return;
    var order = el.value.split(',').map(function(x) { return x.trim(); })
                        .filter(function(x) { return x; });
    window.api(window.API_BASE + '/ai-providers', {
        method: 'PUT',
        body: JSON.stringify({ feature: feature, order: order })
    }).then(function(r) {
        window.showToast(r && r.ok ? 'Tartib saqlandi ✅' : 'Saqlab bo\'lmadi',
                         r && r.ok ? 'success' : 'error');
    });
}

function saveMarketplaceSettings() {
    var values = {};
    (window.__marketKeys || []).forEach(function(key) {
        var el = document.getElementById('market_' + key);
        if (!el) return;
        var n = parseInt(el.value, 10);
        // Bo'sh yoki noto'g'ri qiymat YUBORILMAYDI: backend standartни
        // ishlatadi va savdo to'xtab qolmaydi.
        if (!isNaN(n) && n >= 0) values[key] = n;
    });
    window.api(window.API_BASE + '/marketplace-settings', { method: 'PUT', body: JSON.stringify({ values: values }) })
        .then(function(r) {
            window.showToast(r && r.ok ? 'Savdo sozlamalari saqlandi ✅' : 'Saqlab bo\'lmadi', r && r.ok ? 'success' : 'error');
        });
}

function saveLegal() {
    var payload = {};
    ['terms', 'privacy', 'faq'].forEach(function(k) {
        var el = document.getElementById('legal_' + k);
        if (el) payload[k] = el.value;
    });
    window.api(window.API_BASE + '/legal', { method: 'PUT', body: JSON.stringify(payload) })
        .then(function(r) {
            window.showToast(r && r.ok ? 'Hujjatlar saqlandi ✅' : 'Saqlab bo\'lmadi', r && r.ok ? 'success' : 'error');
        });
}

function saveCategoryFlags() {
    var keys = window.__catKeys || [];
    var flagsList = [];
    keys.forEach(function(key) {
        var cb = document.getElementById('cat_' + key + '_enabled');
        var msgEl = document.getElementById('cat_' + key + '_msg');
        if (cb) {
            flagsList.push({ key: key, enabled: cb.checked, message: msgEl ? msgEl.value : '' });
        }
    });
    window.api(window.API_BASE + '/category-flags', { method: 'PUT', body: JSON.stringify({ flags: flagsList }) })
        .then(function(r) {
            window.showToast(r && r.ok ? 'Xizmatlar saqlandi ✅' : 'Saqlab bo\'lmadi', r && r.ok ? 'success' : 'error');
        });
}

function saveSettings() {
    var payload = {
        maintenance_mode: document.getElementById('settingMaintenance').checked,
        registration_open: document.getElementById('settingRegistration').checked,
        support_phone: document.getElementById('settingSupportPhone').value,
        support_telegram: document.getElementById('settingSupportTelegram').value
    };
    var leadFeeEl = document.getElementById('settingLeadFee');
    if (leadFeeEl) {
        var lf = parseFloat(leadFeeEl.value);
        if (!isNaN(lf) && lf >= 0) payload.default_lead_fee = lf;
    }
    window.api(window.API_BASE + '/settings', { method: 'PATCH', body: JSON.stringify(payload) })
        .then(function(r) {
            window.showToast(r && r.ok ? 'Sozlamalar muvaffaqiyatli saqlandi' : 'Saqlab bo\'lmadi', r && r.ok ? 'success' : 'error');
        });
}

// Exports for ES6 modules
export { saveSettings, saveAiConfig, saveFeatureFlags, saveCategoryFlags, saveMarketplaceSettings, saveAiKey, testAiKey, saveAiOrder, saveLegal, updToggle, renderSettings };
// Expose to window for inline onclick handlers
window.saveSettings = saveSettings;
window.saveAiConfig = saveAiConfig;
window.saveFeatureFlags = saveFeatureFlags;
window.saveCategoryFlags = saveCategoryFlags;
window.saveMarketplaceSettings = saveMarketplaceSettings;
window.saveAiKey = saveAiKey;
window.testAiKey = testAiKey;
window.saveAiOrder = saveAiOrder;
window.saveLegal = saveLegal;
window.updToggle = updToggle;
window.renderSettings = renderSettings;
