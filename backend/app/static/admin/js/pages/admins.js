import { API_BASE, api } from '../api.js';
import { showToast } from '../ui.js';

var _schema = { sections: [], actions: ['view', 'edit'] };
var _roles = [];

async function renderAdmins() {
    try {
        var rs = await window.api(window.API_BASE + '/permission-schema');
        if (rs && rs.ok) _schema = await rs.json();
    } catch (e) {}
    try {
        var rr = await window.api(window.API_BASE + '/roles');
        if (rr && rr.ok) _roles = await rr.json();
    } catch (e) { _roles = []; }
    var admins = [];
    try {
        var ra = await window.api(window.API_BASE + '/admins');
        if (ra && ra.ok) admins = await ra.json();
    } catch (e) {}
    var audit = [];
    try {
        var au = await window.api(window.API_BASE + '/audit-logs?limit=50');
        if (au && au.ok) audit = await au.json();
    } catch (e) {}

    var roleOpts = '<option value="">— rol tanlang —</option>' +
        _roles.map(function (r) { return '<option value="' + r.id + '">' + window.escapeHtml(r.name) + '</option>'; }).join('');

    // Rollar jadvali
    var roleRows = _roles.map(function (r) {
        var summary = Object.keys(r.permissions || {}).map(function (k) {
            return k + '(' + (r.permissions[k] || []).join('/') + ')';
        }).join(', ') || '—';
        return '<tr><td>' + window.escapeHtml(r.name) + '</td><td style="font-size:12px;color:#64748b;">' + summary + '</td>' +
            '<td><button class="btn btn-sm" onclick="editRole(' + r.id + ')">✏️</button> ' +
            '<button class="btn btn-sm" onclick="deleteRole(' + r.id + ')">🗑️</button></td></tr>';
    }).join('');

    // Adminlar jadvali
    var adminRows = admins.map(function (a) {
        var badge = a.is_super_admin ? '<span style="color:#7c3aed;font-weight:700;">SUPER ADMIN</span>' : window.escapeHtml(a.role_name || '—');
        return '<tr><td>' + window.escapeHtml(a.name) + ' ' + window.escapeHtml(a.surname) + '</td><td>' + window.escapeHtml(a.phone) + '</td><td>' + badge + '</td>' +
            '<td>' + (a.is_active ? '✅' : '⛔') + '</td>' +
            '<td>' + (a.is_super_admin ? '' :
                '<button class="btn btn-sm" onclick="changeAdminRole(' + a.id + ')">Rol</button> ' +
                '<button class="btn btn-sm" onclick="resetAdminPass(' + a.id + ')">🔑</button> ' +
                '<button class="btn btn-sm" onclick="revokeAdmin(' + a.id + ')">🗑️</button>') + '</td></tr>';
    }).join('');

    // Audit jadvali
    var auditRows = audit.map(function (x) {
        var t = x.created_at ? new Date(x.created_at).toLocaleString() : '';
        return '<tr><td style="font-size:12px;">' + t + '</td><td>' + window.escapeHtml(x.admin_name || '#' + x.admin_user_id) + '</td>' +
            '<td>' + window.escapeHtml(x.section) + '</td><td>' + window.escapeHtml(x.action) + '</td><td style="font-size:12px;color:#64748b;">' + window.escapeHtml(x.path) + '</td></tr>';
    }).join('');

    mainContent.innerHTML =
        '<div class="page-header"><h1 class="page-title">Adminlar va rollar</h1>' +
        '<p class="page-subtitle">Yangi admin qo\'shish, rol va ruxsatlarni boshqarish</p></div>' +

        // Rollar
        '<div class="card"><div class="card-body">' +
        '<h3 class="settings-section-title">🧩 Rollar</h3>' +
        '<p class="setting-description" style="margin-bottom:10px;">Har rol qaysi bo\'limlarni ko\'rishi/tahrirlashini belgilaydi.</p>' +
        '<table class="data-table"><thead><tr><th>Nomi</th><th>Ruxsatlar</th><th>Amal</th></tr></thead><tbody>' +
        (roleRows || '<tr><td colspan="3">Hali rol yo\'q</td></tr>') + '</tbody></table>' +
        '<div style="padding-top:12px;"><button class="btn btn-primary" onclick="newRole()">+ Yangi rol</button></div>' +
        '<div id="roleEditor" style="margin-top:16px;"></div>' +
        '</div></div>' +

        // Adminlar
        '<div class="card"><div class="card-body">' +
        '<h3 class="settings-section-title">👤 Adminlar</h3>' +
        '<table class="data-table"><thead><tr><th>Ism</th><th>Login</th><th>Rol</th><th>Faol</th><th>Amal</th></tr></thead><tbody>' +
        (adminRows || '<tr><td colspan="5">—</td></tr>') + '</tbody></table>' +
        '<div style="margin-top:16px; padding:16px; background:#f8fafc; border-radius:12px;">' +
        '<b>Yangi admin qo\'shish</b>' +
        '<div style="display:flex; gap:8px; flex-wrap:wrap; margin-top:10px;">' +
        '<input class="form-input" id="na_name" placeholder="Ism" style="width:140px;">' +
        '<input class="form-input" id="na_surname" placeholder="Familiya" style="width:140px;">' +
        '<input class="form-input" id="na_phone" placeholder="Login (yoki telefon)" style="width:160px;">' +
        '<input class="form-input" id="na_pass" placeholder="Parol" type="password" style="width:130px;">' +
        '<select class="form-input" id="na_role" style="width:180px;">' + roleOpts + '</select>' +
        '<button class="btn btn-primary" onclick="createAdmin()">Qo\'shish</button>' +
        '</div></div>' +
        '</div></div>' +

        // Audit
        '<div class="card"><div class="card-body">' +
        '<h3 class="settings-section-title">📜 Harakatlar tarixi (audit)</h3>' +
        '<div style="max-height:360px; overflow-y:auto;">' +
        '<table class="data-table"><thead><tr><th>Vaqt</th><th>Admin</th><th>Bo\'lim</th><th>Amal</th><th>Yo\'l</th></tr></thead><tbody>' +
        (auditRows || '<tr><td colspan="5">Yozuv yo\'q</td></tr>') + '</tbody></table></div>' +
        '</div></div>';
}

function _roleEditorHtml(role) {
    var isEdit = !!role;
    var perms = (role && role.permissions) || {};
    var rows = _schema.sections.map(function (s) {
        var cur = perms[s.key] || [];
        var checks = _schema.actions.map(function (act) {
            var id = 'perm_' + s.key + '_' + act;
            var checked = cur.indexOf(act) !== -1 ? ' checked' : '';
            return '<label style="margin-right:14px;"><input type="checkbox" id="' + id + '"' + checked + '> ' + act + '</label>';
        }).join('');
        return '<div class="setting-row"><div class="setting-info"><div class="setting-label">' + window.escapeHtml(s.label) + '</div></div>' +
            '<div class="setting-control">' + checks + '</div></div>';
    }).join('');
    return '<div style="padding:16px; background:#f8fafc; border-radius:12px;">' +
        '<b>' + (isEdit ? 'Rolni tahrirlash' : 'Yangi rol') + '</b>' +
        '<input class="form-input" id="role_name" placeholder="Rol nomi" value="' + window.escapeHtml(role ? role.name : '') + '" style="width:260px; margin:10px 0;">' +
        rows +
        '<div style="padding-top:12px;">' +
        '<button class="btn btn-primary" onclick="saveRole(' + (role ? role.id : 'null') + ')">💾 Saqlash</button> ' +
        '<button class="btn" onclick="document.getElementById(\'roleEditor\').innerHTML=\'\'">Bekor</button>' +
        '</div></div>';
}

function newRole() { document.getElementById('roleEditor').innerHTML = _roleEditorHtml(null); }
function editRole(id) {
    var role = _roles.find(function (r) { return r.id === id; });
    document.getElementById('roleEditor').innerHTML = _roleEditorHtml(role);
}
function _collectPerms() {
    var perms = {};
    _schema.sections.forEach(function (s) {
        var acts = [];
        _schema.actions.forEach(function (act) {
            var el = document.getElementById('perm_' + s.key + '_' + act);
            if (el && el.checked) acts.push(act);
        });
        if (acts.length) perms[s.key] = acts;
    });
    return perms;
}
function saveRole(id) {
    var name = document.getElementById('role_name').value.trim();
    if (!name) { window.showToast('Rol nomini kiriting', 'error'); return; }
    var body = JSON.stringify({ name: name, permissions: _collectPerms() });
    var url = window.API_BASE + '/roles' + (id ? '/' + id : '');
    window.api(url, { method: id ? 'PUT' : 'POST', body: body }).then(function (r) {
        if (r && r.ok) { window.showToast('Rol saqlandi ✅'); renderAdmins(); }
        else { window.showToast('Saqlab bo\'lmadi', 'error'); }
    });
}
function deleteRole(id) {
    if (!confirm('Rolni o\'chirasizmi?')) return;
    window.api(window.API_BASE + '/roles/' + id, { method: 'DELETE' }).then(function (r) {
        window.showToast(r && r.ok ? 'O\'chirildi' : 'Xatolik', r && r.ok ? 'success' : 'error');
        renderAdmins();
    });
}
function createAdmin() {
    var body = JSON.stringify({
        name: document.getElementById('na_name').value.trim(),
        surname: document.getElementById('na_surname').value.trim(),
        phone: document.getElementById('na_phone').value.trim(),
        password: document.getElementById('na_pass').value,
        role_id: document.getElementById('na_role').value ? parseInt(document.getElementById('na_role').value) : null
    });
    window.api(window.API_BASE + '/admins', { method: 'POST', body: body }).then(async function (r) {
        if (r && r.ok) { window.showToast('Admin qo\'shildi ✅'); renderAdmins(); }
        else { var e = await r.json().catch(function () { return {}; }); window.showToast(e.detail || 'Xatolik', 'error'); }
    });
}
function changeAdminRole(id) {
    var opts = _roles.map(function (r) { return r.id + '=' + r.name; }).join(', ');
    var val = prompt('Rol ID kiriting (' + opts + '), bo\'sh = rolsiz:');
    if (val === null) return;
    var role_id = val.trim() ? parseInt(val.trim()) : null;
    window.api(window.API_BASE + '/admins/' + id, { method: 'PUT', body: JSON.stringify({ role_id: role_id }) })
        .then(function (r) { window.showToast(r && r.ok ? 'Yangilandi' : 'Xatolik', r && r.ok ? 'success' : 'error'); renderAdmins(); });
}
function resetAdminPass(id) {
    var p = prompt('Yangi parol (kamida 4 belgi):');
    if (!p || p.length < 4) return;
    window.api(window.API_BASE + '/admins/' + id, { method: 'PUT', body: JSON.stringify({ password: p }) })
        .then(function (r) { window.showToast(r && r.ok ? 'Parol yangilandi' : 'Xatolik', r && r.ok ? 'success' : 'error'); });
}
function revokeAdmin(id) {
    if (!confirm('Bu foydalanuvchidan admin huquqini olib tashlaysizmi?')) return;
    window.api(window.API_BASE + '/admins/' + id, { method: 'DELETE' })
        .then(function (r) { window.showToast(r && r.ok ? 'Olib tashlandi' : 'Xatolik', r && r.ok ? 'success' : 'error'); renderAdmins(); });
}

export { renderAdmins };
window.renderAdmins = renderAdmins;
window.newRole = newRole;
window.editRole = editRole;
window.saveRole = saveRole;
window.deleteRole = deleteRole;
window.createAdmin = createAdmin;
window.changeAdminRole = changeAdminRole;
window.resetAdminPass = resetAdminPass;
window.revokeAdmin = revokeAdmin;
