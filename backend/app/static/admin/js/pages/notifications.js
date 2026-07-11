import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: NOTIFICATIONS =====
        async function renderNotifications() {
            var notifItems = [];
            try {
                const r = await window.api(window.API_BASE + '/notifications');
                if (r && r.ok) {
                    var data = await r.json();
                    notifItems = data.items || [];
                }
            } catch(e) {}

            // Bildirishnoma shablonlari (AI va Bildirishnomalar bo'limида tahrirlanadi)
            var notifTpls = [];
            try {
                const rt = await window.api(window.API_BASE + '/notif-templates');
                if (rt && rt.ok) { var dt = await rt.json(); notifTpls = dt.templates || []; }
            } catch(e) {}
            window._notifTplCache = notifTpls;
            var tplOptions = '<option value="">— Shablon tanlang (ixtiyoriy) —</option>' +
                notifTpls.map(function(t, i){ return '<option value="'+i+'">'+window.escapeHtml(t.title || ('Shablon '+(i+1)))+'</option>'; }).join('');

            var html =
                '<div class="page-header">' +
                    '<h1 class="page-title">Bildirishnomalar</h1>' +
                    '<p class="page-subtitle">Push, email va SMS bildirishnomalar yuborish</p>' +
                '</div>' +
                '<div style="display:grid; grid-template-columns: 1fr 1fr; gap:24px;">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Yangi bildirishnoma</h3></div>' +
                        '<div class="card-body">' +
                            '<div class="form-group">' +
                                '<label class="form-label">Tur</label>' +
                                '<div class="type-selector" id="notifTypeSelector">' +
                                    '<div class="type-option selected" data-type="push" onclick="selectNotifType(this)">&#128241; Push</div>' +
                                    '<div class="type-option" data-type="email" onclick="selectNotifType(this)">&#9993; Email</div>' +
                                    '<div class="type-option" data-type="sms" onclick="selectNotifType(this)">&#128242; SMS</div>' +
                                    '<div class="type-option" data-type="in_app" onclick="selectNotifType(this)">&#128276; In-App</div>' +
                                '</div>' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Shablon</label>' +
                                '<select class="form-input" id="notifTpl" onchange="applyNotifTpl(this.value)">' + tplOptions + '</select>' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Sarlavha</label>' +
                                '<input type="text" class="form-input" id="notifTitle" placeholder="Bildirishnoma sarlavhasi">' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Xabar</label>' +
                                '<textarea class="form-input" id="notifMessage" placeholder="Xabar matni..." rows="4"></textarea>' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Kimlarga yuborish</label>' +
                                '<select class="form-input" id="notifTarget">' +
                                    '<option value="all">Barcha foydalanuvchilar</option>' +
                                    '<option value="users">Faqat foydalanuvchilar</option>' +
                                    '<option value="providers">Faqat soha egalari</option>' +
                                '</select>' +
                            '</div>' +
                            '<button class="btn btn-primary" onclick="sendNotification()" style="width:100%;">&#128640; Yuborish</button>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header" style="display:flex;justify-content:space-between;align-items:center;">' +
                            '<h3 class="card-title">Yuborilgan bildirishnomalar</h3>' +
                            '<div style="display:flex;gap:8px;">' +
                                '<button class="btn btn-sm" onclick="clearNotifications(true)" title="O\'qilganlarni tozalash">🧹 O\'qilganlar</button>' +
                                '<button class="btn btn-sm" onclick="clearNotifications(false)" style="color:#dc2626;" title="Hammasini tozalash">🗑 Hammasini tozalash</button>' +
                            '</div>' +
                        '</div>' +
                        '<div class="card-body no-padding">' +
                            '<div class="table-container">' +
                                '<table class="data-table">' +
                                    '<thead><tr><th>ID</th><th>Tur</th><th>Sarlavha</th><th>Kimlarga</th><th>Soni</th><th>Sana</th><th></th></tr></thead>' +
                                    '<tbody>';

            notifItems.forEach(function(n) {
                var typeClass = n.type === 'push' ? 'confirmed' : n.type === 'email' ? 'active' : n.type === 'sms' ? 'in_progress' : 'pending';
                var targetLabel = n.target === 'all' ? 'Barcha' : n.target === 'users' ? 'Foydalanuvchilar' : 'Providerlar';
                html += '<tr>' +
                    '<td>' + (n.id || '-') + '</td>' +
                    '<td><span class="badge-status ' + typeClass + '">' + window.escapeHtml((n.type || 'in_app').toUpperCase()) + '</span></td>' +
                    '<td>' + window.escapeHtml(n.title || '') + '</td>' +
                    '<td>' + targetLabel + '</td>' +
                    '<td>' + (n.count || 0).toLocaleString() + '</td>' +
                    '<td>' + window.escapeHtml(n.sent_at || n.created_at || '-') + '</td>' +
                    '<td><button class="btn btn-sm" onclick="deleteNotification(' + (n.id || 0) + ')" style="color:#dc2626;" title="O\'chirish">🗑</button></td>' +
                '</tr>';
            });

            if (!notifItems.length) {
                html += '<tr><td colspan="7" style="text-align:center;color:#94a3b8;padding:20px;">Bildirishnoma yo\'q</td></tr>';
            }

            html += '</tbody></table></div></div></div></div></div>';
            mainContent.innerHTML = html;
        }

        function selectNotifType(el) {
            document.querySelectorAll('#notifTypeSelector .type-option').forEach(function(o) { o.classList.remove('selected'); });
            el.classList.add('selected');
        }

        function sendNotification() {
            var title = document.getElementById('notifTitle').value.trim();
            var message = document.getElementById('notifMessage').value.trim();
            var target = document.getElementById('notifTarget').value;
            var selected = document.querySelector('#notifTypeSelector .type-option.selected');
            var type = selected ? selected.dataset.type : 'push';

            if (!title || !message) { window.showToast('Sarlavha va xabar majburiy', 'error'); return; }

            window.api(window.API_BASE + '/notifications/send', {
                method: 'POST',
                body: JSON.stringify({ type: type, title: title, message: message, target: target })
            }).then(function(r) {
                if (r && r.ok) {
                    window.showToast('"' + title + '" bildirishnomasi yuborildi');
                    renderNotifications();
                } else {
                    window.showToast('Yuborib bo\'lmadi', 'error');
                }
            });
        }

        

// Bitta bildirishnomani o'chirish
function deleteNotification(id) {
    if (!id) return;
    if (!confirm('Bu bildirishnomani o\'chirasizmi?')) return;
    window.api(window.API_BASE + '/notifications/' + id, { method: 'DELETE' })
        .then(function (r) {
            window.showToast(r && r.ok ? 'O\'chirildi' : 'Xatolik', r && r.ok ? 'success' : 'error');
            if (r && r.ok) renderNotifications();
        });
}

// Bildirishnomalar tarixini tozalash (hammasi yoki faqat o'qilganlar)
function clearNotifications(onlyRead) {
    var msg = onlyRead ? 'O\'qilgan bildirishnomalarni tozalaysizmi?' : 'BARCHA bildirishnomalarni tozalaysizmi? Bu amalni ortga qaytarib bo\'lmaydi.';
    if (!confirm(msg)) return;
    window.api(window.API_BASE + '/notifications?only_read=' + (onlyRead ? 'true' : 'false'), { method: 'DELETE' })
        .then(function (r) {
            if (r && r.ok) {
                r.json().then(function (d) { window.showToast((d.cleared || 0) + ' ta tozalandi ✅', 'success'); renderNotifications(); });
            } else window.showToast('Xatolik', 'error');
        });
}

// Tanlangan shablonni sarlavha/xabar maydonlariga to'ldiradi
function applyNotifTpl(idx) {
    var tpls = window._notifTplCache || [];
    var t = tpls[parseInt(idx, 10)];
    if (!t) return;
    var titleEl = document.getElementById('notifTitle');
    var msgEl = document.getElementById('notifMessage');
    if (titleEl) titleEl.value = t.title || '';
    if (msgEl) msgEl.value = t.message || '';
}

// Exports for ES6 modules
export { selectNotifType, renderNotifications, sendNotification };
// Expose to window for inline onclick handlers
window.selectNotifType = selectNotifType;
window.renderNotifications = renderNotifications;
window.sendNotification = sendNotification;
window.applyNotifTpl = applyNotifTpl;
window.deleteNotification = deleteNotification;
window.clearNotifications = clearNotifications;
