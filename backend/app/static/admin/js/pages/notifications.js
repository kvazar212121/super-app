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
                        '<div class="card-header"><h3 class="card-title">Yuborilgan bildirishnomalar</h3></div>' +
                        '<div class="card-body no-padding">' +
                            '<div class="table-container">' +
                                '<table class="data-table">' +
                                    '<thead><tr><th>ID</th><th>Tur</th><th>Sarlavha</th><th>Kimlarga</th><th>Soni</th><th>Sana</th></tr></thead>' +
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
                '</tr>';
            });

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

        

// Exports for ES6 modules
export { selectNotifType, renderNotifications, sendNotification };
// Expose to window for inline onclick handlers
window.selectNotifType = selectNotifType;
window.renderNotifications = renderNotifications;
window.sendNotification = sendNotification;
