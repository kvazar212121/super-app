import { API_BASE, apiError, api, getAuthHeaders } from '../api.js';
import { showToast } from '../ui.js';

// ===== PAGE: SOVRINLI SEZONLI REYTING (AKSIYA) =====
//
// "Aksiyalar" (promos.js) dan FARQI: u chegirma bannerlari, bu esa
// vaqt bilan chegaralangan OVOZ BERISH musobaqasi. Yulduz soni
// ahamiyatsiz — har bir foydalanuvchi 1 ta ovoz beradi va faqat
// BITTA provayderni tanlaydi. Eng ko'p ovoz olgani sovrin oladi.

var CAMPAIGN_STATUS = {
    running:  ['Ketmoqda', 'active'],
    upcoming: ['Kutilmoqda', 'pending'],
    finished: ['Yakunlangan', 'completed'],
    disabled: ["To'xtatilgan", 'cancelled']
};

function campaignBadge(st) {
    var pair = CAMPAIGN_STATUS[st] || [st, 'pending'];
    return '<span class="badge-status ' + pair[1] + '">' + window.escapeHtml(pair[0]) + '</span>';
}

function campaignDate(iso) {
    if (!iso) return '—';
    var d = new Date(iso);
    return d.toLocaleDateString('uz-UZ') + ' ' + d.toTimeString().slice(0, 5);
}

async function renderCampaigns() {
    var campaigns = [];
    var categories = [];
    try {
        const r = await window.api(window.API_BASE + '/admin/campaigns');
        if (r && r.ok) campaigns = await r.json();
    } catch (e) { apiError('Aksiyalarni yuklab bo\'lmadi'); }
    try {
        const rc = await window.api(window.API_BASE + '/categories');
        if (rc && rc.ok) categories = await rc.json();
    } catch (e) { /* kategoriyasiz ham ishlaydi */ }

    var catOptions = '<option value="">Barcha kategoriyalar</option>' +
        categories.map(function (c) {
            return '<option value="' + c.id + '">' + window.escapeHtml(c.title_uz || c.key) + '</option>';
        }).join('');

    var catById = {};
    categories.forEach(function (c) { catById[c.id] = c; });

    mainContent.innerHTML =
        '<div class="page-header">' +
            '<h1 class="page-title">Sovrinli reyting</h1>' +
            '<p class="page-subtitle">Sezonli musobaqa: foydalanuvchilar ovoz beradi, ' +
            'eng ko\'p ovoz olgan provayder sovrin oladi. Har bir foydalanuvchi ' +
            'butun aksiya davomida faqat BITTA ovoz bera oladi.</p>' +
        '</div>' +
        '<div style="display:grid; grid-template-columns: 2fr 1fr; gap: 24px;">' +
            '<div class="card">' +
                '<div class="card-header"><h3 class="card-title">Aksiyalar</h3></div>' +
                '<div class="card-body no-padding">' +
                    '<div class="table-container">' +
                        '<table class="data-table">' +
                            '<thead><tr><th>ID</th><th>Sarlavha</th><th>Kategoriya</th>' +
                            '<th>Muddat</th><th>Holat</th><th>Himoya</th><th>Ovozlar</th><th>Amallar</th></tr></thead>' +
                            '<tbody>' +
                            (campaigns.length === 0
                                ? '<tr><td colspan="8" style="text-align:center;padding:24px;color:var(--gray-400);">Hali aksiya yo\'q</td></tr>'
                                : campaigns.map(function (c) {
                                    var cat = c.category_id && catById[c.category_id]
                                        ? window.escapeHtml(catById[c.category_id].title_uz || '')
                                        : 'Barchasi';
                                    return '<tr>' +
                                        '<td>#' + c.id + '</td>' +
                                        '<td><b>' + window.escapeHtml(c.title || '—') + '</b>' +
                                        (c.prize ? '<br><small style="color:var(--gray-400)">' + window.escapeHtml(c.prize) + '</small>' : '') +
                                        '</td>' +
                                        '<td>' + cat + '</td>' +
                                        '<td>' + campaignDate(c.starts_at) + '<br>' +
                                        '<small style="color:var(--gray-400)">' + campaignDate(c.ends_at) + '</small></td>' +
                                        '<td>' + campaignBadge(c.status) + '</td>' +
                                        '<td>' + (c.require_completed_order
                                            ? '<span class="badge-status active" title="Faqat yakunlangan buyurtmasi bor mijozlar">Mijozlar</span>'
                                            : '<span class="badge-status pending" title="Har kim ovoz bera oladi">Ochiq</span>') + '</td>' +
                                        '<td><b>' + (c.vote_count || 0) + '</b></td>' +
                                        '<td>' +
                                            '<button class="btn btn-sm" onclick="showCampaignBoard(' + c.id + ')">Reyting</button> ' +
                                            '<button class="btn btn-sm" onclick="toggleCampaign(' + c.id + ',' + (!c.is_active) + ')">' +
                                            (c.is_active ? 'To\'xtatish' : 'Yoqish') + '</button> ' +
                                            '<button class="btn btn-sm btn-danger" onclick="deleteCampaign(' + c.id + ')">O\'chirish</button>' +
                                        '</td>' +
                                    '</tr>';
                                }).join('')) +
                            '</tbody>' +
                        '</table>' +
                    '</div>' +
                '</div>' +
            '</div>' +
            '<div class="card">' +
                '<div class="card-header"><h3 class="card-title">Yangi aksiya e\'lon qilish</h3></div>' +
                '<div class="card-body">' +
                    '<form id="addCampaignForm" onsubmit="event.preventDefault(); createCampaign();">' +
                        '<div class="form-group">' +
                            '<label class="form-label">Sarlavha</label>' +
                            '<input type="text" class="form-input" id="cmTitle" placeholder="Eng yaxshi sartarosh — Sentabr" required>' +
                        '</div>' +
                        '<div class="form-group">' +
                            '<label class="form-label">Kategoriya</label>' +
                            '<select class="form-input" id="cmCategory">' + catOptions + '</select>' +
                        '</div>' +
                        '<div class="form-group">' +
                            '<label class="form-label">Boshlanish sanasi</label>' +
                            '<input type="datetime-local" class="form-input" id="cmStart" required>' +
                        '</div>' +
                        '<div class="form-group">' +
                            '<label class="form-label">Tugash sanasi</label>' +
                            '<input type="datetime-local" class="form-input" id="cmEnd" required>' +
                        '</div>' +
                        '<div class="form-group">' +
                            '<label class="form-label">Sovrin</label>' +
                            '<input type="text" class="form-input" id="cmPrize" placeholder="1-o\'rin: 5 000 000 so\'m">' +
                        '</div>' +
                        '<div class="form-group">' +
                            '<label class="form-label">Tavsif</label>' +
                            '<input type="text" class="form-input" id="cmDescription" placeholder="Aksiya haqida qisqacha">' +
                        '</div>' +
                        '<div class="form-group">' +
                            '<label style="display:flex;align-items:flex-start;gap:8px;cursor:pointer">' +
                                '<input type="checkbox" id="cmRequireOrder" checked style="margin-top:3px">' +
                                '<span><b>Faqat mijozlar ovoz bera olsin</b><br>' +
                                '<small style="color:var(--gray-400)">Ovoz berish uchun o\'sha provayderda ' +
                                'yakunlangan buyurtma bo\'lishi shart. Sovrinli musobaqada YOQIB QO\'YING — ' +
                                'aks holda soxta akkauntlar bilan ovoz yig\'ish mumkin.</small></span>' +
                            '</label>' +
                        '</div>' +
                        '<button type="submit" class="btn btn-primary" style="width:100%">E\'lon qilish</button>' +
                    '</form>' +
                '</div>' +
            '</div>' +
        '</div>' +
        '<div id="campaignBoard" style="margin-top:24px"></div>';
}

async function createCampaign() {
    var title = document.getElementById('cmTitle').value.trim();
    var start = document.getElementById('cmStart').value;
    var end = document.getElementById('cmEnd').value;
    if (!title || !start || !end) { apiError('Sarlavha va sanalar majburiy'); return; }
    if (new Date(end) <= new Date(start)) {
        apiError('Tugash sanasi boshlanish sanasidan keyin bo\'lishi kerak');
        return;
    }
    var body = {
        title: title,
        starts_at: new Date(start).toISOString(),
        ends_at: new Date(end).toISOString(),
        prize: document.getElementById('cmPrize').value.trim() || null,
        description: document.getElementById('cmDescription').value.trim() || null,
        require_completed_order: document.getElementById('cmRequireOrder').checked
    };
    var cat = document.getElementById('cmCategory').value;
    if (cat) body.category_id = parseInt(cat, 10);

    try {
        const r = await window.api(window.API_BASE + '/admin/campaigns', {
            method: 'POST',
            headers: Object.assign({ 'Content-Type': 'application/json' }, getAuthHeaders()),
            body: JSON.stringify(body)
        });
        if (r && r.ok) {
            window.showToast('Aksiya e\'lon qilindi');
            renderCampaigns();
        } else {
            var e = r ? await r.json().catch(function () { return {}; }) : {};
            apiError(e.detail || 'Aksiya yaratilmadi');
        }
    } catch (e) { apiError('Aksiya yaratilmadi'); }
}

async function toggleCampaign(id, active) {
    try {
        const r = await window.api(window.API_BASE + '/admin/campaigns/' + id, {
            method: 'PATCH',
            headers: Object.assign({ 'Content-Type': 'application/json' }, getAuthHeaders()),
            body: JSON.stringify({ is_active: active })
        });
        if (r && r.ok) { window.showToast('Holat o\'zgartirildi'); renderCampaigns(); }
        else apiError('O\'zgartirib bo\'lmadi');
    } catch (e) { apiError('O\'zgartirib bo\'lmadi'); }
}

async function deleteCampaign(id) {
    if (!confirm('Aksiya va uning barcha ovozlari o\'chiriladi. Davom etasizmi?')) return;
    try {
        const r = await window.api(window.API_BASE + '/admin/campaigns/' + id, { method: 'DELETE' });
        if (r && r.ok) { window.showToast('Aksiya o\'chirildi'); renderCampaigns(); }
        else apiError('O\'chirib bo\'lmadi');
    } catch (e) { apiError('O\'chirib bo\'lmadi'); }
}

async function showCampaignBoard(id) {
    var box = document.getElementById('campaignBoard');
    if (!box) return;
    var rows = [];
    try {
        const r = await window.api(window.API_BASE + '/admin/campaigns/' + id + '/leaderboard');
        if (r && r.ok) rows = await r.json();
        else { apiError('Reytingni yuklab bo\'lmadi'); return; }
    } catch (e) { apiError('Reytingni yuklab bo\'lmadi'); return; }

    var medals = { 1: '&#127942;', 2: '&#129352;', 3: '&#129353;' };
    box.innerHTML =
        '<div class="card">' +
            '<div class="card-header"><h3 class="card-title">Reyting — aksiya #' + id + '</h3></div>' +
            '<div class="card-body no-padding"><div class="table-container">' +
                '<table class="data-table">' +
                    '<thead><tr><th>O\'rin</th><th>Provayder</th><th>Manzil</th><th>Telefon</th><th>Ovozlar</th></tr></thead>' +
                    '<tbody>' +
                    (rows.length === 0
                        ? '<tr><td colspan="5" style="text-align:center;padding:24px;color:var(--gray-400);">Hali ovoz berilmagan</td></tr>'
                        : rows.map(function (p) {
                            return '<tr>' +
                                '<td>' + (medals[p.position] || '') + ' ' + p.position + '</td>' +
                                '<td><b>' + window.escapeHtml(p.name || '') + '</b></td>' +
                                '<td>' + window.escapeHtml(p.address || '') + '</td>' +
                                '<td>' + window.escapeHtml(p.phone || '') + '</td>' +
                                '<td><b>' + p.votes + '</b></td>' +
                            '</tr>';
                        }).join('')) +
                    '</tbody>' +
                '</table>' +
            '</div></div>' +
        '</div>';
    box.scrollIntoView({ behavior: 'smooth' });
}

// Exports for ES6 modules
export { renderCampaigns, createCampaign, toggleCampaign, deleteCampaign, showCampaignBoard };
// Expose to window for inline onclick handlers
window.renderCampaigns = renderCampaigns;
window.createCampaign = createCampaign;
window.toggleCampaign = toggleCampaign;
window.deleteCampaign = deleteCampaign;
window.showCampaignBoard = showCampaignBoard;
