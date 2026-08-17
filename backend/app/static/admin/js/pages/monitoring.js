import { API_BASE, apiError, api } from '../api.js';

// ===== PAGE: MONITORING =====
//
// Bu sahifa ilgari KO'RINMAYDIGAN ma'lumotlarni ochadi. Har biri uchun
// ma'lumot allaqachon yig'ilardi, lekin admin uni ko'ra olmasdi:
//   - firibgarlik statistikasi (no_show / nizolar)
//   - provayderlar bloklagan mijozlar
//   - ish e'lonlari va takliflar konversiyasi
//   - push qamrovi (nechta odamga bildirishnoma yetib boradi)
//   - kunlik faollik

function fraudBadge(level) {
    var map = {
        normal: ['Normal', 'active'],
        warning: ['Ogohlantirish', 'pending'],
        alert: ['Xavf', 'cancelled'],
        suspended: ['To\'xtatilgan', 'cancelled']
    };
    var pair = map[level] || [level, 'pending'];
    return '<span class="badge-status ' + pair[1] + '">' + window.escapeHtml(pair[0]) + '</span>';
}

function statCard(label, value, hint) {
    return '<div class="stat-card">' +
        '<div class="stat-label">' + window.escapeHtml(label) + '</div>' +
        '<div class="stat-value">' + value + '</div>' +
        (hint ? '<div class="stat-hint" style="font-size:12px;color:var(--gray-400)">' +
            window.escapeHtml(hint) + '</div>' : '') +
        '</div>';
}

async function renderMonitoring() {
    mainContent.innerHTML =
        '<div class="page-header">' +
            '<h1 class="page-title">Monitoring</h1>' +
            '<p class="page-subtitle">Firibgarlik, ish e\'lonlari, bildirishnoma qamrovi va faollik</p>' +
        '</div>' +
        '<div id="monBody"><div class="card"><div class="card-body">Yuklanmoqda…</div></div></div>';

    var fraud = null, jobs = null, reach = null, blocked = null;
    try {
        var r1 = await window.api(window.API_BASE + '/admin/monitoring/fraud');
        if (r1 && r1.ok) fraud = await r1.json();
    } catch (e) { /* pastda ko'rsatiladi */ }
    try {
        var r2 = await window.api(window.API_BASE + '/admin/monitoring/jobs');
        if (r2 && r2.ok) jobs = await r2.json();
    } catch (e) { /* */ }
    try {
        var r3 = await window.api(window.API_BASE + '/admin/monitoring/push-reach');
        if (r3 && r3.ok) reach = await r3.json();
    } catch (e) { /* */ }
    try {
        var r4 = await window.api(window.API_BASE + '/admin/monitoring/blocked-users');
        if (r4 && r4.ok) blocked = await r4.json();
    } catch (e) { /* */ }

    var html = '';

    // ── Umumiy ko'rsatkichlar ────────────────────────────────────────
    html += '<div class="stats-grid" style="display:grid;grid-template-columns:repeat(auto-fit,minmax(180px,1fr));gap:16px;margin-bottom:24px">';
    if (reach) {
        html += statCard('Push qamrovi', reach.reach_percent + '%',
            reach.users_without_token + ' odamda qurilma tokeni yo\'q — ular bildirishnoma OLMAYDI');
        html += statCard('Qurilmalar', reach.total_devices, reach.users_with_token + ' foydalanuvchi');
    }
    if (jobs && jobs.summary) {
        html += statCard('Ish e\'lonlari', Object.values(jobs.summary.by_status || {})
            .reduce(function (a, b) { return a + b; }, 0), 'jami');
        html += statCard('Taklif konversiyasi', jobs.summary.conversion_percent + '%',
            jobs.summary.accepted_offers + '/' + jobs.summary.total_offers + ' taklif qabul qilindi');
        html += statCard('Taklifsiz e\'lonlar', jobs.summary.open_without_offers,
            'ochiq, lekin hech kim taklif bermagan');
    }
    if (fraud && fraud.summary) {
        html += statCard('Shubhali provayderlar',
            (fraud.summary.alert || 0) + (fraud.summary.suspended || 0),
            fraud.month + ' oyi');
    }
    html += '</div>';

    // ── Firibgarlik ──────────────────────────────────────────────────
    html += '<div class="card" style="margin-bottom:24px">' +
        '<div class="card-header"><h3 class="card-title">Firibgarlik monitoringi</h3></div>' +
        '<div class="card-body no-padding"><div class="table-container">' +
        '<table class="data-table"><thead><tr>' +
        '<th>Provayder</th><th>Telefon</th><th>Buyurtma</th><th>Kelmagan</th>' +
        '<th>Kelmaslik %</th><th>Nizo</th><th>Daraja</th></tr></thead><tbody>';
    if (!fraud || !fraud.items || fraud.items.length === 0) {
        html += '<tr><td colspan="7" style="text-align:center;padding:24px;color:var(--gray-400);">' +
            (fraud ? 'Bu oyda ma\'lumot yo\'q' : 'Yuklab bo\'lmadi') + '</td></tr>';
    } else {
        html += fraud.items.map(function (f) {
            return '<tr>' +
                '<td><b>' + window.escapeHtml(f.provider_name || '') + '</b></td>' +
                '<td>' + window.escapeHtml(f.provider_phone || '') + '</td>' +
                '<td>' + f.total_orders + '</td>' +
                '<td>' + f.no_show_count + '</td>' +
                '<td>' + f.no_show_rate + '%</td>' +
                '<td>' + f.disputed_count + '</td>' +
                '<td>' + fraudBadge(f.flag_level) + '</td>' +
            '</tr>';
        }).join('');
    }
    html += '</tbody></table></div></div></div>';

    // ── Ish e'lonlari ────────────────────────────────────────────────
    html += '<div class="card" style="margin-bottom:24px">' +
        '<div class="card-header"><h3 class="card-title">Ish e\'lonlari</h3></div>' +
        '<div class="card-body no-padding"><div class="table-container">' +
        '<table class="data-table"><thead><tr>' +
        '<th>ID</th><th>Sarlavha</th><th>Mijoz</th><th>Summa</th>' +
        '<th>Takliflar</th><th>Holat</th></tr></thead><tbody>';
    if (!jobs || !jobs.items || jobs.items.length === 0) {
        html += '<tr><td colspan="6" style="text-align:center;padding:24px;color:var(--gray-400);">' +
            (jobs ? 'E\'lon yo\'q' : 'Yuklab bo\'lmadi') + '</td></tr>';
    } else {
        html += jobs.items.map(function (j) {
            return '<tr>' +
                '<td>#' + j.id + '</td>' +
                '<td><b>' + window.escapeHtml(j.title || '') + '</b></td>' +
                '<td>' + window.escapeHtml(j.user_name || '') + '<br>' +
                '<small style="color:var(--gray-400)">' + window.escapeHtml(j.user_phone || '') + '</small></td>' +
                '<td>' + (j.budget ? Number(j.budget).toLocaleString('uz-UZ') : '—') + '</td>' +
                '<td>' + j.offers_count + '</td>' +
                '<td>' + window.escapeHtml(j.status || '') + '</td>' +
            '</tr>';
        }).join('');
    }
    html += '</tbody></table></div></div></div>';

    // ── Bloklangan mijozlar ──────────────────────────────────────────
    html += '<div class="card">' +
        '<div class="card-header"><h3 class="card-title">Provayderlar bloklagan mijozlar</h3></div>' +
        '<div class="card-body no-padding"><div class="table-container">' +
        '<table class="data-table"><thead><tr>' +
        '<th>Mijoz</th><th>Telefon</th><th>Kim bloklagan</th>' +
        '<th>Necha marta bloklangan</th><th>Sana</th></tr></thead><tbody>';
    if (!blocked || !blocked.items || blocked.items.length === 0) {
        html += '<tr><td colspan="5" style="text-align:center;padding:24px;color:var(--gray-400);">' +
            (blocked ? 'Bloklangan mijoz yo\'q' : 'Yuklab bo\'lmadi') + '</td></tr>';
    } else {
        html += blocked.items.map(function (b) {
            var many = b.blocked_by_count >= 3;
            return '<tr>' +
                '<td><b>' + window.escapeHtml(b.user_name || '') + '</b></td>' +
                '<td>' + window.escapeHtml(b.user_phone || '') + '</td>' +
                '<td>' + window.escapeHtml(b.provider_name || '') + '</td>' +
                '<td>' + (many
                    ? '<span class="badge-status cancelled">' + b.blocked_by_count + '</span>'
                    : b.blocked_by_count) + '</td>' +
                '<td>' + (b.created_at ? new Date(b.created_at).toLocaleDateString('uz-UZ') : '—') + '</td>' +
            '</tr>';
        }).join('');
    }
    html += '</tbody></table></div></div></div>';

    document.getElementById('monBody').innerHTML = html;
}

export { renderMonitoring };
window.renderMonitoring = renderMonitoring;
