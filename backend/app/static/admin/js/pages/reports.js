import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: REPORTS =====
        var reportChartInstance = null;
        var reportBarChartInstance = null;

        async function renderReports() {
            var today = new Date();
            var firstDay = new Date(today.getFullYear(), today.getMonth(), 1);
            var fmt = function(d) { return d.toISOString().split('T')[0]; };

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Hisobotlar</h1>' +
                    '<p class="page-subtitle">Haqiqiy moliyaviy siyosat asosida interaktiv tahlil</p>' +
                '</div>' +

                '<div class="card" style="margin-bottom:20px;"><div class="card-body">' +
                    '<h3 class="settings-section-title" style="margin-bottom:10px;">📥 Ma\'lumot eksporti (CSV)</h3>' +
                    '<div style="display:flex;gap:10px;flex-wrap:wrap;">' +
                        '<button class="btn btn-primary" onclick="downloadCsv(\'/reports/export/orders.csv\',\'buyurtmalar.csv\')">⬇️ Buyurtmalar</button>' +
                        '<button class="btn btn-primary" onclick="downloadCsv(\'/reports/export/users.csv\',\'foydalanuvchilar.csv\')">⬇️ Foydalanuvchilar</button>' +
                        '<button class="btn btn-primary" onclick="downloadCsv(\'/reports/export/finance.csv\',\'moliya.csv\')">⬇️ Moliya</button>' +
                    '</div>' +
                '</div></div>' +

                '<div class="card" style="margin-bottom:20px;">' +
                    '<div class="card-body" style="display:flex;align-items:center;gap:12px;flex-wrap:wrap;">' +
                        '<div class="period-selector" id="reportPeriodSelector">' +
                            '<button class="period-btn" data-period="daily" onclick="selectReportPeriod(this)">Kunlik</button>' +
                            '<button class="period-btn" data-period="weekly" onclick="selectReportPeriod(this)">Haftalik</button>' +
                            '<button class="period-btn active" data-period="monthly" onclick="selectReportPeriod(this)">Oylik</button>' +
                            '<button class="period-btn" data-period="yearly" onclick="selectReportPeriod(this)">Yillik</button>' +
                        '</div>' +
                        '<input type="date" class="form-input" id="reportDateFrom" value="' + fmt(firstDay) + '" style="width:auto;">' +
                        '<span style="color:#aaa;">—</span>' +
                        '<input type="date" class="form-input" id="reportDateTo" value="' + fmt(today) + '" style="width:auto;">' +
                        '<button class="btn btn-primary" onclick="generateReport()">🔍 Hisobot</button>' +
                        '<button class="btn btn-secondary" onclick="exportCSV()">📥 CSV</button>' +
                        '<div id="reportLoading" style="display:none;font-size:13px;color:#888;">⏳ Yuklanmoqda...</div>' +
                    '</div>' +
                '</div>' +

                // Financial stats row
                '<div class="stats-grid" id="reportStats" style="grid-template-columns:repeat(4,1fr);">' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Lead Fee (Komissiya)</span><div class="stat-card-icon green">💰</div></div><div class="stat-card-value" id="rLeadFee">0</div><span class="stat-card-change up">Soha egalariadan yechilgan</span></div>' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Premium Tushum</span><div class="stat-card-icon orange">⭐</div></div><div class="stat-card-value" id="rPremium">0</div><span class="stat-card-change up">Obunalardan</span></div>' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Sof Foyda</span><div class="stat-card-icon purple">📈</div></div><div class="stat-card-value" id="rNetProfit">0</div><span class="stat-card-change up">LeadFee + Premium - Xarajat</span></div>' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Platforma Xarajati</span><div class="stat-card-icon red">💸</div></div><div class="stat-card-value" id="rWithdraw">0</div><span class="stat-card-change down">Yechib olingan</span></div>' +
                '</div>' +

                // Orders stats row
                '<div class="stats-grid" id="reportOrderStats" style="grid-template-columns:repeat(5,1fr);margin-top:16px;">' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Jami Buyurtmalar</span><div class="stat-card-icon blue">📦</div></div><div class="stat-card-value" id="rTotal">0</div></div>' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Tugallangan</span><div class="stat-card-icon green">✅</div></div><div class="stat-card-value" id="rCompleted">0</div></div>' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Bekor qilingan</span><div class="stat-card-icon red">❌</div></div><div class="stat-card-value" id="rCancelled">0</div></div>' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Yangi Foydalanuvchilar</span><div class="stat-card-icon purple">👥</div></div><div class="stat-card-value" id="rNewUsers">0</div></div>' +
                    '<div class="stat-card"><div class="stat-card-header"><span class="stat-card-label">Yangi Soha Egalari</span><div class="stat-card-icon teal">🏪</div></div><div class="stat-card-value" id="rNewProviders">0</div></div>' +
                '</div>' +

                // Charts row
                '<div style="display:grid;grid-template-columns:2fr 1fr;gap:20px;margin-top:20px;">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Lead Fee Dinamikasi</h3></div>' +
                        '<div class="card-body"><div class="chart-container"><canvas id="reportChart"></canvas></div></div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Sohalar bo\'yicha</h3></div>' +
                        '<div class="card-body"><div class="chart-container"><canvas id="reportBarChart"></canvas></div></div>' +
                    '</div>' +
                '</div>' +

                // Bottom tables
                '<div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;margin-top:20px;">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Sohalar bo\'yicha batafsil</h3></div>' +
                        '<div class="card-body no-padding"><table class="data-table" id="reportCatTable">' +
                            '<thead><tr><th>Soha</th><th>Buyurtmalar</th><th>Lead Fee</th></tr></thead>' +
                            '<tbody id="reportCatBody"><tr><td colspan="3" style="text-align:center;color:#aaa;">Yuklanmoqda...</td></tr></tbody>' +
                        '</table></div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Faol Soha Egalari (Top 8)</h3></div>' +
                        '<div class="card-body no-padding"><table class="data-table" id="reportProvTable">' +
                            '<thead><tr><th>Usta</th><th>Buyurtmalar</th><th>Lead Fee</th><th>Balans</th></tr></thead>' +
                            '<tbody id="reportProvBody"><tr><td colspan="4" style="text-align:center;color:#aaa;">Yuklanmoqda...</td></tr></tbody>' +
                        '</table></div>' +
                    '</div>' +
                '</div>';

            await generateReport();
        }

        function selectReportPeriod(el) {
            document.querySelectorAll('#reportPeriodSelector .period-btn').forEach(function(b) { b.classList.remove('active'); });
            el.classList.add('active');
            // Auto-set date range
            var today = new Date();
            var from = new Date();
            var p = el.dataset.period;
            if (p === 'daily') { from = today; }
            else if (p === 'weekly') { from = new Date(today); from.setDate(today.getDate() - 7); }
            else if (p === 'monthly') { from = new Date(today.getFullYear(), today.getMonth(), 1); }
            else if (p === 'yearly') { from = new Date(today.getFullYear(), 0, 1); }
            var fmt = function(d) { return d.toISOString().split('T')[0]; };
            document.getElementById('reportDateFrom').value = fmt(from);
            document.getElementById('reportDateTo').value = fmt(today);
            generateReport();
        }

        async function generateReport() {
            var loading = document.getElementById('reportLoading');
            if (loading) loading.style.display = 'block';

            var periodEl = document.querySelector('#reportPeriodSelector .period-btn.active');
            var period = periodEl ? periodEl.dataset.period : 'monthly';
            var df = document.getElementById('reportDateFrom') ? document.getElementById('reportDateFrom').value : '';
            var dt = document.getElementById('reportDateTo') ? document.getElementById('reportDateTo').value : '';
            var url = window.API_BASE + '/reports?period=' + period;
            if (df) url += '&date_from=' + df;
            if (dt) url += '&date_to=' + dt;

            try {
                const r = await window.api(url);
                if (!r || !r.ok) { window.showToast('Hisobot yuklanmadi', 'error'); return; }
                var rep = await r.json();

                // Financial stats
                document.getElementById('rLeadFee').textContent = window.formatMoney(rep.total_lead_fee || 0);
                document.getElementById('rPremium').textContent = window.formatMoney(rep.total_premium || 0);
                document.getElementById('rNetProfit').textContent = window.formatMoney(rep.net_profit || 0);
                document.getElementById('rWithdraw').textContent = window.formatMoney(rep.total_admin_withdraw || 0);

                // Order stats
                document.getElementById('rTotal').textContent = (rep.total_orders || 0).toLocaleString();
                document.getElementById('rCompleted').textContent = (rep.completed_orders || 0).toLocaleString();
                document.getElementById('rCancelled').textContent = (rep.cancelled_orders || 0).toLocaleString();
                document.getElementById('rNewUsers').textContent = (rep.new_users || 0).toLocaleString();
                document.getElementById('rNewProviders').textContent = (rep.new_providers || 0).toLocaleString();

                // Color net profit
                var npEl = document.getElementById('rNetProfit');
                npEl.style.color = (rep.net_profit || 0) >= 0 ? 'var(--green-600)' : 'var(--red-600)';

                // Charts
                initReportChart(rep.chart_data || []);
                initBarChart(rep.category_stats || []);

                // Category table
                var catBody = document.getElementById('reportCatBody');
                if (catBody) {
                    catBody.innerHTML = (rep.category_stats || []).length > 0
                        ? rep.category_stats.map(function(c) {
                            return '<tr>' +
                                '<td><b>' + c.name + '</b></td>' +
                                '<td>' + c.orders + '</td>' +
                                '<td style="color:var(--green-600);font-weight:600;">' + window.formatMoney(c.lead_fee_total) + '</td>' +
                            '</tr>';
                        }).join('')
                        : '<tr><td colspan="3" style="text-align:center;color:#aaa;">Ma\'lumot yo\'q</td></tr>';
                }

                // Provider table
                var provBody = document.getElementById('reportProvBody');
                if (provBody) {
                    provBody.innerHTML = (rep.top_providers || []).length > 0
                        ? rep.top_providers.map(function(p) {
                            var balColor = p.balance < 0 ? 'var(--red-600)' : p.balance < 10000 ? 'var(--orange-500)' : 'var(--green-600)';
                            return '<tr>' +
                                '<td><b>' + p.name + '</b></td>' +
                                '<td>' + p.orders + '</td>' +
                                '<td style="color:var(--green-600);">' + window.formatMoney(p.lead_fee_total) + '</td>' +
                                '<td style="color:' + balColor + ';font-weight:600;">' + window.formatMoney(p.balance) + '</td>' +
                            '</tr>';
                        }).join('')
                        : '<tr><td colspan="4" style="text-align:center;color:#aaa;">Ma\'lumot yo\'q</td></tr>';
                }

                window.showToast('Hisobot yangilandi ✅');
            } catch(e) {
                window.showToast('Xatolik: ' + e.message, 'error');
            } finally {
                if (loading) loading.style.display = 'none';
            }
        }

        function initReportChart(chartData) {
            var ctx = document.getElementById('reportChart');
            if (!ctx) return;
            if (reportChartInstance) reportChartInstance.destroy();

            var labels = chartData.map(function(p) { return p.label; });
            var fees = chartData.map(function(p) { return p.lead_fee; });
            var orders = chartData.map(function(p) { return p.orders; });

            reportChartInstance = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [
                        {
                            label: 'Lead Fee (so\'m)',
                            data: fees,
                            borderColor: '#6366f1',
                            backgroundColor: 'rgba(99,102,241,0.10)',
                            fill: true,
                            tension: 0.4,
                            borderWidth: 2.5,
                            pointRadius: 4,
                            pointBackgroundColor: '#6366f1',
                            yAxisID: 'y',
                        },
                        {
                            label: 'Buyurtmalar',
                            data: orders,
                            borderColor: '#10b981',
                            backgroundColor: 'rgba(16,185,129,0.07)',
                            fill: false,
                            tension: 0.4,
                            borderWidth: 2,
                            pointRadius: 3,
                            pointBackgroundColor: '#10b981',
                            borderDash: [5, 3],
                            yAxisID: 'y2',
                        }
                    ]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    interaction: { mode: 'index', intersect: false },
                    plugins: {
                        legend: { display: true, position: 'top', labels: { font: { size: 11 } } },
                        tooltip: {
                            callbacks: {
                                label: function(ctx) {
                                    if (ctx.datasetIndex === 0) return ' Lead Fee: ' + window.formatMoney(ctx.raw);
                                    return ' Buyurtmalar: ' + ctx.raw;
                                }
                            }
                        }
                    },
                    scales: {
                        x: { grid: { display: false }, ticks: { font: { size: 10 } } },
                        y: {
                            position: 'left',
                            grid: { color: '#F3F4F6' },
                            ticks: { font: { size: 10 }, callback: function(v) { return (v >= 1000 ? (v/1000).toFixed(0) + 'k' : v) + ' so\'m'; } }
                        },
                        y2: {
                            position: 'right',
                            grid: { display: false },
                            ticks: { font: { size: 10 }, stepSize: 1 }
                        }
                    }
                }
            });
        }

        function initBarChart(catStats) {
            var ctx = document.getElementById('reportBarChart');
            if (!ctx) return;
            if (reportBarChartInstance) reportBarChartInstance.destroy();

            var labels = catStats.map(function(c) { return c.name; });
            var fees = catStats.map(function(c) { return c.lead_fee_total; });
            var colors = ['#6366f1','#10b981','#f59e0b','#ef4444','#8b5cf6','#06b6d4','#ec4899','#84cc16'];

            reportBarChartInstance = new Chart(ctx, {
                type: 'doughnut',
                data: {
                    labels: labels,
                    datasets: [{
                        data: fees.length > 0 ? fees : [1],
                        backgroundColor: labels.length > 0 ? colors.slice(0, labels.length) : ['#e5e7eb'],
                        borderWidth: 2,
                        borderColor: '#fff',
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: {
                        legend: { position: 'bottom', labels: { font: { size: 10 }, boxWidth: 10 } },
                        tooltip: {
                            callbacks: {
                                label: function(ctx) {
                                    if (fees.length === 0) return ' Ma\'lumot yo\'q';
                                    return ' ' + ctx.label + ': ' + window.formatMoney(ctx.raw);
                                }
                            }
                        }
                    }
                }
            });
        }

        function exportCSV() {
            var periodEl = document.querySelector('#reportPeriodSelector .period-btn.active');
            var period = periodEl ? periodEl.dataset.period : 'monthly';
            var df = document.getElementById('reportDateFrom') ? document.getElementById('reportDateFrom').value : '';
            var dt = document.getElementById('reportDateTo') ? document.getElementById('reportDateTo').value : '';
            var url = window.API_BASE + '/reports/export/csv?period=' + period;
            if (df) url += '&date_from=' + df;
            if (dt) url += '&date_to=' + dt;
            window.open(url, '_blank');
        }

// Exports for ES6 modules
function downloadCsv(path, filename) {
    window.api(window.API_BASE + path).then(async function(r) {
        if (!r || !r.ok) { window.showToast('Eksport qilib bo\'lmadi', 'error'); return; }
        var blob = await r.blob();
        var url = URL.createObjectURL(blob);
        var a = document.createElement('a');
        a.href = url; a.download = filename;
        document.body.appendChild(a); a.click(); a.remove();
        URL.revokeObjectURL(url);
        window.showToast('Yuklab olindi ✅');
    });
}
window.downloadCsv = downloadCsv;

export { exportCSV, initReportChart, selectReportPeriod, renderReports, generateReport, initBarChart, downloadCsv };
// Expose to window for inline onclick handlers
window.exportCSV = exportCSV;
window.initReportChart = initReportChart;
window.initBarChart = initBarChart;
window.selectReportPeriod = selectReportPeriod;
window.renderReports = renderReports;
window.generateReport = generateReport;
