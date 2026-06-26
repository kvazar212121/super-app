import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: ORDERS =====
        let ordersPage = 1;
        let ordersData = { items: [], total: 0, pages: 1 };

        async function renderOrders(page) {
            if (page === undefined) page = 1;
            ordersPage = page;
            var status = '';
            var statusEl = document.getElementById('orderStatusFilter');
            if (statusEl) status = statusEl.value;

            let url = window.API_BASE + '/orders?page=' + page + '&per_page=20';
            if (status && status !== 'all') url += '&status=' + encodeURIComponent(status);

            try {
                const r = await window.api(url);
                if (r && r.ok) ordersData = await r.json();
            } catch(e) {
                ordersData = emptyPage(); apiError('Buyurtmalarni yuklab bo\'lmadi');
            }

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Buyurtmalar</h1>' +
                    '<p class="page-subtitle">Buyurtmalarni boshqarish (' + ordersData.total + ' ta)</p>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-header">' +
                        '<div class="filters-bar" style="margin-bottom:0; width:100%;">' +
                            '<select class="filter-select" id="orderStatusFilter">' +
                                '<option value="all"' + (status === 'all' || !status ? ' selected' : '') + '>Barcha holatlar</option>' +
                                '<option value="pending"' + (status === 'pending' ? ' selected' : '') + '>Kutilmoqda</option>' +
                                '<option value="confirmed"' + (status === 'confirmed' ? ' selected' : '') + '>Tasdiqlangan</option>' +
                                '<option value="in_progress"' + (status === 'in_progress' ? ' selected' : '') + '>Jarayonda</option>' +
                                '<option value="completed"' + (status === 'completed' ? ' selected' : '') + '>Tugallangan</option>' +
                                '<option value="cancelled"' + (status === 'cancelled' ? ' selected' : '') + '>Bekor qilingan</option>' +
                            '</select>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card-body no-padding">' +
                        '<div class="table-container">' +
                            '<table class="data-table">' +
                                '<thead><tr><th>ID</th><th>Xizmat</th><th>Foydalanuvchi</th><th>Provider</th><th>Narx</th><th>Holat</th><th>Sana</th><th>Amallar</th></tr></thead>' +
                                '<tbody>' + renderOrderRowsApi(ordersData.items) + '</tbody>' +
                            '</table>' +
                        '</div>' +
                    '</div>' +
                    '<div class="pagination">' +
                        '<span class="pagination-info">' + ordersData.total + ' ta buyurtma</span>' +
                        '<div class="pagination-buttons">' + renderPagination(ordersData.pages, ordersPage, 'renderOrders') + '</div>' +
                    '</div>' +
                '</div>';

            document.getElementById('orderStatusFilter').addEventListener('change', function() { renderOrders(1); });
        }

        function renderOrderRowsApi(items) {
            if (!items || items.length === 0) return '<tr><td colspan="8" style="text-align:center;color:var(--gray-400);padding:40px;">Buyurtmalar topilmadi</td></tr>';
            return items.map(function(o) {
                return '<tr>' +
                    '<td>#' + o.id + '</td>' +
                    '<td>' + (o.service_name || o.service || '—') + '</td>' +
                    '<td>' + (o.user_name || '—') + '</td>' +
                    '<td>' + (o.provider_name || '—') + '</td>' +
                    '<td>' + window.formatMoney(o.price || 0) + '</td>' +
                    '<td>' + window.statusBadge(o.status || 'pending') + '</td>' +
                    '<td>' + (o.created_at ? window.formatDate(o.created_at) : '—') + '</td>' +
                    '<td><div class="action-group">' +
                        '<select class="filter-select" style="padding:4px 24px 4px 8px;font-size:12px;" onchange="changeOrderStatus(' + o.id + ', this.value)">' +
                            '<option value="">Status</option>' +
                            '<option value="confirmed">Tasdiqlash</option>' +
                            '<option value="in_progress">Jarayon</option>' +
                            '<option value="completed">Yakunlash</option>' +
                            '<option value="cancelled">Bekor</option>' +
                        '</select>' +
                    '</div></td>' +
                '</tr>';
            }).join('');
        }

        async function changeOrderStatus(id, status) {
            if (!status) return;
            try {
                await window.api(window.API_BASE + '/orders/' + id + '/status', { method: 'PATCH', body: JSON.stringify({ status: status }) });
                window.showToast('Buyurtma statusi yangilandi');
                renderOrders(ordersPage);
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        

// Exports for ES6 modules
export { changeOrderStatus, renderOrders, renderOrderRowsApi };
// Expose to window for inline onclick handlers
window.changeOrderStatus = changeOrderStatus;
window.renderOrders = renderOrders;
window.renderOrderRowsApi = renderOrderRowsApi;
