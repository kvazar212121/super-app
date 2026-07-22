import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: USERS =====
        // ===== PAGE: USERS =====
        let usersPage = 1;
        let usersData = { items: [], total: 0, pages: 1 };

        async function renderUsers(page) {
            if (page === undefined) page = 1;
            usersPage = page;
            var search = '';
            var searchEl = document.getElementById('userSearch');
            if (searchEl) search = searchEl.value;

            let url = window.API_BASE + '/users?page=' + page + '&per_page=20';
            if (search) url += '&search=' + encodeURIComponent(search);

            try {
                const r = await window.api(url);
                if (r && r.ok) usersData = await r.json();
            } catch(e) {
                usersData = emptyPage(); apiError('Foydalanuvchilarni yuklab bo\'lmadi');
            }

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Foydalanuvchilar</h1>' +
                    '<p class="page-subtitle">Foydalanuvchilarni boshqarish (' + usersData.total + ' ta)</p>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-header">' +
                        '<div class="filters-bar" style="margin-bottom:0; width:100%;">' +
                            '<div class="filter-search">' +
                                '<span class="search-icon">&#128269;</span>' +
                                '<input type="text" placeholder="Ism yoki telefon bo\'yicha qidirish..." id="userSearch" value="' + window.escapeHtml(search || '') + '">' +
                            '</div>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card-body no-padding">' +
                        '<div class="table-container">' +
                            '<table class="data-table" id="usersTable">' +
                                '<thead><tr><th>ID</th><th>Foydalanuvchi</th><th>Telefon</th><th>Premium</th><th>Sana</th><th>Amallar</th></tr></thead>' +
                                '<tbody id="usersTableBody">' + renderUserRowsApi(usersData.items) + '</tbody>' +
                            '</table>' +
                        '</div>' +
                    '</div>' +
                    '<div class="pagination">' +
                        '<span class="pagination-info">' + usersData.total + ' ta foydalanuvchi</span>' +
                        '<div class="pagination-buttons" id="usersPagination">' + renderPagination(usersData.pages, usersPage, 'renderUsers') + '</div>' +
                    '</div>' +
                '</div>';

            var userSearchEl = document.getElementById('userSearch');
            var searchTimeout;
            userSearchEl.addEventListener('input', function() {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(function() { renderUsers(1); }, 400);
            });
        }

        function renderUserRowsApi(users) {
            if (!users || users.length === 0) return '<tr><td colspan="8" style="text-align:center;color:var(--gray-400);padding:40px;">Foydalanuvchilar topilmadi</td></tr>';
            return users.map(function(u) {
                var name = (u.name || '') + ' ' + (u.surname || '');
                var created = u.created_at ? window.formatDate(u.created_at) : '—';
                var blocked = !!u.is_blocked;
                var premiumCell = u.is_premium ? '<span class="badge-status confirmed">Premium</span>' : '<span class="badge-status pending">Oddiy</span>';
                if (blocked) premiumCell += ' <span class="badge-status cancelled">Bloklangan</span>';
                var blockBtn = blocked
                    ? '<button class="btn-icon success" title="Blokdan chiqarish" onclick="blockUserApi(' + u.id + ', false)">&#128275;</button>'
                    : '<button class="btn-icon warning" title="Bloklash" onclick="blockUserApi(' + u.id + ', true)">&#128274;</button>';
                return '<tr>' +
                    '<td>' + u.id + '</td>' +
                    '<td><div class="table-user"><div class="table-avatar">' + window.getInitials(name) + '</div><span>' + window.escapeHtml(name.trim()) + '</span></div></td>' +
                    '<td>' + window.escapeHtml(u.phone || '') + '</td>' +
                    '<td>' + premiumCell + '</td>' +
                    '<td>' + created + '</td>' +
                    '<td><div class="action-group">' +
                        '<button class="btn-icon" title="Ko\'rish" onclick="viewUserApi(' + u.id + ')">&#128065;</button>' +
                        blockBtn +
                        '<button class="btn-icon danger" title="O\'chirish" onclick="deleteUserApi(' + u.id + ')">&#128465;</button>' +
                    '</div></td>' +
                '</tr>';
            }).join('');
        }

        function renderPagination(totalPages, currentPage, fnName) {
            if (totalPages <= 1) return '';
            var html = '';
            html += '<button class="pagination-btn" ' + (currentPage <= 1 ? 'disabled' : 'onclick="' + fnName + '(' + (currentPage - 1) + ')"') + '>&#8592;</button>';
            for (var i = 1; i <= Math.min(totalPages, 10); i++) {
                html += '<button class="pagination-btn ' + (i === currentPage ? 'active' : '') + '" onclick="' + fnName + '(' + i + ')">' + i + '</button>';
            }
            html += '<button class="pagination-btn" ' + (currentPage >= totalPages ? 'disabled' : 'onclick="' + fnName + '(' + (currentPage + 1) + ')"') + '>&#8594;</button>';
            return html;
        }

        async function viewUserApi(id) {
            try {
                const r = await window.api(window.API_BASE + '/users/' + id);
                if (!r || !r.ok) { window.showToast('Foydalanuvchi topilmadi', 'error'); return; }
                var u = await r.json();
                var name = (u.name || '') + ' ' + (u.surname || '');
                window.openModal('Foydalanuvchi ma\'lumotlari',
                    '<div class="detail-grid">' +
                        '<div class="detail-item"><div class="detail-label">ID</div><div class="detail-value">' + u.id + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Ism</div><div class="detail-value">' + window.escapeHtml(name) + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Telefon</div><div class="detail-value">' + window.escapeHtml(u.phone) + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Balans</div><div class="detail-value">' + window.formatMoney(u.balance) + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Premium</div><div class="detail-value">' + (u.is_premium ? 'Ha' : 'Yo\'q') + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Telegram</div><div class="detail-value">' + window.escapeHtml(u.telegram_username || '—') + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Sana</div><div class="detail-value">' + (u.created_at ? window.formatDate(u.created_at) : '—') + '</div></div>' +
                    '</div>' +
                    '<div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:16px;">' +
                        '<button class="btn btn-primary" onclick="topUpBalanceApi(' + u.id + ')">💰 Balans to\'ldirish</button>' +
                        (u.is_premium
                            ? '<button class="btn btn-secondary" onclick="revokePremiumApi(' + u.id + ')">⭐ Premiumni bekor qilish</button>'
                            : '<button class="btn btn-primary" onclick="grantPremiumApi(' + u.id + ')">⭐ Premium berish</button>') +
                    '</div>',
                    '<button class="btn btn-secondary" onclick="window.closeModal()">Yopish</button>');
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        // ===== Balans to'ldirish (admin) =====
        async function topUpBalanceApi(id) {
            var input = prompt('Balansga qancha pul qo\'shiladi? (so\'m)\nManfiy son yechish uchun. Masalan: 50000');
            if (input === null) return;
            var amount = parseFloat(String(input).replace(/\s/g, '').replace(',', '.'));
            if (isNaN(amount) || amount === 0) { window.showToast('Noto\'g\'ri summa', 'error'); return; }
            try {
                const r = await window.api(window.API_BASE + '/users/' + id + '/balance', {
                    method: 'POST',
                    body: JSON.stringify({ amount: amount, description: 'Admin balans o\'zgartirdi' })
                });
                if (!r || !r.ok) {
                    var msg = 'Xatolik';
                    try { var e = await r.json(); if (e && e.detail) msg = e.detail; } catch(_) {}
                    window.showToast(msg, 'error');
                    return;
                }
                var u = await r.json();
                window.showToast('Balans yangilandi: ' + window.formatMoney(u.balance), 'success');
                window.closeModal();
                renderUsers(usersPage);
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        // ===== Premium berish (admin) =====
        async function grantPremiumApi(id) {
            var input = prompt('Necha kunga premium beriladi?', '30');
            if (input === null) return;
            var days = parseInt(input, 10);
            if (isNaN(days) || days < 1) { window.showToast('Noto\'g\'ri kun soni', 'error'); return; }
            try {
                const r = await window.api(window.API_BASE + '/users/' + id + '/premium', {
                    method: 'POST',
                    body: JSON.stringify({ is_premium: true, days: days })
                });
                if (!r || !r.ok) { window.showToast('Xatolik', 'error'); return; }
                window.showToast(days + ' kunlik premium berildi', 'success');
                window.closeModal();
                renderUsers(usersPage);
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        async function revokePremiumApi(id) {
            if (!confirm('Premiumni bekor qilasizmi?')) return;
            try {
                const r = await window.api(window.API_BASE + '/users/' + id + '/premium', {
                    method: 'POST',
                    body: JSON.stringify({ is_premium: false, days: 0 })
                });
                if (!r || !r.ok) { window.showToast('Xatolik', 'error'); return; }
                window.showToast('Premium bekor qilindi', 'info');
                window.closeModal();
                renderUsers(usersPage);
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        async function blockUserApi(id, block) {
            if (block === undefined) block = true;
            var msg = block ? 'Foydalanuvchini bloklaysizmi?' : 'Foydalanuvchini blokdan chiqarasizmi?';
            if (!confirm(msg)) return;
            try {
                await window.api(window.API_BASE + '/users/' + id + '/block', { method: 'PATCH', body: JSON.stringify({ is_blocked: !!block }) });
                window.showToast(block ? 'Foydalanuvchi bloklandi' : 'Foydalanuvchi blokdan chiqarildi', 'info');
                renderUsers(usersPage);
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        async function deleteUserApi(id) {
            if (!confirm('Rostdan ham bu foydalanuvchini o\'chirmoqchimisiz?')) return;
            try {
                await window.api(window.API_BASE + '/users/' + id, { method: 'DELETE' });
                window.showToast('Foydalanuvchi o\'chirildi', 'error');
                renderUsers(usersPage);
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }


        

// Exports for ES6 modules
export { renderUsers, renderUserRowsApi, renderPagination, blockUserApi, deleteUserApi, viewUserApi, topUpBalanceApi, grantPremiumApi, revokePremiumApi };
// Expose to window for inline onclick handlers
window.renderUsers = renderUsers;
window.renderUserRowsApi = renderUserRowsApi;
window.renderPagination = renderPagination;
window.blockUserApi = blockUserApi;
window.deleteUserApi = deleteUserApi;
window.viewUserApi = viewUserApi;
window.topUpBalanceApi = topUpBalanceApi;
window.grantPremiumApi = grantPremiumApi;
window.revokePremiumApi = revokePremiumApi;
