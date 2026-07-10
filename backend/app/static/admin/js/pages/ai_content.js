import { showToast } from '../ui.js';

var _aiDefaultPrompt = '';
var _notifTpls = [];

async function renderAiContent() {
    // AI prompt
    var promptData = { prompt: '', is_custom: false, default: '' };
    try {
        var r = await window.api(window.API_BASE + '/ai-prompt');
        if (r && r.ok) promptData = await r.json();
    } catch (e) {}
    _aiDefaultPrompt = promptData.default || '';

    // Bildirishnoma shablonlari
    try {
        var rt = await window.api(window.API_BASE + '/notif-templates');
        if (rt && rt.ok) { var d = await rt.json(); _notifTpls = d.templates || []; }
    } catch (e) {}

    mainContent.innerHTML =
        '<div class="page-header"><h1 class="page-title">AI va Bildirishnomalar</h1>' +
        '<p class="page-subtitle">AI yordamchi qanday javob berishini va bildirishnoma shablonlarini boshqaring</p></div>' +

        // ── AI prompt ──
        '<div class="card"><div class="card-body">' +
        '<h3 class="settings-section-title">🤖 AI yordamchi prompti</h3>' +
        '<p class="setting-description" style="margin-bottom:10px;">Bu matn AI ga "qanday javob berish" ni o\'rgatadi. ' +
        '<code>{current_time}</code> — hozirgi vaqt bilan almashtiriladi. Bo\'sh qoldirilsa standart prompt ishlaydi.' +
        (promptData.is_custom ? ' <b style="color:#7c3aed;">(hozir maxsus prompt yoqilgan)</b>' : ' <b style="color:#16a34a;">(hozir standart prompt)</b>') +
        '</p>' +
        '<textarea class="form-input" id="aiPrompt" rows="14" style="font-family:monospace;font-size:13px;line-height:1.5;">' +
        window.escapeHtml(promptData.prompt || '') + '</textarea>' +
        '<div style="display:flex;gap:10px;padding-top:12px;">' +
        '<button class="btn btn-primary" onclick="saveAiPrompt()">💾 Promptni saqlash</button>' +
        '<button class="btn" onclick="resetAiPrompt()">↺ Standartga qaytarish</button>' +
        '</div></div></div>' +

        // ── Bildirishnoma shablonlari ──
        '<div class="card"><div class="card-body">' +
        '<h3 class="settings-section-title">📢 Bildirishnoma shablonlari</h3>' +
        '<p class="setting-description" style="margin-bottom:10px;">Tez-tez yuboriladigan bildirishnomalarni shablon sifatida saqlang. ' +
        'Keyin "Bildirishnomalar" bo\'limida tanlab, bir zumda to\'ldirasiz.</p>' +
        '<div id="tplList"></div>' +
        '<div style="display:flex;gap:10px;padding-top:12px;">' +
        '<button class="btn" onclick="addNotifTpl()">➕ Shablon qo\'shish</button>' +
        '<button class="btn btn-primary" onclick="saveNotifTpls()">💾 Shablonlarni saqlash</button>' +
        '</div></div></div>';

    renderTplList();
}

function renderTplList() {
    var el = document.getElementById('tplList');
    if (!el) return;
    if (!_notifTpls.length) {
        el.innerHTML = '<div style="color:#94a3b8;padding:10px 0;">Shablon yo\'q. "Shablon qo\'shish" tugmasini bosing.</div>';
        return;
    }
    el.innerHTML = _notifTpls.map(function (t, i) {
        return '<div style="border:1px solid var(--border,#e2e8f0);border-radius:12px;padding:14px;margin-bottom:12px;">' +
            '<div style="display:flex;justify-content:space-between;align-items:center;margin-bottom:8px;">' +
            '<strong style="font-size:13px;color:#64748b;">Shablon #' + (i + 1) + '</strong>' +
            '<button class="btn btn-sm" onclick="removeNotifTpl(' + i + ')" style="color:#dc2626;">🗑 O\'chirish</button></div>' +
            '<input type="text" class="form-input" id="tplTitle' + i + '" placeholder="Sarlavha" value="' +
            window.escapeHtml(t.title || '') + '" style="margin-bottom:8px;">' +
            '<textarea class="form-input" id="tplMsg' + i + '" placeholder="Xabar matni..." rows="2">' +
            window.escapeHtml(t.message || '') + '</textarea>' +
            '</div>';
    }).join('');
}

// _notifTpls ni DOM'dagi qiymatlar bilan sinxronlaymiz (renderdan oldin)
function _syncTplsFromDom() {
    _notifTpls = _notifTpls.map(function (t, i) {
        var ti = document.getElementById('tplTitle' + i);
        var mi = document.getElementById('tplMsg' + i);
        return {
            id: t.id,
            title: ti ? ti.value : (t.title || ''),
            message: mi ? mi.value : (t.message || ''),
        };
    });
}

function addNotifTpl() {
    _syncTplsFromDom();
    _notifTpls.push({ id: null, title: '', message: '' });
    renderTplList();
}

function removeNotifTpl(i) {
    _syncTplsFromDom();
    _notifTpls.splice(i, 1);
    renderTplList();
}

function saveNotifTpls() {
    _syncTplsFromDom();
    var payload = _notifTpls.filter(function (t) { return (t.title || '').trim() || (t.message || '').trim(); });
    window.api(window.API_BASE + '/notif-templates', {
        method: 'PUT', body: JSON.stringify({ templates: payload }),
    }).then(function (r) {
        if (r && r.ok) { r.json().then(function (d) { _notifTpls = d.templates || []; renderTplList(); }); window.showToast('Shablonlar saqlandi ✅', 'success'); }
        else window.showToast('Xatolik', 'error');
    });
}

function saveAiPrompt() {
    var ta = document.getElementById('aiPrompt');
    var prompt = ta ? ta.value : '';
    window.api(window.API_BASE + '/ai-prompt', {
        method: 'PUT', body: JSON.stringify({ prompt: prompt }),
    }).then(function (r) {
        window.showToast(r && r.ok ? 'Prompt saqlandi ✅' : 'Xatolik', r && r.ok ? 'success' : 'error');
        if (r && r.ok) renderAiContent();
    });
}

function resetAiPrompt() {
    if (!confirm('Promptni standart holatga qaytarasizmi?')) return;
    window.api(window.API_BASE + '/ai-prompt', {
        method: 'PUT', body: JSON.stringify({ prompt: '' }),
    }).then(function (r) {
        window.showToast(r && r.ok ? 'Standart promptga qaytarildi' : 'Xatolik', r && r.ok ? 'success' : 'error');
        if (r && r.ok) renderAiContent();
    });
}

export { renderAiContent };
window.renderAiContent = renderAiContent;
window.saveAiPrompt = saveAiPrompt;
window.resetAiPrompt = resetAiPrompt;
window.addNotifTpl = addNotifTpl;
window.removeNotifTpl = removeNotifTpl;
window.saveNotifTpls = saveNotifTpls;
