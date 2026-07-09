import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from './api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from './ui.js';
import { navigateTo, renderPage } from './router.js';

// ===== USER DATA =====
        async function renderUserDataTodos() {
            mainContent.innerHTML = '<div class="page-header"><h1 class="page-title">Kundalik rejalar</h1></div><div class="card"><div class="card-body">Yuklanmoqda...</div></div>';
            var html = '<div class="page-header"><h1 class="page-title">Kundalik rejalar (Todos)</h1><p class="page-subtitle">Platformadagi barcha foydalanuvchi rejalari</p></div>';
            html += '<div class="card"><div class="table-container"><table class="table"><thead><tr><th>ID</th><th>Foydalanuvchi</th><th>Sarlavha</th><th>Holati</th><th>Sana</th></tr></thead><tbody id="todosTableBody"></tbody></table></div></div>';
            mainContent.innerHTML = html;
            try {
                const res = await window.api(window.API_BASE + '/user-data/todos');
                if (res.ok) {
                    var data = await res.json();
                    var tbody = document.getElementById('todosTableBody');
                    if (data.length === 0) tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:20px;">Ma\'lumot yo\'q</td></tr>';
                    else {
                        tbody.innerHTML = data.map(function(t) {
                            return '<tr>' +
                                '<td>#' + t.id + '</td>' +
                                '<td><div style="font-weight:600;">' + window.escapeHtml(t.user_name) + '</div></td>' +
                                '<td>' + window.escapeHtml(t.title || '-') + '</td>' +
                                '<td><span class="status-badge ' + (t.is_completed ? 'status-success' : 'status-warning') + '">' + (t.is_completed ? 'Bajarilgan' : 'Bajarilmagan') + '</span></td>' +
                                '<td>' + (t.created_at ? t.created_at.substring(0,10) : '-') + '</td>' +
                            '</tr>';
                        }).join('');
                    }
                }
            } catch(e) { console.error(e); }
        }

        async function renderUserDataShopping() {
            mainContent.innerHTML = '<div class="page-header"><h1 class="page-title">Xaridlar (Bozorlik)</h1></div><div class="card"><div class="card-body">Yuklanmoqda...</div></div>';
            var html = '<div class="page-header"><h1 class="page-title">Xaridlar ro\'yxati</h1><p class="page-subtitle">Foydalanuvchilar tuzgan bozorlik ro\'yxatlari</p></div>';
            html += '<div class="card"><div class="table-container"><table class="table"><thead><tr><th>ID</th><th>Foydalanuvchi</th><th>Sarlavha</th><th>Mahsulotlar</th><th>Taxminiy narx</th><th>Asl narx</th><th>Holati</th></tr></thead><tbody id="shoppingTableBody"></tbody></table></div></div>';
            mainContent.innerHTML = html;
            try {
                const res = await window.api(window.API_BASE + '/user-data/shopping');
                if (res.ok) {
                    var data = await res.json();
                    var tbody = document.getElementById('shoppingTableBody');
                    if (data.length === 0) tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:20px;">Ma\'lumot yo\'q</td></tr>';
                    else {
                        tbody.innerHTML = data.map(function(s) {
                            return '<tr>' +
                                '<td>#' + s.id + '</td>' +
                                '<td><div style="font-weight:600;">' + window.escapeHtml(s.user_name) + '</div></td>' +
                                '<td>' + window.escapeHtml(s.name || '-') + '</td>' +
                                '<td>' + s.item_count + ' ta</td>' +
                                '<td>' + window.formatMoney(s.total_estimated_price) + '</td>' +
                                '<td>' + window.formatMoney(s.total_actual_price) + '</td>' +
                                '<td><span class="status-badge ' + (s.is_completed ? 'status-success' : 'status-warning') + '">' + (s.is_completed ? 'Tugallangan' : 'Jarayonda') + '</span></td>' +
                            '</tr>';
                        }).join('');
                    }
                }
            } catch(e) { console.error(e); }
        }

        async function renderUserDataFinance() {
            mainContent.innerHTML = '<div class="page-header"><h1 class="page-title">Moliya daftari</h1></div><div class="card"><div class="card-body">Yuklanmoqda...</div></div>';
            var html = '<div class="page-header"><h1 class="page-title">Moliya yozuvlari</h1><p class="page-subtitle">Foydalanuvchilar kiritgan daromad va xarajatlar</p></div>';
            html += '<div class="card"><div class="table-container"><table class="table"><thead><tr><th>ID</th><th>Foydalanuvchi</th><th>Turi</th><th>Kategoriya</th><th>Summa</th><th>Izoh</th><th>Sana</th></tr></thead><tbody id="financeTableBody"></tbody></table></div></div>';
            mainContent.innerHTML = html;
            try {
                const res = await window.api(window.API_BASE + '/user-data/finance');
                if (res.ok) {
                    var data = await res.json();
                    var tbody = document.getElementById('financeTableBody');
                    if (data.length === 0) tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:20px;">Ma\'lumot yo\'q</td></tr>';
                    else {
                        tbody.innerHTML = data.map(function(f) {
                            return '<tr>' +
                                '<td>#' + f.id + '</td>' +
                                '<td><div style="font-weight:600;">' + window.escapeHtml(f.user_name) + '</div></td>' +
                                '<td><span class="status-badge ' + (f.type === 'income' ? 'status-success' : 'status-danger') + '">' + (f.type === 'income' ? 'Daromad' : 'Xarajat') + '</span></td>' +
                                '<td>' + window.escapeHtml(f.category || '-') + '</td>' +
                                '<td style="font-weight:bold;color:' + (f.type === 'income' ? 'var(--success)' : 'var(--danger)') + ';">' + window.formatMoney(f.amount) + '</td>' +
                                '<td>' + window.escapeHtml(f.note || '-') + '</td>' +
                                '<td>' + (f.date ? f.date.substring(0,10) : '-') + '</td>' +
                            '</tr>';
                        }).join('');
                    }
                }
            } catch(e) { console.error(e); }
        }

        async function renderUserDataPlans() {
            mainContent.innerHTML = '<div class="page-header"><h1 class="page-title">Taqvim rejalari</h1></div><div class="card"><div class="card-body">Yuklanmoqda...</div></div>';
            var html = '<div class="page-header"><h1 class="page-title">Taqvim rejalari</h1><p class="page-subtitle">Foydalanuvchilar kiritgan muddatli rejalar</p></div>';
            html += '<div class="card"><div class="table-container"><table class="table"><thead><tr><th>ID</th><th>Foydalanuvchi</th><th>Sarlavha</th><th>Izoh</th><th>Sana/Vaqt</th><th>Holati</th></tr></thead><tbody id="plansTableBody"></tbody></table></div></div>';
            mainContent.innerHTML = html;
            try {
                const res = await window.api(window.API_BASE + '/user-data/plans');
                if (res.ok) {
                    var data = await res.json();
                    var tbody = document.getElementById('plansTableBody');
                    if (data.length === 0) tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:20px;">Ma\'lumot yo\'q</td></tr>';
                    else {
                        tbody.innerHTML = data.map(function(p) {
                            return '<tr>' +
                                '<td>#' + p.id + '</td>' +
                                '<td><div style="font-weight:600;">' + window.escapeHtml(p.user_name) + '</div></td>' +
                                '<td>' + window.escapeHtml(p.title || '-') + '</td>' +
                                '<td>' + window.escapeHtml(p.description || '-') + '</td>' +
                                '<td>' + (p.date ? p.date.substring(0,10) : '') + ' ' + (p.time ? p.time.substring(0,5) : '') + '</td>' +
                                '<td><span class="status-badge ' + (p.is_completed ? 'status-success' : 'status-warning') + '">' + (p.is_completed ? 'Bajarilgan' : 'Bajarilmagan') + '</span></td>' +
                            '</tr>';
                        }).join('');
                    }
                }
            } catch(e) { console.error(e); }
        }

        

// Exports for ES6 modules
export { renderUserDataPlans, renderUserDataShopping, renderUserDataTodos, renderUserDataFinance };
// Expose to window for inline onclick handlers
window.renderUserDataPlans = renderUserDataPlans;
window.renderUserDataShopping = renderUserDataShopping;
window.renderUserDataTodos = renderUserDataTodos;
window.renderUserDataFinance = renderUserDataFinance;
