import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from './api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from './ui.js';

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
            window.renderPage(page);
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
                premium: renderPremium,
                support: renderSupport,
                admins: renderAdmins,
            };
            if (renderers[page]) {
                await renderers[page]();
                if (page === 'dashboard') setTimeout(function() { initDashboardCharts(); }, 50);
            }
        }

        

// Exports for ES6 modules
export { navigateTo, renderPage };
// Expose to window for inline onclick handlers
window.navigateTo = navigateTo;
window.renderPage = renderPage;
