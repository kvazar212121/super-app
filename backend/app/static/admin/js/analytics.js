import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from './api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from './ui.js';
import { navigateTo, renderPage } from './router.js';

// ===== USER ANALYTICS =====
        async function renderUserAnalytics() {
            mainContent.innerHTML = '<div class="page-header"><h1 class="page-title">Foydalanuvchi odatlari</h1></div><div class="card"><div class="card-body">Yuklanmoqda...</div></div>';
            
            try {
                const r = await window.api(window.API_BASE + '/analytics/user-insights');
                if (!r || !r.ok) throw new Error();
                const data = await r.json();

                let html = '<div class="page-header">' +
                    '<h1 class="page-title">Foydalanuvchi odatlari va statistikasi</h1>' +
                    '<p class="page-subtitle">Umumiy anonimlashtirilgan xatti-harakatlar tahlili</p>' +
                    '</div>';
                
                // Top cards
                html += '<div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap:24px; margin-bottom:24px;">' +
                    '<div class="stat-card"><div class="stat-title">O\'rtacha bozorlik xarajati</div><div class="stat-value text-success">' + window.formatMoney(data.shopping.avg_price) + '</div><div class="stat-desc">' + data.shopping.total_lists + ' ta ro\'yxat asosida</div></div>' +
                    '<div class="stat-card"><div class="stat-title">Jami rejalar (Plans & Todos)</div><div class="stat-value">' + (data.planning.total_plans + data.planning.total_todos) + '</div><div class="stat-desc">Bajarilganlar: ' + (data.planning.completed_plans + data.planning.completed_todos) + '</div></div>' +
                    '</div>';

                html += '<div style="display:grid; grid-template-columns: 1fr 1fr; gap:24px;">';

                // Popular Shopping Items
                html += '<div class="card">' +
                    '<div class="card-header"><h3 class="card-title">Top-10 eng ommabop mahsulotlar</h3></div>' +
                    '<div class="card-body no-padding"><div class="table-container"><table class="data-table">' +
                    '<thead><tr><th>#</th><th>Mahsulot nomi</th><th>Qo\'shilgan soni</th></tr></thead><tbody>';
                if(data.shopping.top_items.length === 0) {
                    html += '<tr><td colspan="3" style="text-align:center;padding:24px;color:var(--gray-400);">Ma\'lumot yo\'q</td></tr>';
                } else {
                    data.shopping.top_items.forEach((item, index) => {
                        html += '<tr><td>' + (index + 1) + '</td><td><b>' + item.name + '</b></td><td>' + item.count + ' marta</td></tr>';
                    });
                }
                html += '</tbody></table></div></div></div>';

                // Popular Hours
                let maxHourCount = 0;
                data.planning.popular_hours.forEach(h => { if(h.count > maxHourCount) maxHourCount = h.count; });
                
                html += '<div class="card">' +
                    '<div class="card-header"><h3 class="card-title">Reja tuzish uchun eng faol soatlar</h3></div>' +
                    '<div class="card-body" style="padding: 24px;">';
                
                if (maxHourCount === 0) {
                    html += '<div style="text-align:center;color:var(--gray-400);">Ma\'lumot yo\'q</div>';
                } else {
                    data.planning.popular_hours.forEach(h => {
                        if(h.count > 0) {
                            let w = Math.max(5, (h.count / maxHourCount) * 100);
                            html += '<div style="margin-bottom:12px; display:flex; align-items:center;">' +
                                '<div style="width:50px; font-size:12px; color:var(--gray-500);">' + h.hour + '</div>' +
                                '<div style="flex:1; background:var(--gray-100); border-radius:4px; height:24px; overflow:hidden;">' +
                                    '<div style="width:' + w + '%; background:var(--primary); height:100%; display:flex; align-items:center; padding-left:8px; color:white; font-size:11px; font-weight:bold;">' + h.count + ' ta</div>' +
                                '</div>' +
                                '</div>';
                        }
                    });
                }
                html += '</div></div>';

                html += '</div>'; // End grid

                mainContent.innerHTML = html;
            } catch(e) { 
                apiError('Statistikani yuklashda xatolik yuz berdi');
                mainContent.innerHTML = '<div class="page-header"><h1 class="page-title">Foydalanuvchi odatlari</h1></div><div class="card"><div class="card-body" style="color:var(--danger)">Yuklab bo\'lmadi</div></div>';
            }
        }
        
        

// Exports for ES6 modules
export { renderUserAnalytics };
// Expose to window for inline onclick handlers
window.renderUserAnalytics = renderUserAnalytics;
