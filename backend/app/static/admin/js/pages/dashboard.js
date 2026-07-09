import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: DASHBOARD =====
        async function renderDashboard() {
            // Fetch real stats from API
            let s = { orders_total: 0, users: 0, providers: 0, categories: 0, revenue_today: 0, revenue_month: 0, avg_rating: 0, orders_by_status: {} };
            let providers = [];
            try {
                const r = await window.api(window.API_BASE + '/stats');
                if (r && r.ok) s = await r.json();
                const providersRes = await window.api(window.API_BASE + '/finance/providers');
                if (providersRes && providersRes.ok) providers = await providersRes.json();
            } catch(e) { console.warn('Stats load error', e); apiError('Statistikani yuklab bo\'lmadi'); }

            var providerOptions = providers.map(p => '<option value="' + p.id + '">' + window.escapeHtml(p.name) + ' (Balans: ' + window.formatMoney(p.balance) + ')</option>').join('');

            var recentOrders = [];
            var topProviders = [];
            try {
                const or = await window.api(window.API_BASE + '/orders?page=1&per_page=5');
                if (or && or.ok) {
                    var od = await or.json();
                    recentOrders = (od.items || []).map(function(o) {
                        return { id: o.id, service: o.service_name || o.service, price: o.price, status: o.status };
                    });
                }
                const pr = await window.api(window.API_BASE + '/providers?page=1&per_page=5');
                if (pr && pr.ok) {
                    var pd = await pr.json();
                    topProviders = (pd.items || []).sort(function(a, b) { return (b.rating || 0) - (a.rating || 0); }).slice(0, 5);
                }
            } catch(e) { console.warn('Dashboard lists fallback', e); }

            var weatherHtml = '<div class="widget-desc">Yuklanmoqda...</div>';
            try {
                const wr = await window.api(window.API_BASE + '/utilities/weather?city=Tashkent');
                if (wr && wr.ok) {
                    var w = await wr.json();
                    weatherHtml = '<div class="widget-value">' + w.temperature_celsius + '°C, ' + w.condition + '</div>' +
                                  '<div class="widget-desc">' + w.city + ' (Namlik: ' + w.humidity + '%)</div>';
                }
            } catch(e) {}

            var currencyHtml = '<div class="widget-desc">Yuklanmoqda...</div>';
            try {
                const cr = await window.api(window.API_BASE + '/utilities/currency');
                if (cr && cr.ok) {
                    var c = await cr.json();
                    if (c.rates && c.rates.length > 0) {
                        var usd = c.rates.find(r => r.Ccy === 'USD');
                        var rub = c.rates.find(r => r.Ccy === 'RUB');
                        currencyHtml = '<div class="widget-value">1 USD = ' + (usd ? usd.Rate : '--') + ' UZS</div>' +
                                       '<div class="widget-desc">1 RUB = ' + (rub ? rub.Rate : '--') + ' UZS (' + (usd ? usd.Date : '') + ')</div>';
                    }
                }
            } catch(e) {}

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Bosh sahifa</h1>' +
                    '<p class="page-subtitle">Platforma statistikasi va tahlillar</p>' +
                '</div>' +

                '<div class="stats-grid">' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Jami buyurtmalar</span>' +
                            '<div class="stat-card-icon purple">&#128230;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + new Intl.NumberFormat('uz-UZ').format(s.orders_total) + '</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Foydalanuvchilar</span>' +
                            '<div class="stat-card-icon blue">&#128101;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + new Intl.NumberFormat('uz-UZ').format(s.users) + '</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Soha egalari</span>' +
                            '<div class="stat-card-icon green">&#127970;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + new Intl.NumberFormat('uz-UZ').format(s.providers) + '</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Bugungi tushum</span>' +
                            '<div class="stat-card-icon yellow">&#128176;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + window.formatMoney(s.revenue_today) + '</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Oylik tushum</span>' +
                            '<div class="stat-card-icon green">&#128200;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + window.formatMoney(s.revenue_month) + '</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">O\'rtacha reyting</span>' +
                            '<div class="stat-card-icon orange">&#11088;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + s.avg_rating + '</div>' +
                    '</div>' +
                '</div>' +
                '<div class="charts-grid">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Tushum dinamikasi (30 kun)</h3></div>' +
                        '<div class="card-body"><div class="chart-container"><canvas id="revenueChart"></canvas></div></div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Buyurtmalar kategoriya bo\'yicha</h3></div>' +
                        '<div class="card-body"><div class="chart-container"><canvas id="categoryChart"></canvas></div></div>' +
                    '</div>' +
                '</div>' +
                '<div style="display:grid; grid-template-columns: 1fr 1fr; gap: 24px;">' +
                    '<div class="card">' +
                        '<div class="card-header">' +
                            '<h3 class="card-title">So\'nggi buyurtmalar</h3>' +
                            '<button class="btn btn-sm btn-secondary" onclick="navigateTo(\'orders\')">Barchasi &#8594;</button>' +
                        '</div>' +
                        '<div class="card-body no-padding">' +
                            '<div class="table-container">' +
                                '<table class="data-table">' +
                                    '<thead><tr><th>ID</th><th>Xizmat</th><th>Narx</th><th>Holat</th></tr></thead>' +
                                    '<tbody>' +
                                        recentOrders.map(function(o) {
                            return '<tr><td>#' + o.id + '</td><td>' + window.escapeHtml(o.service) + '</td><td>' + window.formatMoney(o.price) + '</td><td>' + window.statusBadge(o.status) + '</td></tr>';
                        }).join('') +
                                    '</tbody>' +
                                '</table>' +
                            '</div>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Top soha egalari</h3></div>' +
                        '<div class="card-body no-padding">' +
                            '<div class="table-container">' +
                                '<table class="data-table">' +
                                    '<thead><tr><th>#</th><th>Nomi</th><th>Reyting</th><th>Buyurtmalar</th></tr></thead>' +
                                    '<tbody>' +
                                        topProviders.map(function(p, i) {
                            return '<tr><td>' + (i + 1) + '</td><td><div class="table-user"><div class="table-avatar">' + window.getInitials(p.name) + '</div><span>' + window.escapeHtml(p.name) + '</span></div></td><td>' + window.renderStars(Math.round(p.rating || 0)) + ' ' + (p.rating || 0) + '</td><td>' + (p.review_count || p.orders || 0) + '</td></tr>';
                        }).join('') +
                                    '</tbody>' +
                                '</table>' +
                            '</div>' +
                        '</div>' +
                    '</div>' +
                '</div>';
        }

        var revenueChartInstance = null;
        var categoryChartInstance = null;
        var chartDataCache = null;

        async function initDashboardCharts() {
            var revenueCtx = document.getElementById('revenueChart');
            if (!revenueCtx) return;
            if (revenueChartInstance) revenueChartInstance.destroy();

            var labels = [];
            var data = [];
            var catLabels = [];
            var catData = [];

            try {
                await loadCategoriesCache();
                catLabels = window.categoriesCache.map(function(c) { return c.title_uz; });
                catData = window.categoriesCache.map(function() { return 0; });
                const r = await window.api(window.API_BASE + '/chart-data?days=30');
                if (r && r.ok) {
                    chartDataCache = await r.json();
                    labels = chartDataCache.revenue.map(function(p) {
                        var d = new Date(p.label);
                        return d.toLocaleDateString('uz-UZ', { day: 'numeric', month: 'short' });
                    });
                    data = chartDataCache.revenue.map(function(p) { return p.value; });
                    if (chartDataCache.top_categories && chartDataCache.top_categories.length) {
                        catLabels = chartDataCache.top_categories.map(function(c) { return c.label; });
                        catData = chartDataCache.top_categories.map(function(c) { return c.value; });
                    }
                }
            } catch(e) { console.warn('Chart data error', e); }

            if (labels.length === 0) {
                labels = ['—'];
                data = [0];
            }
            if (catLabels.length === 0) {
                catLabels = ['—'];
                catData = [0];
            }

            revenueChartInstance = new Chart(revenueCtx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Tushum (so\'m)',
                        data: data,
                        borderColor: '#6366F1',
                        backgroundColor: 'rgba(99, 102, 241, 0.1)',
                        fill: true,
                        tension: 0.4,
                        borderWidth: 2,
                        pointRadius: 0,
                        pointHoverRadius: 5,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        x: { grid: { display: false }, ticks: { maxTicksLimit: 10, font: { size: 11 } } },
                        y: { grid: { color: '#F3F4F6' }, ticks: { font: { size: 11 }, callback: function(v) { return (v / 1000) + 'k'; } } }
                    }
                }
            });

            var catCtx = document.getElementById('categoryChart');
            if (!catCtx) return;
            if (categoryChartInstance) categoryChartInstance.destroy();

            categoryChartInstance = new Chart(catCtx, {
                type: 'bar',
                data: {
                    labels: catLabels,
                    datasets: [{
                        label: 'Buyurtmalar',
                        data: catData,
                        backgroundColor: ['#F59E0B', '#3B82F6', '#10B981', '#EC4899', '#8B5CF6'],
                        borderRadius: 6,
                        borderSkipped: false,
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        x: { grid: { display: false }, ticks: { font: { size: 10 } } },
                        y: { grid: { color: '#F3F4F6' }, ticks: { font: { size: 11 } } }
                    }
                }
            });
        }

        

// Exports for ES6 modules
export { initDashboardCharts, renderDashboard };
// Expose to window for inline onclick handlers
window.initDashboardCharts = initDashboardCharts;
window.renderDashboard = renderDashboard;
