// ===== API BASE =====
        const API_BASE = '/api/v1/admin';
        const API = '/api/v1';

        // ===== AUTH TOKEN =====
        let authToken = localStorage.getItem('at');
        if (!authToken) {
            location.replace('/admin/login');
            throw new Error('auth_required');
        }

        function getAuthHeaders() {
            const token = localStorage.getItem('at');
            if (!token) return null;
            return { 'Authorization': 'Bearer ' + token, 'Content-Type': 'application/json' };
        }

        async function api(url, opts) {
            opts = opts || {};
            const headers = getAuthHeaders();
            if (!headers) {
                location.replace('/admin/login');
                return null;
            }
            opts.headers = Object.assign({}, headers, opts.headers || {});
            try {
                const r = await fetch(url, opts);
                if (r.status === 401) {
                    localStorage.removeItem('at');
                    localStorage.removeItem('rt');
                    location.replace('/admin/login');
                }
                return r;
            } catch(e) {
                console.error('API error:', e);
                return null;
            }
        }

        function logout() {
            localStorage.removeItem('at');
            localStorage.removeItem('rt');
            location.replace('/admin/login');
        }

        function emptyPage() {
            return { items: [], total: 0, pages: 1 };
        }

        function apiError(msg) {
            showToast(msg || 'API xatoligi', 'error');
        }

        // ===== UTILITY FUNCTIONS =====
        function formatMoney(amount) {
            return new Intl.NumberFormat('uz-UZ').format(amount) + ' so\'m';
        }

        function formatDate(dateStr) {
            const d = new Date(dateStr);
            return d.toLocaleDateString('uz-UZ', { year: 'numeric', month: 'short', day: 'numeric' });
        }

        function getInitials(name) {
            return name.split(' ').map(w => w[0]).join('').substring(0, 2).toUpperCase();
        }

        function renderStars(rating) {
            let html = '<span class="stars">';
            for (let i = 1; i <= 5; i++) {
                html += i <= rating ? '&#9733;' : '<span class="empty">&#9733;</span>';
            }
            html += '</span>';
            return html;
        }

        function statusBadge(status) {
            const labels = {
                active: 'Faol', pending: 'Kutilmoqda', blocked: 'Bloklangan',
                completed: 'Tugallangan', confirmed: 'Tasdiqlangan', in_progress: 'Jarayonda',
                cancelled: 'Bekor qilingan', sent: 'Yuborilgan'
            };
            return '<span class="badge-status ' + status + '">' + (labels[status] || status) + '</span>';
        }

        // ===== TOAST =====
        function showToast(message, type) {
            if (type === undefined) type = 'success';
            var container = document.getElementById('toastContainer');
            var icons = { success: '&#9989;', error: '&#10060;', warning: '&#9888;', info: '&#8505;' };
            var toast = document.createElement('div');
            toast.className = 'toast ' + type;
            toast.innerHTML = '<span class="toast-icon">' + icons[type] + '</span>' +
                '<span class="toast-message">' + message + '</span>' +
                '<span class="toast-close" onclick="this.parentElement.remove()">&times;</span>';
            container.appendChild(toast);
            setTimeout(function() { toast.remove(); }, 4000);
        }

        // ===== MODAL =====
        function openModal(title, bodyHtml, footerHtml) {
            document.getElementById('modalTitle').textContent = title;
            document.getElementById('modalBody').innerHTML = bodyHtml;
            document.getElementById('modalFooter').innerHTML = footerHtml || '';
            document.getElementById('modalOverlay').classList.add('active');
        }

        function closeModal() {
            document.getElementById('modalOverlay').classList.remove('active');
        }

        document.getElementById('modalClose').addEventListener('click', closeModal);
        document.getElementById('modalOverlay').addEventListener('click', function(e) {
            if (e.target === e.currentTarget) closeModal();
        });

        // ===== SIDEBAR =====
        var sidebar = document.getElementById('sidebar');
        document.getElementById('sidebarToggle').addEventListener('click', function() {
            sidebar.classList.toggle('collapsed');
        });

        document.getElementById('mobileMenuBtn').addEventListener('click', function() {
            sidebar.classList.toggle('mobile-open');
        });

        // ===== NAVIGATION =====
        var currentPage = 'dashboard';
        var navItems = document.querySelectorAll('.nav-item');
        var mainContent = document.getElementById('mainContent');

        navItems.forEach(function(item) {
            item.addEventListener('click', function() {
                navigateTo(item.dataset.page);
                sidebar.classList.remove('mobile-open');
            });
        });

        function navigateTo(page) {
            currentPage = page;
            navItems.forEach(function(n) { n.classList.toggle('active', n.dataset.page === page); });
            renderPage(page);
        }

        async function renderPage(page) {
            var renderers = {
                dashboard: renderDashboard,
                users: renderUsers,
                providers: renderProviders,
                orders: renderOrders,
                categories: renderCategories,
                products: renderProducts,
                promos: renderPromos,
                reviews: renderReviews,
                finance: renderFinance,
                settings: renderSettings,
                notifications: renderNotifications,
                reports: renderReports,
                user_analytics: renderUserAnalytics,
            };
            if (renderers[page]) {
                await renderers[page]();
                if (page === 'dashboard') setTimeout(function() { initDashboardCharts(); }, 50);
            }
        }

        // ===== PAGE: DASHBOARD =====
        async function renderDashboard() {
            // Fetch real stats from API
            let s = { orders_total: 0, users: 0, providers: 0, categories: 0, revenue_today: 0, revenue_month: 0, avg_rating: 0, orders_by_status: {} };
            let providers = [];
            try {
                const r = await api(API_BASE + '/stats');
                if (r && r.ok) s = await r.json();
                const providersRes = await api(API_BASE + '/finance/providers');
                if (providersRes && providersRes.ok) providers = await providersRes.json();
            } catch(e) { console.warn('Stats load error', e); apiError('Statistikani yuklab bo\'lmadi'); }

            var providerOptions = providers.map(p => '<option value="' + p.id + '">' + p.name + ' (Balans: ' + formatMoney(p.balance) + ')</option>').join('');

            var recentOrders = [];
            var topProviders = [];
            try {
                const or = await api(API_BASE + '/orders?page=1&per_page=5');
                if (or && or.ok) {
                    var od = await or.json();
                    recentOrders = (od.items || []).map(function(o) {
                        return { id: o.id, service: o.service_name || o.service, price: o.price, status: o.status };
                    });
                }
                const pr = await api(API_BASE + '/providers?page=1&per_page=5');
                if (pr && pr.ok) {
                    var pd = await pr.json();
                    topProviders = (pd.items || []).sort(function(a, b) { return (b.rating || 0) - (a.rating || 0); }).slice(0, 5);
                }
            } catch(e) { console.warn('Dashboard lists fallback', e); }

            var weatherHtml = '<div class="widget-desc">Yuklanmoqda...</div>';
            try {
                const wr = await api(API_BASE + '/utilities/weather?city=Tashkent');
                if (wr && wr.ok) {
                    var w = await wr.json();
                    weatherHtml = '<div class="widget-value">' + w.temperature_celsius + '°C, ' + w.condition + '</div>' +
                                  '<div class="widget-desc">' + w.city + ' (Namlik: ' + w.humidity + '%)</div>';
                }
            } catch(e) {}

            var currencyHtml = '<div class="widget-desc">Yuklanmoqda...</div>';
            try {
                const cr = await api(API_BASE + '/utilities/currency');
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
                        '<div class="stat-card-value">' + formatMoney(s.revenue_today) + '</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Oylik tushum</span>' +
                            '<div class="stat-card-icon green">&#128200;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + formatMoney(s.revenue_month) + '</div>' +
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
                            return '<tr><td>#' + o.id + '</td><td>' + o.service + '</td><td>' + formatMoney(o.price) + '</td><td>' + statusBadge(o.status) + '</td></tr>';
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
                            return '<tr><td>' + (i + 1) + '</td><td><div class="table-user"><div class="table-avatar">' + getInitials(p.name) + '</div><span>' + p.name + '</span></div></td><td>' + renderStars(Math.round(p.rating || 0)) + ' ' + (p.rating || 0) + '</td><td>' + (p.review_count || p.orders || 0) + '</td></tr>';
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
                catLabels = categoriesCache.map(function(c) { return c.title_uz; });
                catData = categoriesCache.map(function() { return 0; });
                const r = await api(API_BASE + '/chart-data?days=30');
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

            let url = API_BASE + '/users?page=' + page + '&per_page=20';
            if (search) url += '&search=' + encodeURIComponent(search);

            try {
                const r = await api(url);
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
                var created = u.created_at ? formatDate(u.created_at) : '—';
                return '<tr>' +
                    '<td>' + u.id + '</td>' +
                    '<td><div class="table-user"><div class="table-avatar">' + getInitials(name) + '</div><span>' + name.trim() + '</span></div></td>' +
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
                const r = await api(API_BASE + '/users/' + id);
                if (!r || !r.ok) { showToast('Foydalanuvchi topilmadi', 'error'); return; }
                var u = await r.json();
                var name = (u.name || '') + ' ' + (u.surname || '');
                openModal('Foydalanuvchi ma\'lumotlari',
                    '<div class="detail-grid">' +
                        '<div class="detail-item"><div class="detail-label">ID</div><div class="detail-value">' + u.id + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Ism</div><div class="detail-value">' + name + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Telefon</div><div class="detail-value">' + u.phone + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Balans</div><div class="detail-value">' + formatMoney(u.balance) + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Cashback</div><div class="detail-value">' + formatMoney(u.cashback) + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Premium</div><div class="detail-value">' + (u.is_premium ? 'Ha' : 'Yo\'q') + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Telegram</div><div class="detail-value">' + (u.telegram_username || '—') + '</div></div>' +
                        '<div class="detail-item"><div class="detail-label">Sana</div><div class="detail-value">' + (u.created_at ? formatDate(u.created_at) : '—') + '</div></div>' +
                    '</div>',
                    '<button class="btn btn-secondary" onclick="closeModal()">Yopish</button>');
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        async function blockUserApi(id) {
            if (!confirm('Foydalanuvchini bloklash/blokdan chiqarish?')) return;
            try {
                await api(API_BASE + '/users/' + id + '/block', { method: 'PATCH', body: JSON.stringify({ is_blocked: true }) });
                showToast('Foydalanuvchi holati o\'zgartirildi', 'info');
                renderUsers(usersPage);
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        async function deleteUserApi(id) {
            if (!confirm('Rostdan ham bu foydalanuvchini o\'chirmoqchimisiz?')) return;
            try {
                await api(API_BASE + '/users/' + id, { method: 'DELETE' });
                showToast('Foydalanuvchi o\'chirildi', 'error');
                renderUsers(usersPage);
            } catch(e) { showToast('Xatolik', 'error'); }
        }


        // ===== PAGE: PROVIDERS =====
        let providersPage = 1;
        let providersData = { items: [], total: 0, pages: 1 };
        let categoriesCache = [];

        async function loadCategoriesCache() {
            try {
                const r = await api(API_BASE + '/categories');
                if (r && r.ok) categoriesCache = await r.json();
            } catch(e) {
                categoriesCache = []; apiError('Kategoriyalarni yuklab bo\'lmadi');
            }
            return categoriesCache;
        }

        async function renderProviders(page) {
            if (page === undefined) page = 1;
            providersPage = page;
            await loadCategoriesCache();

            var search = '';
            var searchEl = document.getElementById('providerSearch');
            if (searchEl) search = searchEl.value;

            let url = API_BASE + '/providers?page=' + page + '&per_page=20';
            if (search) url += '&search=' + encodeURIComponent(search);
            var statusFilterEl = document.getElementById('providerStatusFilter');
            var statusFilter = statusFilterEl ? statusFilterEl.value : '';
            if (statusFilter === 'pending') url += '&is_active=false';
            else if (statusFilter === 'active') url += '&is_active=true';

            try {
                const r = await api(url);
                if (r && r.ok) providersData = await r.json();
            } catch(e) {
                providersData = emptyPage(); apiError('Provayderlarni yuklab bo\'lmadi');
            }

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Soha egalari</h1>' +
                    '<p class="page-subtitle">Xizmat ko\'rsatuvchilarni boshqarish (' + providersData.total + ' ta)</p>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-header">' +
                        '<div class="filters-bar" style="margin-bottom:0; width:100%;">' +
                            '<div class="filter-search">' +
                                '<span class="search-icon">&#128269;</span>' +
                                '<input type="text" placeholder="Nomi yoki telefon bo\'yicha qidirish..." id="providerSearch" value="' + (search || '') + '">' +
                            '</div>' +
                            '<select class="filter-select" id="providerCategoryFilter">' +
                                '<option value="all">Barcha kategoriyalar</option>' +
                                categoriesCache.map(function(c) { return '<option value="' + c.key + '">' + c.title_uz + '</option>'; }).join('') +
                            '</select>' +
                            '<select class="filter-select" id="providerStatusFilter">' +
                                '<option value="">Barcha holatlar</option>' +
                                '<option value="pending"' + (statusFilter === 'pending' ? ' selected' : '') + '>Tasdiqlash kutilmoqda</option>' +
                                '<option value="active"' + (statusFilter === 'active' ? ' selected' : '') + '>Faol</option>' +
                            '</select>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card-body no-padding">' +
                        '<div class="table-container">' +
                            '<table class="data-table" id="providersTable">' +
                                '<thead><tr><th>ID</th><th>Nomi</th><th>Kategoriya</th><th>Telefon</th><th>Reyting</th><th>Holat</th><th>Amallar</th></tr></thead>' +
                                '<tbody id="providersTableBody">' + renderProviderRowsApi(providersData.items) + '</tbody>' +
                            '</table>' +
                        '</div>' +
                    '</div>' +
                    '<div class="pagination">' +
                        '<span class="pagination-info">' + providersData.total + ' ta soha egasi</span>' +
                        '<div class="pagination-buttons" id="providersPagination">' + renderPagination(providersData.pages, providersPage, 'renderProviders') + '</div>' +
                    '</div>' +
                '</div>';

            var providerSearchEl = document.getElementById('providerSearch');
            var searchTimeout;
            providerSearchEl.addEventListener('input', function() {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(function() { renderProviders(1); }, 400);
            });
            var providerStatusFilterEl = document.getElementById('providerStatusFilter');
            if (providerStatusFilterEl) {
                providerStatusFilterEl.addEventListener('change', function() { renderProviders(1); });
            }
        }

        function providerMeta(p) {
            return (p.metadata || p.metadata_json || {});
        }

        function providerNeedsApproval(p) {
            var meta = providerMeta(p);
            var t = meta.type || '';
            // Faqat hujjat/sertifikat talab qiladigan yoki xavfsizlik tekshiruvidan o'tishi kerak bo'lgan kategoriyalar (kuryer, bozorchi)
            if (t === 'nanny' || t === 'massage' || t === 'nurse' || t === 'courier' || t === 'bozorchi') {
                return p.is_active === false || meta.verification_status === 'pending';
            }
            return p.is_active === false;
        }

        function providerDisplayStatus(p) {
            var meta = providerMeta(p);
            if (meta.verification_status === 'rejected') return 'blocked';
            if (providerNeedsApproval(p) && meta.verification_status !== 'rejected') return 'pending';
            return p.is_active !== false ? 'active' : 'blocked';
        }

        function renderProviderRowsApi(providers) {
            return providers.map(function(p) {
                var status = providerDisplayStatus(p);
                var meta = providerMeta(p);
                var typeLabel = meta.type === 'tutor' ? 'Yakka repetitor' :
                    meta.type === 'education_center' ? 'O\'quv markazi' :
                    meta.type === 'nanny' ? 'Enaga' :
                    meta.type === 'disinfection' ? 'Dezinfeksiya' :
                    meta.type === 'massage' ? (meta.massage_role === 'salon' ? 'Massaj salon' : 'Yakka mutaxassis') :
                    meta.type === 'nurse' ? 'Hamshira' :
                    meta.type === 'dental_clinic' ? 'Stomatologiya' :
                    meta.type === 'event_organizer' ? 'Tadbir guruhi (' + (meta.team_size || '?') + ' kishi)' : '';
                var actions = '<button class="btn-icon" title="Ko\'rish" onclick="viewProvider(' + p.id + ')">&#128065;</button>';
                if (providerNeedsApproval(p)) {
                    actions += '<button class="btn-icon" title="Tasdiqlash" style="color:var(--success)" onclick="approveProvider(' + p.id + ')">&#10003;</button>';
                    actions += '<button class="btn-icon danger" title="Rad etish" onclick="rejectProvider(' + p.id + ')">&#10007;</button>';
                }
                actions += '<button class="btn-icon danger" title="O\'chirish" onclick="deleteProvider(' + p.id + ')">&#128465;</button>';
                return '<tr>' +
                    '<td>' + p.id + '</td>' +
                    '<td><div class="table-user"><div class="table-avatar">' + getInitials(p.name) + '</div><span>' + p.name + (typeLabel ? '<br><small style="color:#64748b">' + typeLabel + '</small>' : '') + '</span></div></td>' +
                    '<td>' + (p.category_title || p.category_key || '-') + '</td>' +
                    '<td>' + p.phone + '</td>' +
                    '<td>' + renderStars(Math.round(p.rating || 0)) + ' ' + (p.rating || 0) + '</td>' +
                    '<td>' + statusBadge(status) + '</td>' +
                    '<td><div class="action-group">' + actions + '</div></td>' +
                '</tr>';
            }).join('');
        }

        function renderProviderRows(providers) {
            return renderProviderRowsApi(providers.map(function(p) {
                return { id: p.id, name: p.name, category_title: p.category, phone: p.phone, rating: p.rating, is_active: p.status === 'active' };
            }));
        }

        function filterProviders() {
            renderProviders(1);
        }

        function providerDetailHtml(p) {
            var meta = providerMeta(p);
            var extra = '';
            if (meta.type === 'tutor' || meta.type === 'education_center') {
                var subs = (meta.subjects || meta.courses || []).join(', ');
                var modes = (meta.lesson_modes || []).join(', ');
                extra = '<div class="detail-item"><div class="detail-label">Turi</div><div class="detail-value">' +
                    (meta.type === 'tutor' ? 'Yakka repetitor' : 'O\'quv markazi') + '</div></div>' +
                    (subs ? '<div class="detail-item"><div class="detail-label">Fanlar / kurslar</div><div class="detail-value">' + subs + '</div></div>' : '') +
                    (modes ? '<div class="detail-item"><div class="detail-label">Dars formati</div><div class="detail-value">' + modes + '</div></div>' : '') +
                    '<div class="detail-item"><div class="detail-label">Tasdiqlash</div><div class="detail-value">' + (meta.verification_status || (p.is_active ? 'verified' : 'pending')) + '</div></div>';
            }
            if (meta.type === 'nanny') {
                extra = '<div class="detail-item"><div class="detail-label">Tasdiqlash</div><div class="detail-value">' + (meta.verification_status || 'pending') + '</div></div>';
            }
            if (meta.type === 'disinfection') {
                var areas = (meta.area_types || []).join(', ');
                extra = '<div class="detail-item"><div class="detail-label">Turi</div><div class="detail-value">Dezinfeksiya xizmati</div></div>' +
                    (areas ? '<div class="detail-item"><div class="detail-label">Hudud turlari</div><div class="detail-value">' + areas + '</div></div>' : '') +
                    '<div class="detail-item"><div class="detail-label">Sertifikat</div><div class="detail-value">' + (meta.is_certified ? 'Ha' : 'Yo\'q') + '</div></div>' +
                    '<div class="detail-item"><div class="detail-label">Tasdiqlash</div><div class="detail-value">' + (meta.verification_status || (p.is_active ? 'verified' : 'pending')) + '</div></div>';
            }
            if (meta.type === 'massage') {
                var vm = (meta.visit_modes || []).join(', ');
                var docUrl = meta.document_url || null;
                var passUrl = meta.passport_url || null;
                
                function docCard(label, url) {
                    if (!url) return '<div class="detail-item"><div class="detail-label">' + label + '</div><div class="detail-value" style="color:#94a3b8;">Yuklanmagan</div></div>';
                    return '<div class="detail-item" style="grid-column:1/-1;">' +
                        '<div class="detail-label">' + label + '</div>' +
                        '<div class="detail-value">' +
                            '<a href="' + url + '" target="_blank" style="display:inline-block;">' +
                                '<img src="' + url + '" alt="' + label + '" style="max-width:100%;max-height:200px;border-radius:8px;border:1px solid #e2e8f0;cursor:pointer;" ' +
                                'onerror="this.style.display=\'none\'; this.nextSibling.style.display=\'inline-block\';">' +
                                '<span style="display:none; padding:6px 12px; background:#f1f5f9; border-radius:6px; color:#3b82f6; text-decoration:underline;">Hujjatni ochish ↗</span>' +
                            '</a>' +
                        '</div>' +
                    '</div>';
                }

                extra = '<div class="detail-item"><div class="detail-label">Turi</div><div class="detail-value">' + (meta.massage_role === 'salon' ? 'Salon' : 'Yakka mutaxassis') + '</div></div>' +
                    (vm ? '<div class="detail-item"><div class="detail-label">Qabul usuli</div><div class="detail-value">' + vm + '</div></div>' : '') +
                    '<div class="detail-item"><div class="detail-label">Jinsiyat</div><div class="detail-value">' + (meta.gender || 'both') + '</div></div>' +
                    '<div class="detail-item"><div class="detail-label">Tasdiqlash holati</div><div class="detail-value">' +
                        '<span style="padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600;background:' +
                        (meta.verification_status === 'pending' ? '#fef3c7;color:#d97706' : meta.verification_status === 'rejected' ? '#fee2e2;color:#dc2626' : '#dcfce7;color:#16a34a') +
                        ';">' + (meta.verification_status || 'pending') + '</span>' +
                    '</div></div>' +
                    '<div style="grid-column:1/-1;margin:8px 0;border-top:1px solid #f1f5f9;padding-top:12px;">' +
                        '<div style="font-weight:600;font-size:13px;color:#475569;margin-bottom:10px;">📋 Hujjatlar</div>' +
                    '</div>' +
                    docCard('Sertifikat / Litsenziya', docUrl) +
                    docCard('Pasport', passUrl);
            }
            if (meta.type === 'event_organizer') {
                var ot = (meta.organizer_types || []).join(', ');
                var vt = (meta.venue_types || []).join(', ');
                extra = '<div class="detail-item"><div class="detail-label">Turi</div><div class="detail-value">Tadbir tashkil etuvchi guruh</div></div>' +
                    '<div class="detail-item"><div class="detail-label">Jamoa</div><div class="detail-value">' + (meta.team_size || '-') + ' kishi</div></div>' +
                    (ot ? '<div class="detail-item"><div class="detail-label">Xizmatlar</div><div class="detail-value">' + ot + '</div></div>' : '') +
                    (vt ? '<div class="detail-item"><div class="detail-label">Joy turlari</div><div class="detail-value">' + vt + '</div></div>' : '') +
                    '<div class="detail-item"><div class="detail-label">Hudud</div><div class="detail-value">' + (meta.service_area || '-') + '</div></div>' +
                    '<div class="detail-item"><div class="detail-label">Tasdiqlash</div><div class="detail-value">' + (meta.verification_status || (p.is_active ? 'verified' : 'pending')) + '</div></div>';
            }
            if (meta.type === 'nurse') {
                var medTypes = (meta.medical_types || []).join(', ');
                var docUrl = meta.document_url || null;
                var passUrl = meta.passport_url || null;
                function docCard(label, url) {
                    if (!url) return '<div class="detail-item"><div class="detail-label">' + label + '</div><div class="detail-value" style="color:#94a3b8;">Yuklanmagan</div></div>';
                    return '<div class="detail-item" style="grid-column:1/-1;">' +
                        '<div class="detail-label">' + label + '</div>' +
                        '<div class="detail-value">' +
                            '<a href="' + url + '" target="_blank" style="display:inline-block;">' +
                                '<img src="' + url + '" alt="' + label + '" style="max-width:100%;max-height:200px;border-radius:8px;border:1px solid #e2e8f0;cursor:pointer;" ' +
                                'onerror="this.style.display=\'none\'; this.nextSibling.style.display=\'inline-block\';">' +
                                '<span style="display:none; padding:6px 12px; background:#f1f5f9; border-radius:6px; color:#3b82f6; text-decoration:underline;">Hujjatni ochish ↗</span>' +
                            '</a>' +
                        '</div>' +
                    '</div>';
                }
                extra = '<div class="detail-item"><div class="detail-label">Turi</div><div class="detail-value">Hamshira (uyga borish)</div></div>' +
                    (meta.service_area ? '<div class="detail-item"><div class="detail-label">Hudud</div><div class="detail-value">' + meta.service_area + '</div></div>' : '') +
                    (meta.qualifications ? '<div class="detail-item"><div class="detail-label">Malaka</div><div class="detail-value">' + meta.qualifications + '</div></div>' : '') +
                    (medTypes ? '<div class="detail-item"><div class="detail-label">Tibbiy xizmatlar</div><div class="detail-value">' + medTypes + '</div></div>' : '') +
                    '<div class="detail-item"><div class="detail-label">Tasdiqlash holati</div><div class="detail-value">' +
                        '<span style="padding:3px 10px;border-radius:20px;font-size:12px;font-weight:600;background:' +
                        (meta.verification_status === 'pending' ? '#fef3c7;color:#d97706' : meta.verification_status === 'rejected' ? '#fee2e2;color:#dc2626' : '#dcfce7;color:#16a34a') +
                        ';">' + (meta.verification_status || 'pending') + '</span>' +
                    '</div></div>' +
                    '<div style="grid-column:1/-1;margin:8px 0;border-top:1px solid #f1f5f9;padding-top:12px;">' +
                        '<div style="font-weight:600;font-size:13px;color:#475569;margin-bottom:10px;">📋 Hujjatlar</div>' +
                    '</div>' +
                    docCard('Diplom / Sertifikat', docUrl) +
                    docCard('Pasport', passUrl);
            }
            return '<div class="detail-grid">' +
                '<div class="detail-item"><div class="detail-label">ID</div><div class="detail-value">' + p.id + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Nomi</div><div class="detail-value">' + p.name + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Kategoriya</div><div class="detail-value">' + (p.category_title || p.category || '-') + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Telefon</div><div class="detail-value">' + p.phone + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Manzil</div><div class="detail-value">' + (p.address || '-') + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Holat</div><div class="detail-value">' + statusBadge(providerDisplayStatus(p)) + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Reyting</div><div class="detail-value">' + (p.rating || 0) + ' ' + renderStars(Math.round(p.rating || 0)) + '</div></div>' +
                extra +
            '</div>';
        }

        async function viewProvider(id) {
            var p = providersData.items.find(function(x) { return x.id === id; });
            if (!p) return;
            var footer = '<button class="btn btn-secondary" onclick="closeModal()">Yopish</button>';
            if (providerNeedsApproval(p)) {
                footer = '<button class="btn btn-primary" onclick="approveProvider(' + p.id + '); closeModal();">Tasdiqlash</button>' +
                    '<button class="btn btn-secondary" onclick="rejectProvider(' + p.id + '); closeModal();">Rad etish</button>' + footer;
            }
            openModal('Soha egasi ma\'lumotlari', providerDetailHtml(p), footer);
        }

        function editProvider(id) {
            viewProvider(id);
        }

        function saveProvider(id) {
            closeModal();
        }

        async function approveProvider(id) {
            try {
                await api(API_BASE + '/providers/' + id + '/approve', { method: 'PATCH' });
                showToast('Soha egasi tasdiqlandi'); renderProviders();
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        async function rejectProvider(id) {
            if (!confirm('Bu soha egasini rad etmoqchimisiz?')) return;
            try {
                await api(API_BASE + '/providers/' + id + '/reject', { method: 'PATCH' });
                showToast('Soha egasi rad etildi', 'warning'); renderProviders();
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        async function deleteProvider(id) {
            if (!confirm('Rostdan ham bu soha egasini o\'chirmoqchimisiz?')) return;
            try {
                await api(API_BASE + '/providers/' + id, { method: 'DELETE' });
                showToast('Soha egasi o\'chirildi', 'error'); renderProviders();
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        // ===== PAGE: ORDERS =====
        let ordersPage = 1;
        let ordersData = { items: [], total: 0, pages: 1 };

        async function renderOrders(page) {
            if (page === undefined) page = 1;
            ordersPage = page;
            var status = '';
            var statusEl = document.getElementById('orderStatusFilter');
            if (statusEl) status = statusEl.value;

            let url = API_BASE + '/orders?page=' + page + '&per_page=20';
            if (status && status !== 'all') url += '&status=' + encodeURIComponent(status);

            try {
                const r = await api(url);
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
                    '<td>' + formatMoney(o.price || 0) + '</td>' +
                    '<td>' + statusBadge(o.status || 'pending') + '</td>' +
                    '<td>' + (o.created_at ? formatDate(o.created_at) : '—') + '</td>' +
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
                await api(API_BASE + '/orders/' + id + '/status', { method: 'PATCH', body: JSON.stringify({ status: status }) });
                showToast('Buyurtma statusi yangilandi');
                renderOrders(ordersPage);
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        // ===== PAGE: CATEGORIES =====
        function getCategoryEmoji(icon) {
            if (!icon) return '&#128194;';
            var map = {
                'scissors': '✂️', 'sparkles': '✨', 'droplet': '💦', 'droplets': '💦', 'zap': '⚡',
                'sprayCan': '🧴', 'car': '🚗', 'trophy': '🏆', 'graduationCap': '🎓',
                'hammer': '🔨', 'hardHat': '👷', 'wind': '💨', 'baby': '👶',
                'bookOpen': '📖', 'shieldCheck': '🛡️', 'refrigerator': '🗄️', 'package': '📦',
                'heartPulse': '❤️', 'stethoscope': '🩺', 'smile': '😊', 'partyPopper': '🎉',
                'shoppingCart': '🛒', 'utensils': '🍴', 'gamepad2': '🎮', 'sports_soccer': '⚽',
                'monitor': '🖥️', 'layoutGrid': '🔲', 'users': '👥', 'wrench': '🔧'
            };
            return map[icon] || icon;
        }

        async function renderCategories() {
            await loadCategoriesCache();
            var cats = categoriesCache;

            var html =
                '<div class="page-header">' +
                    '<h1 class="page-title">Kategoriyalar</h1>' +
                    '<p class="page-subtitle">Xizmat kategoriyalarini boshqarish (' + cats.length + ' ta)</p>' +
                '</div>' +
                '<div style="display:flex; justify-content:flex-end; margin-bottom:16px;">' +
                    '<button class="btn btn-primary" onclick="addCategoryModal()">&#43; Yangi kategoriya</button>' +
                '</div>' +
                '<div id="categoriesList">';

            cats.forEach(function(c, ci) {
                var variants = c.variants || [];
                html += '<div class="category-item" id="category-' + ci + '">' +
                    '<div class="category-header" onclick="toggleCategory(' + ci + ')">' +
                        '<div class="category-icon" style="background:' + (c.accent_color || '#6366F1') + '20; color:' + (c.accent_color || '#6366F1') + ';">' + getCategoryEmoji(c.icon) + '</div>' +
                        '<div class="category-info">' +
                            '<div class="category-name">' + c.title_uz + '</div>' +
                            '<div class="category-key">' + c.key + '</div>' +
                        '</div>' +
                        '<span class="category-variants-count">' + variants.length + ' ta variant</span>' +
                        '<div class="action-group">' +
                            '<button class="btn-icon" title="Tahrirlash" onclick="event.stopPropagation(); editCategoryModal(' + ci + ')">&#9998;</button>' +
                            '<button class="btn-icon danger" title="O\'chirish" onclick="event.stopPropagation(); deleteCategory(' + ci + ', ' + (c.id || 0) + ')">&#128465;</button>' +
                        '</div>' +
                        '<span class="category-expand">&#9660;</span>' +
                    '</div>' +
                    '<div class="category-variants">' +
                        '<div style="display:flex; justify-content:space-between; align-items:center; margin-bottom:12px;">' +
                            '<strong style="font-size:14px;">Variantlar</strong>' +
                            '<button class="btn btn-sm btn-primary" onclick="addVariantModal(' + ci + ', ' + (c.id || 0) + ')">&#43; Variant qo\'shish</button>' +
                        '</div>';
                variants.forEach(function(v) {
                    html += '<div class="variant-item">' +
                        '<div><span class="variant-label">' + (v.label_uz || v.label) + '</span></div>' +
                        '<div style="display:flex; align-items:center; gap:12px;">' +
                            '<span class="variant-price">' + formatMoney(v.base_price) + '</span>' +
                            '<div class="action-group">' +
                                '<button class="btn-icon danger" title="O\'chirish" onclick="deleteVariant(' + ci + ', ' + (c.id || 0) + ', ' + v.id + ')">&#128465;</button>' +
                            '</div>' +
                        '</div>' +
                    '</div>';
                });
                html += '</div></div>';
            });

            html += '</div>';
            mainContent.innerHTML = html;
        }

        function toggleCategory(idx) {
            document.getElementById('category-' + idx).classList.toggle('expanded');
        }

        function addCategoryModal() {
            openModal('Yangi kategoriya qo\'shish',
                '<div class="form-group"><label class="form-label">Kalit (key)</label><input type="text" class="form-input" id="catKey" placeholder="masalan: elektr"></div>' +
                '<div class="form-group"><label class="form-label">Nomi (o\'zbekcha)</label><input type="text" class="form-input" id="catTitle" placeholder="masalan: Elektrik xizmatlari"></div>' +
                '<div class="form-row">' +
                    '<div class="form-group"><label class="form-label">Icon (emoji)</label><input type="text" class="form-input" id="catIcon" placeholder="&#9889;"></div>' +
                    '<div class="form-group"><label class="form-label">Rang</label><input type="color" class="form-input" id="catColor" value="#6366F1" style="height:40px; padding:4px;"></div>' +
                '</div>',
                '<button class="btn btn-secondary" onclick="closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveCategory()">Saqlash</button>');
        }

        function saveCategory() {
            var key = document.getElementById('catKey').value.trim();
            var title = document.getElementById('catTitle').value.trim();
            var icon = document.getElementById('catIcon').value || '&#128194;';
            var color = document.getElementById('catColor').value;
            if (!key || !title) { showToast('Kalit va nomi majburiy', 'error'); return; }
            api(API_BASE + '/categories', {
                method: 'POST',
                body: JSON.stringify({ key: key, title_uz: title, icon: icon, accent_color: color })
            }).then(function(r) {
                if (r && r.ok) {
                    showToast('Kategoriya qo\'shildi');
                    closeModal();
                    renderCategories();
                } else {
                    showToast('Xatolik yuz berdi', 'error');
                }
            });
        }

        function editCategoryModal(idx) {
            var c = categoriesCache[idx];
            if (!c) return;
            openModal('Kategoriyani tahrirlash',
                '<div class="form-group"><label class="form-label">Kalit (key)</label><input type="text" class="form-input" id="catKey" value="' + c.key + '"></div>' +
                '<div class="form-group"><label class="form-label">Nomi (o\'zbekcha)</label><input type="text" class="form-input" id="catTitle" value="' + c.title_uz + '"></div>' +
                '<div class="form-row">' +
                    '<div class="form-group"><label class="form-label">Icon (emoji)</label><input type="text" class="form-input" id="catIcon" value="' + c.icon + '"></div>' +
                    '<div class="form-group"><label class="form-label">Rang</label><input type="color" class="form-input" id="catColor" value="' + c.accent_color + '" style="height:40px; padding:4px;"></div>' +
                '</div>',
                '<button class="btn btn-secondary" onclick="closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="updateCategory(' + idx + ', ' + c.id + ')">Saqlash</button>');
        }

        function updateCategory(idx, catId) {
            var payload = {
                key: document.getElementById('catKey').value.trim(),
                title_uz: document.getElementById('catTitle').value.trim(),
                icon: document.getElementById('catIcon').value,
                accent_color: document.getElementById('catColor').value
            };
            api(API_BASE + '/categories/' + catId, {
                method: 'PATCH',
                body: JSON.stringify(payload)
            }).then(function(r) {
                if (r && r.ok) {
                    showToast('Kategoriya yangilandi');
                    closeModal();
                    renderCategories();
                } else {
                    showToast('Xatolik yuz berdi', 'error');
                }
            });
        }

        function deleteCategory(idx, catId) {
            if (!catId) { showToast('Kategoriya ID topilmadi', 'error'); return; }
            if (confirm('Bu kategoriyani o\'chirmoqchimisiz?')) {
                api(API_BASE + '/categories/' + catId, { method: 'DELETE' }).then(function(r) {
                    if (r && (r.ok || r.status === 204)) {
                        showToast('Kategoriya o\'chirildi', 'error');
                        renderCategories();
                    } else {
                        showToast('O\'chirib bo\'lmadi', 'error');
                    }
                });
            }
        }

        function addVariantModal(catIdx, catId) {
            openModal('Yangi variant qo\'shish',
                '<div class="form-group"><label class="form-label">Variant nomi</label><input type="text" class="form-input" id="varLabel" placeholder="masalan: Rozetka o\'rnatish"></div>' +
                '<div class="form-group"><label class="form-label">Boshlang\'ich narx (so\'m)</label><input type="number" class="form-input" id="varPrice" placeholder="50000"></div>',
                '<button class="btn btn-secondary" onclick="closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveVariant(' + catIdx + ', ' + catId + ')">Saqlash</button>');
        }

        function saveVariant(catIdx, catId) {
            var label = document.getElementById('varLabel').value.trim();
            var price = parseInt(document.getElementById('varPrice').value);
            if (!label || !price) { showToast('Nomi va narx majburiy', 'error'); return; }
            api(API_BASE + '/categories/' + catId + '/variants', {
                method: 'POST',
                body: JSON.stringify({ label_uz: label, base_price: price })
            }).then(function(r) {
                if (r && r.ok) {
                    showToast('Variant qo\'shildi');
                    closeModal();
                    renderCategories();
                } else {
                    showToast('Xatolik yuz berdi', 'error');
                }
            });
        }

        function editVariantModal(catIdx, varId) {
            var cat = categoriesCache[catIdx];
            if (!cat) return;
            var v = (cat.variants || []).find(function(x) { return x.id === varId; });
            if (!v) return;
            openModal('Variantni tahrirlash',
                '<div class="form-group"><label class="form-label">Variant nomi</label><input type="text" class="form-input" id="varLabel" value="' + (v.label_uz || v.label) + '"></div>' +
                '<div class="form-group"><label class="form-label">Boshlang\'ich narx (so\'m)</label><input type="number" class="form-input" id="varPrice" value="' + v.base_price + '"></div>',
                '<button class="btn btn-secondary" onclick="closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="updateVariant(' + catIdx + ', ' + cat.id + ', ' + varId + ')">Saqlash</button>');
        }

        function updateVariant(catIdx, catId, varId) {
            var payload = {
                label_uz: document.getElementById('varLabel').value.trim(),
                base_price: parseInt(document.getElementById('varPrice').value)
            };
            api(API_BASE + '/categories/' + catId + '/variants/' + varId, {
                method: 'PATCH',
                body: JSON.stringify(payload)
            }).then(function(r) {
                if (r && r.ok) {
                    showToast('Variant yangilandi');
                    closeModal();
                    renderCategories();
                } else {
                    showToast('Xatolik yuz berdi', 'error');
                }
            });
        }

        function deleteVariant(catIdx, catId, varId) {
            if (confirm('Bu variantni o\'chirmoqchimisiz?')) {
                api(API_BASE + '/categories/' + catId + '/variants/' + varId, { method: 'DELETE' }).then(function(r) {
                    if (r && (r.ok || r.status === 204)) {
                        showToast('Variant o\'chirildi', 'error');
                        renderCategories();
                    } else {
                        showToast('O\'chirib bo\'lmadi', 'error');
                    }
                });
            }
        }

        // ===== PAGE: REVIEWS =====
        let reviewsData = { items: [], total: 0, pages: 1 };

        async function renderReviews(page) {
            if (page === undefined) page = 1;
            let url = API_BASE + '/reviews?page=' + page + '&per_page=20';
            try {
                const r = await api(url);
                if (r && r.ok) reviewsData = await r.json();
            } catch(e) {
                reviewsData = emptyPage(); apiError('Sharhlarni yuklab bo\'lmadi');
            }

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Sharhlar</h1>' +
                    '<p class="page-subtitle">Foydalanuvchi sharhlarini moderatsiya qilish (' + reviewsData.total + ' ta)</p>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-body no-padding">' +
                        '<div class="table-container">' +
                            '<table class="data-table" id="reviewsTable">' +
                                '<thead><tr><th>ID</th><th>Foydalanuvchi</th><th>Provider</th><th>Reyting</th><th>Sharh</th><th>Sana</th><th>Amallar</th></tr></thead>' +
                                '<tbody id="reviewsTableBody">' + renderReviewRowsApi(reviewsData.items) + '</tbody>' +
                            '</table>' +
                        '</div>' +
                    '</div>' +
                    '<div class="pagination">' +
                        '<span class="pagination-info">' + reviewsData.total + ' ta sharh</span>' +
                        '<div class="pagination-buttons" id="reviewsPagination">' + renderPagination(reviewsData.pages, page, 'renderReviews') + '</div>' +
                    '</div>' +
                '</div>';
        }

        function renderReviewRowsApi(reviews) {
            return reviews.map(function(r) {
                return '<tr>' +
                    '<td>' + r.id + '</td>' +
                    '<td><div class="table-user"><div class="table-avatar">' + getInitials(r.user_name || r.user || '?') + '</div><span>' + (r.user_name || r.user || '-') + '</span></div></td>' +
                    '<td>' + (r.provider_name || r.provider || '-') + '</td>' +
                    '<td>' + renderStars(r.rating) + '</td>' +
                    '<td style="max-width:300px;">' + (r.comment || r.text || '') + '</td>' +
                    '<td>' + formatDate(r.created_at) + '</td>' +
                    '<td><div class="action-group">' +
                        '<button class="btn-icon danger" title="O\'chirish" onclick="deleteReview(' + r.id + ')">&#128465;</button>' +
                    '</div></td>' +
                '</tr>';
            }).join('');
        }

        function renderReviewRows(reviews) {
            return renderReviewRowsApi(reviews);
        }

        function filterReviews() {
            renderReviews(1);
        }

        function deleteReview(id) {
            if (confirm('Bu sharhni o\'chirmoqchimisiz?')) {
                api(API_BASE + '/reviews/' + id, { method: 'DELETE' }).then(function(r) {
                    if (r && (r.ok || r.status === 204)) {
                        showToast('Sharh o\'chirildi', 'error');
                        renderReviews();
                    } else {
                        showToast('O\'chirib bo\'lmadi', 'error');
                    }
                });
            }
        }

        // ===== PAGE: FINANCE =====
        async function renderFinance() {
            var f = { total_revenue: 0, total_commission: 0, total_cashback_given: 0, platform_balance: 0, commission_rate: 15, transactions: [] };
            try {
                const r = await api(API_BASE + '/finance/stats');
                if (r && r.ok) {
                    var stats = await r.json();
                    f.total_revenue = stats.total_revenue || 0;
                    f.total_commission = stats.total_commission || 0;
                    f.total_cashback_given = stats.total_cashback_given || 0;
                    f.platform_balance = stats.platform_balance || 0;
                    f.commission_rate = stats.commission_rate || 15;
                }
            } catch(e) {}

            await loadCategoriesCache();
            var providerOptions = '';
            try {
                const pr = await api(API_BASE + '/providers?per_page=100');
                if (pr && pr.ok) {
                    var pdata = await pr.json();
                    providerOptions = (pdata.items || []).filter(function(p) { return p.is_active; }).map(function(p) {
                        return '<option value="' + p.id + '">' + p.name + '</option>';
                    }).join('');
                }
            } catch(e) {}
            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Moliya</h1>' +
                    '<p class="page-subtitle">Moliyaviy boshqaruv va hisobotlar</p>' +
                '</div>' +
                '<div class="stats-grid">' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Jami tushum</span>' +
                            '<div class="stat-card-icon green">&#128200;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + formatMoney(f.total_revenue) + '</div>' +
                        '<span class="stat-card-change up">&#8593; Bajarilgan buyurtmalar</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Komissiya (' + f.commission_rate + '%)</span>' +
                            '<div class="stat-card-icon purple">&#128176;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + formatMoney(f.total_commission) + '</div>' +
                        '<span class="stat-card-change up">Platforma daromadi</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Cashback berilgan</span>' +
                            '<div class="stat-card-icon orange">&#127873;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + formatMoney(f.total_topups) + '</div>' +
                        '<span class="stat-card-change up">Jami kiritilgan</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Qaytarilgan summalar (Refund)</span>' +
                            '<div class="stat-card-icon blue">&#128178;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + formatMoney(f.total_refunds) + '</div>' +
                        '<span class="stat-card-change down">Foydalanuvchilarga</span>' +
                    '</div>' +
                '</div>' +
                '<div style="display:grid; grid-template-columns: 1fr 1fr; gap:24px;">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Provider hisobini boshqarish</h3></div>' +
                        '<div class="card-body">' +
                            '<div class="form-group">' +
                                '<label class="form-label">Provider</label>' +
                                '<select class="form-input" id="payoutProvider">' +
                                    '<option value="">Tanlang...</option>' +
                                    providerOptions +
                                '</select>' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Amaliyot turi</label>' +
                                '<select class="form-input" id="transactionType">' +
                                    '<option value="topup">Pul qo\'shish (Top-up)</option>' +
                                    '<option value="refund">Pul qaytarish / Yechish (Refund)</option>' +
                                '</select>' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Summa (so\'m)</label>' +
                                '<input type="number" class="form-input" id="payoutAmount" placeholder="500000">' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Izoh</label>' +
                                '<textarea class="form-input" id="payoutNote" placeholder="O\'tkazma haqida qisqacha..." rows="3"></textarea>' +
                            '</div>' +
                            '<button class="btn btn-primary" onclick="processProviderTransaction()" style="width:100%;">Tranzaksiyani amalga oshirish</button>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Komissiya stavkasi</h3></div>' +
                        '<div class="card-body">' +
                            '<div class="form-group">' +
                                '<label class="form-label">Komissiya foizi (%)</label>' +
                                '<input type="number" class="form-input" id="commissionRate" value="' + f.commission_rate + '" min="1" max="50">' +
                            '</div>' +
                            '<button class="btn btn-primary" onclick="updateCommissionRate()" style="width:100%;">Yangilash</button>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
                '<div class="card" style="margin-top:24px;">' +
                    '<div class="card-header"><h3 class="card-title">Moliyaviy ma\'lumotlar API dan yuklanadi</h3></div>' +
                    '<div class="card-body"><p style="color:var(--text-muted);">Tranzaksiyalar tarixi tez orada qo\'shiladi.</p></div>' +
                '</div>';
        }

        function processProviderTransaction() {
            var provider = document.getElementById('payoutProvider').value;
            var amount = document.getElementById('payoutAmount').value;
            var note = document.getElementById('payoutNote').value;
            var type = document.getElementById('transactionType').value;
            if (!provider || !amount) { showToast('Provider va summa majburiy', 'error'); return; }
            api(API_BASE + '/finance/provider-transaction', {
                method: 'POST',
                body: JSON.stringify({ provider_id: parseInt(provider), amount: parseFloat(amount), type: type, note: note || null })
            }).then(function(r) {
                if (r && r.ok) {
                    showToast('Tranzaksiya amalga oshirildi');
                    document.getElementById('payoutAmount').value = '';
                    document.getElementById('payoutNote').value = '';
                    renderFinance(); // Refresh balances
                } else {
                    showToast('Tranzaksiya amalga oshmadi', 'error');
                }
            });
        }

        function updateCommissionRate() {
            var rate = parseFloat(document.getElementById('commissionRate').value);
            api(API_BASE + '/finance/commission', {
                method: 'PATCH',
                body: JSON.stringify({ rate: rate })
            }).then(function(r) {
                if (r && r.ok) {
                    showToast('Komissiya stavkasi ' + rate + '% ga yangilandi');
                } else {
                    showToast('Yangilab bo\'lmadi', 'error');
                }
            });
        }

        // ===== PAGE: PROMOS & BANNERS =====
        async function renderPromos() {
            var promos = [];
            try {
                const r = await api(API_BASE + '/promos');
                if (r && r.ok) promos = await r.json();
            } catch(e) { apiError('Aksiyalarni yuklab bo\'lmadi'); }

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Aksiyalar va Bannerlar</h1>' +
                    '<p class="page-subtitle">Mobil ilova bosh sahifasidagi aksiya bannerlarini boshqarish</p>' +
                '</div>' +
                '<div style="display:grid; grid-template-columns: 2fr 1fr; gap: 24px;">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Mavjud bannerlar</h3></div>' +
                        '<div class="card-body no-padding">' +
                            '<div class="table-container">' +
                                '<table class="data-table">' +
                                    '<thead><tr><th>ID</th><th>Sarlavha</th><th>Kichik matn</th><th>Badge</th><th>Ranglar</th><th>Rasm</th><th>Amallar</th></tr></thead>' +
                                    '<tbody>' +
                                        (promos.length === 0 ? '<tr><td colspan="6" style="text-align:center;padding:24px;color:var(--gray-400);">Bannerlar topilmadi</td></tr>' : 
                                        promos.map(function(p) {
                                            var colorBadges = (p.colors || '').split(',').map(function(c) {
                                                return '<span style="display:inline-block;width:12px;height:12px;border-radius:50%;background:'+c+';margin-right:4px;border:1px solid #ccc;"></span>';
                                            }).join('');
                                            return '<tr>' +
                                                '<td>#' + p.id + '</td>' +
                                                '<td><b>' + (p.title || '—') + '</b></td>' +
                                                '<td>' + (p.subtitle || '—') + '</td>' +
                                                '<td><span class="badge-status active">' + (p.badge || 'AKSIYA') + '</span></td>' +
                                                '<td>' + colorBadges + ' ' + (p.colors || '') + '</td>' +
                                                '<td>' + (p.image_url ? '<img src="'+p.image_url+'" style="width:40px;height:40px;object-fit:cover;border-radius:4px;border:1px solid var(--gray-200);">' : '—') + '</td>' +
                                                '<td><button class="btn btn-sm btn-danger" onclick="deletePromo(' + p.id + ')">O\'chirish</button></td>' +
                                            '</tr>';
                                        }).join('')) +
                                    '</tbody>' +
                                '</table>' +
                            '</div>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Yangi aksiya qo\'shish</h3></div>' +
                        '<div class="card-body">' +
                            '<form id="addPromoForm" onsubmit="event.preventDefault(); createPromo();">' +
                                '<div class="form-group">' +
                                    '<label class="form-label">Sarlavha (Title)</label>' +
                                    '<input type="text" class="form-input" id="promoTitle" placeholder="Sartarosh — 25% chegirma" required>' +
                                '</div>' +
                                '<div class="form-group">' +
                                    '<label class="form-label">Tavsif (Subtitle)</label>' +
                                    '<input type="text" class="form-input" id="promoSubtitle" placeholder="Dushanba–chorshanba, barcha xizmatlar" required>' +
                                '</div>' +
                                '<div class="form-group">' +
                                    '<label class="form-label">Nishon matni (Badge)</label>' +
                                    '<input type="text" class="form-input" id="promoBadge" placeholder="-25%" required>' +
                                '</div>' +
                                '<div class="form-group">' +
                                    '<label class="form-label">Ranglar gradiyenti (Colors)</label>' +
                                    '<input type="text" class="form-input" id="promoColors" placeholder="#6366F1,#A855F7" required>' +
                                    '<small class="text-muted" style="display:block;margin-top:4px;">Ikkita HEX rangni vergul bilan ajratib yozing.</small>' +
                                '</div>' +
                                '<div class="form-group">' +
                                    '<label class="form-label">Rasm (URL)</label>' +
                                    '<input type="url" class="form-input" id="promoImageUrl" placeholder="https://example.com/banner.png">' +
                                    '<small class="text-muted" style="display:block;margin-top:4px;">Ixtiyoriy. Banner rasmi havolasini kiriting.</small>' +
                                '</div>' +
                                '<button type="submit" class="btn btn-primary" style="width:100%;justify-content:center;margin-top:8px;">Qo\'shish</button>' +
                            '</form>' +
                        '</div>' +
                    '</div>' +
                '</div>';
        }

        async function createPromo() {
            const title = document.getElementById('promoTitle').value.trim();
            const subtitle = document.getElementById('promoSubtitle').value.trim();
            const badge = document.getElementById('promoBadge').value.trim();
            const colors = document.getElementById('promoColors').value.trim();
            const image_url = document.getElementById('promoImageUrl').value.trim();
            if (!title || !subtitle || !badge || !colors) return;

            try {
                const r = await api(API_BASE + '/promos', {
                    method: 'POST',
                    body: JSON.stringify({ title, subtitle, badge, colors, image_url: image_url || null })
                });
                if (r && r.ok) {
                    showToast('Yangi aksiya banneri qo\'shildi');
                    renderPromos();
                } else {
                    apiError('Banner qo\'shib bo\'lmadi');
                }
            } catch(e) { apiError('Banner qo\'shib bo\'lmadi'); }
        }

        async function deletePromo(id) {
            if (!confirm('Ushbu aksiyani o\'chirishni xohlaysizmi?')) return;
            try {
                const r = await api(API_BASE + '/promos/' + id, {
                    method: 'DELETE'
                });
                if (r && r.ok) {
                    showToast('Aksiya o\'chirildi');
                    renderPromos();
                } else {
                    apiError('O\'chirib bo\'lmadi');
                }
            } catch(e) { apiError('O\'chirib bo\'lmadi'); }
        }

        // ===== PAGE: SETTINGS =====
        async function renderSettings() {
            var f = { commission_rate: 15, cashback_rate: 2, currency: 'UZS', min_withdrawal: 100000, maintenance_mode: false, registration_open: true, support_phone: '+998 71 200 00 00', support_telegram: '@superapp_support' };
            try {
                const r = await api(API_BASE + '/settings');
                if (r && r.ok) f = await r.json();
            } catch(e) {}
            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Sozlamalar</h1>' +
                    '<p class="page-subtitle">Platforma parametrlarini boshqarish</p>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-body">' +
                        '<div class="settings-section">' +
                            '<h3 class="settings-section-title">Moliyaviy sozlamalar</h3>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Komissiya foizi</div>' +
                                    '<div class="setting-description">Platforma komissiyasi (%)</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<input type="number" class="form-input" id="settingCommission" value="' + f.commission_rate + '" min="1" max="50" style="width:80px;">' +
                                '</div>' +
                            '</div>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Cashback foizi</div>' +
                                    '<div class="setting-description">Foydalanuvchilarga cashback (%)</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<input type="number" class="form-input" id="settingCashback" value="' + f.cashback_rate + '" min="0" max="20" style="width:80px;">' +
                                '</div>' +
                            '</div>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Valyuta</div>' +
                                    '<div class="setting-description">Platforma valyutasi</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<select class="form-input" id="settingCurrency" style="width:120px;">' +
                                        '<option value="UZS"' + (f.currency === 'UZS' ? ' selected' : '') + '>UZS</option>' +
                                        '<option value="USD">USD</option>' +
                                        '<option value="RUB">RUB</option>' +
                                    '</select>' +
                                '</div>' +
                            '</div>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Min. yechib olish summasi</div>' +
                                    '<div class="setting-description">Provider minimal yechib olish summasi</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<input type="number" class="form-input" id="settingMinWithdraw" value="' + (f.min_withdrawal || 100000) + '" style="width:140px;">' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                        '<div class="settings-section">' +
                            '<h3 class="settings-section-title">Tizim sozlamalari</h3>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Maintenance rejimi</div>' +
                                    '<div class="setting-description">Yoqilganda platforma vaqtinchalik to\'xtatiladi</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<label class="toggle-switch">' +
                                        '<input type="checkbox" id="settingMaintenance"' + (f.maintenance_mode ? ' checked' : '') + '>' +
                                        '<span class="toggle-slider"></span>' +
                                    '</label>' +
                                '</div>' +
                            '</div>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Registratsiya ochiq</div>' +
                                    '<div class="setting-description">Yangi foydalanuvchilar ro\'yxatdan o\'tishi mumkin</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<label class="toggle-switch">' +
                                        '<input type="checkbox" id="settingRegistration"' + (f.registration_open !== false ? ' checked' : '') + '>' +
                                        '<span class="toggle-slider"></span>' +
                                    '</label>' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                        '<div class="settings-section">' +
                            '<h3 class="settings-section-title">Qo\'llab-quvvatlash</h3>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Support telefon</div>' +
                                    '<div class="setting-description">Mijozlar uchun qo\'llab-quvvatlash raqami</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<input type="text" class="form-input" id="settingSupportPhone" value="' + (f.support_phone || '+998 71 200 00 00') + '" style="width:200px;">' +
                                '</div>' +
                            '</div>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Support Telegram</div>' +
                                    '<div class="setting-description">Telegram support kanali yoki bot</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<input type="text" class="form-input" id="settingSupportTelegram" value="' + (f.support_telegram || '@superapp_support') + '" style="width:200px;">' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                        '<div style="padding-top:16px;">' +
                            '<button class="btn btn-primary" onclick="saveSettings()">&#128190; Saqlash</button>' +
                        '</div>' +
                    '</div>' +
                '</div>';
        }

        function saveSettings() {
            var payload = {
                commission_rate: parseFloat(document.getElementById('settingCommission').value),
                cashback_rate: parseFloat(document.getElementById('settingCashback').value),
                currency: document.getElementById('settingCurrency').value,
                min_withdrawal: parseFloat(document.getElementById('settingMinWithdraw').value),
                maintenance_mode: document.getElementById('settingMaintenance').checked,
                registration_open: document.getElementById('settingRegistration').checked,
                support_phone: document.getElementById('settingSupportPhone').value,
                support_telegram: document.getElementById('settingSupportTelegram').value
            };
            api(API_BASE + '/settings', {
                method: 'PATCH',
                body: JSON.stringify(payload)
            }).then(function(r) {
                if (r && r.ok) {
                    showToast('Sozlamalar muvaffaqiyatli saqlandi');
                } else {
                    showToast('Saqlab bo\'lmadi', 'error');
                }
            });
        }

        // ===== PAGE: NOTIFICATIONS =====
        async function renderNotifications() {
            var notifItems = [];
            try {
                const r = await api(API_BASE + '/notifications');
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
                    '<td><span class="badge-status ' + typeClass + '">' + (n.type || 'in_app').toUpperCase() + '</span></td>' +
                    '<td>' + (n.title || '') + '</td>' +
                    '<td>' + targetLabel + '</td>' +
                    '<td>' + (n.count || 0).toLocaleString() + '</td>' +
                    '<td>' + (n.sent_at || n.created_at || '-') + '</td>' +
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

            if (!title || !message) { showToast('Sarlavha va xabar majburiy', 'error'); return; }

            api(API_BASE + '/notifications/send', {
                method: 'POST',
                body: JSON.stringify({ type: type, title: title, message: message, target: target })
            }).then(function(r) {
                if (r && r.ok) {
                    showToast('"' + title + '" bildirishnomasi yuborildi');
                    renderNotifications();
                } else {
                    showToast('Yuborib bo\'lmadi', 'error');
                }
            });
        }

        // ===== PAGE: REPORTS =====
        async function renderReports() {
            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Hisobotlar</h1>' +
                    '<p class="page-subtitle">Tahliliy hisobotlar va eksport</p>' +
                '</div>' +
                '<div class="card" style="margin-bottom:24px;">' +
                    '<div class="card-header">' +
                        '<div class="period-selector" id="reportPeriodSelector">' +
                            '<button class="period-btn" data-period="daily" onclick="selectReportPeriod(this)">Kunlik</button>' +
                            '<button class="period-btn" data-period="weekly" onclick="selectReportPeriod(this)">Haftalik</button>' +
                            '<button class="period-btn active" data-period="monthly" onclick="selectReportPeriod(this)">Oylik</button>' +
                            '<button class="period-btn" data-period="yearly" onclick="selectReportPeriod(this)">Yillik</button>' +
                        '</div>' +
                        '<div style="display:flex; gap:8px; align-items:center;">' +
                            '<input type="date" class="form-input" id="reportDateFrom" value="2025-05-01" style="width:auto;">' +
                            '<span style="color:var(--gray-400);">&#8212;</span>' +
                            '<input type="date" class="form-input" id="reportDateTo" value="2025-05-15" style="width:auto;">' +
                            '<button class="btn btn-primary" onclick="generateReport()">&#128269; Hisobot</button>' +
                            '<button class="btn btn-success" onclick="exportCSV()">&#128190; CSV eksport</button>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
                '<div class="stats-grid" id="reportStats">' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Jami buyurtmalar</span>' +
                            '<div class="stat-card-icon purple">&#128230;</div>' +
                        '</div>' +
                        '<div class="stat-card-value" id="reportTotalOrders">0</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Tugallangan</span>' +
                            '<div class="stat-card-icon green">&#9989;</div>' +
                        '</div>' +
                        '<div class="stat-card-value" id="reportCompleted">0</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Bekor qilingan</span>' +
                            '<div class="stat-card-icon red">&#10060;</div>' +
                        '</div>' +
                        '<div class="stat-card-value" id="reportCancelled">0</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Jami tushum</span>' +
                            '<div class="stat-card-icon yellow">&#128176;</div>' +
                        '</div>' +
                        '<div class="stat-card-value" id="reportRevenue">' + formatMoney(0) + '</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Komissiya</span>' +
                            '<div class="stat-card-icon blue">&#128178;</div>' +
                        '</div>' +
                        '<div class="stat-card-value" id="reportCommission">' + formatMoney(0) + '</div>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Yangi foydalanuvchilar</span>' +
                            '<div class="stat-card-icon orange">&#128101;</div>' +
                        '</div>' +
                        '<div class="stat-card-value" id="reportNewUsers">0</div>' +
                    '</div>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-header"><h3 class="card-title">Tushum dinamikasi</h3></div>' +
                    '<div class="card-body">' +
                        '<div class="chart-container"><canvas id="reportChart"></canvas></div>' +
                    '</div>' +
                '</div>';
            await generateReport();
            setTimeout(initReportChart, 50);
        }

        function selectReportPeriod(el) {
            document.querySelectorAll('#reportPeriodSelector .period-btn').forEach(function(b) { b.classList.remove('active'); });
            el.classList.add('active');
        }

        async function generateReport() {
            var periodEl = document.querySelector('#reportPeriodSelector .period-btn.active');
            var period = periodEl ? periodEl.dataset.period : 'monthly';
            try {
                const r = await api(API_BASE + '/reports?period=' + period);
                if (!r || !r.ok) { apiError('Hisobot yuklanmadi'); return; }
                var rep = await r.json();
                document.getElementById('reportTotalOrders').textContent = rep.total_orders.toLocaleString();
                document.getElementById('reportCompleted').textContent = rep.completed_orders.toLocaleString();
                document.getElementById('reportCancelled').textContent = rep.cancelled_orders.toLocaleString();
                document.getElementById('reportRevenue').textContent = formatMoney(rep.total_revenue);
                document.getElementById('reportCommission').textContent = formatMoney(rep.total_commission);
                document.getElementById('reportNewUsers').textContent = rep.new_users.toLocaleString();
                showToast('Hisobot yangilandi');
            } catch(e) { apiError('Hisobot yuklanmadi'); }
        }

        function exportCSV() {
            var periodEl = document.querySelector('#reportPeriodSelector .period-btn.active');
            var period = periodEl ? periodEl.dataset.period : 'monthly';
            window.open(API_BASE + '/reports/export/csv?period=' + period, '_blank');
        }

        var reportChartInstance = null;

        function initReportChart() {
            var ctx = document.getElementById('reportChart');
            if (!ctx) return;
            if (reportChartInstance) reportChartInstance.destroy();

            var labels = ['1-may', '3-may', '5-may', '7-may', '9-may', '11-may', '13-may', '15-may'];
            var data = [320000, 480000, 290000, 550000, 410000, 620000, 380000, 510000];

            reportChartInstance = new Chart(ctx, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Tushum',
                        data: data,
                        borderColor: '#10B981',
                        backgroundColor: 'rgba(16, 185, 129, 0.1)',
                        fill: true,
                        tension: 0.4,
                        borderWidth: 2,
                        pointRadius: 4,
                        pointBackgroundColor: '#10B981',
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    plugins: { legend: { display: false } },
                    scales: {
                        x: { grid: { display: false }, ticks: { font: { size: 11 } } },
                        y: { grid: { color: '#F3F4F6' }, ticks: { font: { size: 11 }, callback: function(v) { return (v / 1000) + 'k'; } } }
                    }
                }
            });
        }

        // ===== GLOBAL SEARCH =====
        document.getElementById('globalSearch').addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                var query = e.target.value.trim().toLowerCase();
                if (!query) return;
                showToast('"' + query + '" bo\'yicha qidirilmoqda...', 'info');
            }
        });

        // ===== USER ANALYTICS =====
        async function renderUserAnalytics() {
            mainContent.innerHTML = '<div class="page-header"><h1 class="page-title">Foydalanuvchi odatlari</h1></div><div class="card"><div class="card-body">Yuklanmoqda...</div></div>';
            
            try {
                const r = await api(API_BASE + '/analytics/user-insights');
                if (!r || !r.ok) throw new Error();
                const data = await r.json();

                let html = '<div class="page-header">' +
                    '<h1 class="page-title">Foydalanuvchi odatlari va statistikasi</h1>' +
                    '<p class="page-subtitle">Umumiy anonimlashtirilgan xatti-harakatlar tahlili</p>' +
                    '</div>';
                
                // Top cards
                html += '<div style="display:grid; grid-template-columns: repeat(auto-fit, minmax(240px, 1fr)); gap:24px; margin-bottom:24px;">' +
                    '<div class="stat-card"><div class="stat-title">O\'rtacha bozorlik xarajati</div><div class="stat-value text-success">' + formatMoney(data.shopping.avg_price) + '</div><div class="stat-desc">' + data.shopping.total_lists + ' ta ro\'yxat asosida</div></div>' +
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
        
        // ===== USER DATA =====
        async function renderUserDataTodos() {
            mainContent.innerHTML = '<div class="page-header"><h1 class="page-title">Kundalik rejalar</h1></div><div class="card"><div class="card-body">Yuklanmoqda...</div></div>';
            var html = '<div class="page-header"><h1 class="page-title">Kundalik rejalar (Todos)</h1><p class="page-subtitle">Platformadagi barcha foydalanuvchi rejalari</p></div>';
            html += '<div class="card"><div class="table-container"><table class="table"><thead><tr><th>ID</th><th>Foydalanuvchi</th><th>Sarlavha</th><th>Holati</th><th>Sana</th></tr></thead><tbody id="todosTableBody"></tbody></table></div></div>';
            mainContent.innerHTML = html;
            try {
                const res = await api(API_BASE + '/user-data/todos');
                if (res.ok) {
                    var data = await res.json();
                    var tbody = document.getElementById('todosTableBody');
                    if (data.length === 0) tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;padding:20px;">Ma\'lumot yo\'q</td></tr>';
                    else {
                        tbody.innerHTML = data.map(function(t) {
                            return '<tr>' +
                                '<td>#' + t.id + '</td>' +
                                '<td><div style="font-weight:600;">' + t.user_name + '</div></td>' +
                                '<td>' + (t.title || '-') + '</td>' +
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
                const res = await api(API_BASE + '/user-data/shopping');
                if (res.ok) {
                    var data = await res.json();
                    var tbody = document.getElementById('shoppingTableBody');
                    if (data.length === 0) tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:20px;">Ma\'lumot yo\'q</td></tr>';
                    else {
                        tbody.innerHTML = data.map(function(s) {
                            return '<tr>' +
                                '<td>#' + s.id + '</td>' +
                                '<td><div style="font-weight:600;">' + s.user_name + '</div></td>' +
                                '<td>' + (s.name || '-') + '</td>' +
                                '<td>' + s.item_count + ' ta</td>' +
                                '<td>' + formatMoney(s.total_estimated_price) + '</td>' +
                                '<td>' + formatMoney(s.total_actual_price) + '</td>' +
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
                const res = await api(API_BASE + '/user-data/finance');
                if (res.ok) {
                    var data = await res.json();
                    var tbody = document.getElementById('financeTableBody');
                    if (data.length === 0) tbody.innerHTML = '<tr><td colspan="7" style="text-align:center;padding:20px;">Ma\'lumot yo\'q</td></tr>';
                    else {
                        tbody.innerHTML = data.map(function(f) {
                            return '<tr>' +
                                '<td>#' + f.id + '</td>' +
                                '<td><div style="font-weight:600;">' + f.user_name + '</div></td>' +
                                '<td><span class="status-badge ' + (f.type === 'income' ? 'status-success' : 'status-danger') + '">' + (f.type === 'income' ? 'Daromad' : 'Xarajat') + '</span></td>' +
                                '<td>' + (f.category || '-') + '</td>' +
                                '<td style="font-weight:bold;color:' + (f.type === 'income' ? 'var(--success)' : 'var(--danger)') + ';">' + formatMoney(f.amount) + '</td>' +
                                '<td>' + (f.note || '-') + '</td>' +
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
                const res = await api(API_BASE + '/user-data/plans');
                if (res.ok) {
                    var data = await res.json();
                    var tbody = document.getElementById('plansTableBody');
                    if (data.length === 0) tbody.innerHTML = '<tr><td colspan="6" style="text-align:center;padding:20px;">Ma\'lumot yo\'q</td></tr>';
                    else {
                        tbody.innerHTML = data.map(function(p) {
                            return '<tr>' +
                                '<td>#' + p.id + '</td>' +
                                '<td><div style="font-weight:600;">' + p.user_name + '</div></td>' +
                                '<td>' + (p.title || '-') + '</td>' +
                                '<td>' + (p.description || '-') + '</td>' +
                                '<td>' + (p.date ? p.date.substring(0,10) : '') + ' ' + (p.time ? p.time.substring(0,5) : '') + '</td>' +
                                '<td><span class="status-badge ' + (p.is_completed ? 'status-success' : 'status-warning') + '">' + (p.is_completed ? 'Bajarilgan' : 'Bajarilmagan') + '</span></td>' +
                            '</tr>';
                        }).join('');
                    }
                }
            } catch(e) { console.error(e); }
        }

        // ===== PAGE: PRODUCTS CATALOG =====
        let productsPage = 1;
        let productsData = { items: [], total: 0, pages: 1 };

        async function renderProducts(page) {
            if (page === undefined) page = 1;
            productsPage = page;
            var search = '';
            var searchEl = document.getElementById('productSearch');
            if (searchEl) search = searchEl.value;

            let url = API_BASE + '/products?page=' + page + '&per_page=20';
            if (search) url += '&search=' + encodeURIComponent(search);

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Mahsulotlar katalogi</h1>' +
                    '<p class="page-subtitle">Aqlli bozorlik mahsulotlari va o\'rtacha narxlarni boshqarish</p>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-header">' +
                        '<div class="filters-bar" style="margin-bottom:0; width:100%;">' +
                            '<div class="filter-search">' +
                                '<span class="search-icon">&#128269;</span>' +
                                '<input type="text" placeholder="Mahsulot nomi bo\'yicha qidirish..." id="productSearch" value="' + (search || '') + '">' +
                            '</div>' +
                            '<button class="btn btn-primary" onclick="openAddProductModal()">+ Yangi mahsulot</button>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card-body no-padding">' +
                        '<div class="table-container">' +
                            '<table class="data-table" id="productsTable">' +
                                '<thead><tr><th>ID</th><th>Nomi</th><th>O\'lchov birligi</th><th>O\'rtacha narx</th><th>Amallar</th></tr></thead>' +
                                '<tbody id="productsTableBody"><tr><td colspan="5" style="text-align:center;padding:20px;">Yuklanmoqda...</td></tr></tbody>' +
                            '</table>' +
                        '</div>' +
                    '</div>' +
                    '<div class="pagination">' +
                        '<span class="pagination-info" id="productsCount">0 ta mahsulot</span>' +
                        '<div class="pagination-buttons" id="productsPagination"></div>' +
                    '</div>' +
                '</div>';

            var productSearchEl = document.getElementById('productSearch');
            var searchTimeout;
            productSearchEl.addEventListener('input', function() {
                clearTimeout(searchTimeout);
                searchTimeout = setTimeout(function() { renderProducts(1); }, 400);
            });

            await fetchAndRenderProductRows(url);
        }

        async function fetchAndRenderProductRows(url) {
            try {
                const r = await api(url);
                if (r && r.ok) {
                    productsData = await r.json();
                    var tbody = document.getElementById('productsTableBody');
                    var countEl = document.getElementById('productsCount');
                    var pagEl = document.getElementById('productsPagination');

                    countEl.textContent = productsData.total + ' ta mahsulot';
                    pagEl.innerHTML = renderPagination(productsData.pages, productsPage, 'renderProducts');

                    if (!productsData.items || productsData.items.length === 0) {
                        tbody.innerHTML = '<tr><td colspan="5" style="text-align:center;color:var(--gray-400);padding:40px;">Mahsulotlar topilmadi</td></tr>';
                        return;
                    }

                    tbody.innerHTML = productsData.items.map(function(p) {
                        return '<tr>' +
                            '<td>' + p.id + '</td>' +
                            '<td style="font-weight:600;">' + p.name + '</td>' +
                            '<td>' + p.unit + '</td>' +
                            '<td style="font-weight:bold;color:var(--success);">' + (p.average_price > 0 ? formatMoney(p.average_price) : 'Kiritilmagan') + '</td>' +
                            '<td><div class="action-group">' +
                                '<button class="btn btn-sm btn-secondary" title="Tarix" onclick="viewPriceHistory(' + p.id + ')">&#128338; Tarix</button>' +
                                '<button class="btn btn-sm btn-secondary" title="Narx qo\'shish" style="color:var(--info)" onclick="openAddPriceModal(' + p.id + ')">+ Narx</button>' +
                                '<button class="btn btn-sm btn-secondary" title="AI Estimation" style="color:var(--orange)" onclick="runAiEstimation(' + p.id + ')">&#129302; AI</button>' +
                                '<button class="btn-icon danger" title="O\'chirish" onclick="deleteProduct(' + p.id + ')">&#128465;</button>' +
                            '</div></td>' +
                        '</tr>';
                    }).join('');
                } else {
                    apiError('Mahsulotlarni yuklab bo\'lmadi');
                }
            } catch(e) {
                apiError('Mahsulotlarni yuklab bo\'lmadi');
            }
        }

        function openAddProductModal() {
            var bodyHtml = 
                '<div class="form-group">' +
                    '<label class="form-label">Mahsulot nomi</label>' +
                    '<input type="text" class="form-input" id="newProdName" placeholder="Masalan: Olma, Banan, Pepsi...">' +
                '</div>' +
                '<div class="form-group">' +
                    '<label class="form-label">O\'lchov birligi</label>' +
                    '<select class="form-input" id="newProdUnit">' +
                        '<option value="kg">kg</option>' +
                        '<option value="dona">dona</option>' +
                        '<option value="litr">litr</option>' +
                        '<option value="bog\'">bog\'</option>' +
                    '</select>' +
                '</div>' +
                '<div class="form-group">' +
                    '<label class="form-label">Boshlang\'ich o\'rtacha narx (so\'m, ixtiyoriy)</label>' +
                    '<input type="number" class="form-input" id="newProdPrice" value="0">' +
                '</div>';
            var footerHtml = 
                '<button class="btn btn-secondary" onclick="closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveNewProduct()">Saqlash</button>';
            openModal('Yangi mahsulot qo\'shish', bodyHtml, footerHtml);
        }

        async function saveNewProduct() {
            var name = document.getElementById('newProdName').value.trim();
            var unit = document.getElementById('newProdUnit').value;
            var price = parseFloat(document.getElementById('newProdPrice').value) || 0.0;

            if (!name) { showToast('Mahsulot nomini kiriting', 'error'); return; }

            try {
                const r = await api('/api/v1/admin/products/', {
                    method: 'POST',
                    body: JSON.stringify({ name: name, unit: unit, average_price: price })
                });
                if (r && r.ok) {
                    showToast('Mahsulot muvaffaqiyatli qo\'shildi');
                    closeModal();
                    renderProducts(productsPage);
                } else {
                    const data = await r.json();
                    showToast(data.detail || 'Qo\'shib bo\'lmadi', 'error');
                }
            } catch(e) { showToast('Xatolik yuz berdi', 'error'); }
        }

        async function deleteProduct(id) {
            if (!confirm('Haqiqatdan ham bu mahsulotni o\'chirmoqchimisiz? Narxlar tarixi ham o\'chib ketadi.')) return;
            try {
                const r = await api('/api/v1/admin/products/' + id, { method: 'DELETE' });
                if (r && r.ok) {
                    showToast('Mahsulot o\'chirildi', 'error');
                    renderProducts(productsPage);
                } else { showToast('O\'chirishda xatolik yuz berdi', 'error'); }
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        function openAddPriceModal(id) {
            var bodyHtml = 
                '<div class="form-group">' +
                    '<label class="form-label">Bozordagi yangi narx (so\'m)</label>' +
                    '<input type="number" class="form-input" id="manualPriceVal" placeholder="Masalan: 12000">' +
                '</div>';
            var footerHtml = 
                '<button class="btn btn-secondary" onclick="closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveAdminPrice(' + id + ')">Saqlash</button>';
            openModal('Bozor narxini kiritish', bodyHtml, footerHtml);
        }

        async function saveAdminPrice(id) {
            var price = parseFloat(document.getElementById('manualPriceVal').value) || 0.0;
            if (price <= 0) { showToast('Narx 0 dan katta bo\'lishi kerak', 'error'); return; }

            try {
                const r = await api('/api/v1/admin/products/' + id + '/price', {
                    method: 'POST',
                    body: JSON.stringify({ source_type: 'admin', price: price })
                });
                if (r && r.ok) {
                    showToast('Yangi narx kiritildi va o\'rtacha narx qayta hisoblandi');
                    closeModal();
                    renderProducts(productsPage);
                } else { showToast('Narxni kiritib bo\'lmadi', 'error'); }
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        async function runAiEstimation(id) {
            showToast('AI narx baholash boshlandi...', 'info');
            try {
                const r = await api('/api/v1/admin/products/' + id + '/ai-estimate', { method: 'POST' });
                if (r && r.ok) {
                    const data = await r.json();
                    showToast('AI narxi: ' + formatMoney(data.estimated_price) + ' qilib belgilandi va o\'rtacha narx yangilandi');
                    renderProducts(productsPage);
                } else { showToast('AI baholashda xatolik', 'error'); }
            } catch(e) { showToast('Xatolik', 'error'); }
        }

        function viewPriceHistory(id) {
            var p = productsData.items.find(x => x.id === id);
            if (!p) return;

            var entries = p.price_entries || [];
            var sourceBadges = { 
                admin: '<span class="badge-status confirmed">Admin</span>', 
                ai: '<span class="badge-status in_progress">AI</span>', 
                user: '<span class="badge-status active">Foydalanuvchi</span>' 
            };

            var tableRows = entries.map(function(e) {
                return '<tr>' +
                    '<td>' + (sourceBadges[e.source_type] || e.source_type) + '</td>' +
                    '<td style="font-weight:bold;">' + formatMoney(e.price) + '</td>' +
                    '<td>' + formatDate(e.created_at) + '</td>' +
                '</tr>';
            }).join('');

            var bodyHtml = 
                '<div style="margin-bottom:12px;font-size:14px;">' +
                    'Mahsulot: <b>' + p.name + '</b> (' + p.unit + ')<br>' +
                    'Hozirgi o\'rtacha narx: <b style="color:var(--success);">' + (p.average_price > 0 ? formatMoney(p.average_price) : 'Kiritilmagan') + '</b>' +
                '</div>' +
                '<div class="table-container" style="max-height:300px;overflow-y:auto;">' +
                    '<table class="data-table">' +
                        '<thead><tr><th>Manba</th><th>Narx (birlik uchun)</th><th>Sana</th></tr></thead>' +
                        '<tbody>' + (tableRows || '<tr><td colspan="3" style="text-align:center;padding:16px;">Tarix topilmadi</td></tr>') + '</tbody>' +
                    '</table>' +
                '</div>';

            var footerHtml = '<button class="btn btn-secondary" onclick="closeModal()">Yopish</button>';
            openModal('Narxlar tarixi va manbalar', bodyHtml, footerHtml);
        }

        // ===== INIT =====
        renderPage('dashboard');
        lucide.createIcons();