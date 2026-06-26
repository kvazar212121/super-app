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
                                '<input type="text" placeholder="Ism yoki telefon bo\'yicha qidirish..." id="userSearch" value="' + (search || '') + '">' +
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
                return '<tr>' +
                    '<td>' + u.id + '</td>' +
                    '<td><div class="table-user"><div class="table-avatar">' + window.getInitials(name) + '</div><span>' + name.trim() + '</span></div></td>' +
                    '<td>' + (u.phone || '') + '</td>' +
                    '<td>' + (u.is_premium ? '<span class="badge-status confirmed">Premium</span>' : '<span class="badge-status pending">Oddiy</span>') + '</td>' +
                    '<td>' + created + '</td>' +
                    '<td><div class="action-group">' +
                        '<button class="btn-icon" title="Ko\'rish" onclick="viewUserApi(' + u.id + ')">&#128065;</button>' +
                        '<button class="btn-icon warning" title="Bloklash" onclick="blockUserApi(' + u.id + ')">&#128274;</button>' +
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
                        '<div class="detail-item"><div class="detail-label">Ism</div><div class="detail-value">' + name + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Telefon</div><div class="detail-value">' + u.phone + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Balans</div><div class="detail-value">' + window.formatMoney(u.balance) + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Cashback</div><div class="detail-value">' + window.formatMoney(u.cashback) + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Premium</div><div class="detail-value">' + (u.is_premium ? 'Ha' : 'Yo\'q') + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Telegram</div><div class="detail-value">' + (u.telegram_username || '—') + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Sana</div><div class="detail-value">' + (u.created_at ? window.formatDate(u.created_at) : '—') + '</div></div>' +
                    '</div>',
                    '<button class="btn btn-secondary" onclick="window.closeModal()">Yopish</button>');
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        async function blockUserApi(id) {
            if (!confirm('Foydalanuvchini bloklash/blokdan chiqarish?')) return;
            try {
                await window.api(window.API_BASE + '/users/' + id + '/block', { method: 'PATCH', body: JSON.stringify({ is_blocked: true }) });
                window.showToast('Foydalanuvchi holati o\'zgartirildi', 'info');
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
export { renderUsers, renderUserRowsApi, renderPagination, blockUserApi, deleteUserApi, viewUserApi };
// Expose to window for inline onclick handlers
window.renderUsers = renderUsers;
window.renderUserRowsApi = renderUserRowsApi;
window.renderPagination = renderPagination;
window.blockUserApi = blockUserApi;
window.deleteUserApi = deleteUserApi;
window.viewUserApi = viewUserApi;
