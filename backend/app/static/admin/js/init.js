import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from './api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from './ui.js';
import { navigateTo, renderPage } from './router.js';

// ===== INIT: ruxsatga qarab sidebar va sahifa =====
// data-page -> ruxsat bo'limi
var PAGE_SECTION = {
    dashboard: 'dashboard', users: 'users', providers: 'providers', orders: 'orders',
    categories: 'categories', products: 'products', promos: 'promos', reviews: 'reviews',
    reports: 'reports', user_analytics: 'reports', finance: 'finance', settings: 'settings',
    notifications: 'notifications', premium: 'premium', admins: 'admins'
};

// Sahifada tugmalarni yashirish uchun global yordamchi (backend baribir tekshiradi)
window.canEdit = function (section) {
    var me = window.__adminMe;
    if (!me) return true;
    if (me.is_super_admin) return true;
    var p = (me.permissions || {})[section] || [];
    return p.indexOf('edit') !== -1;
};

(async function initAdmin() {
    var me = null;
    try {
        var r = await window.api(window.API_BASE + '/me');
        if (r && r.ok) me = await r.json();
    } catch (e) {}
    window.__adminMe = me;

    var isSuper = me && me.is_super_admin;
    var perms = (me && me.permissions) || {};
    var firstAllowed = null;

    // Topbar'da admin ismi va roli
    var roleEl = document.getElementById('topbarRole');
    if (roleEl && me) {
        var label = isSuper ? 'Super Admin' : (me.role_name || 'Admin');
        var nm = ((me.name || '') + ' ' + (me.surname || '')).trim();
        roleEl.textContent = nm ? (nm + ' · ' + label) : label;
    }

    document.querySelectorAll('.nav-item[data-page]').forEach(function (item) {
        var page = item.dataset.page;
        var section = PAGE_SECTION[page] || page;
        var canView = isSuper || ((perms[section] || []).indexOf('view') !== -1);
        if (!canView) {
            item.style.display = 'none';
        } else if (!firstAllowed) {
            firstAllowed = page;
        }
    });

    window.renderPage(firstAllowed || 'dashboard');
    if (window.lucide) lucide.createIcons();

    // Nav badge'larni boshlanishда bir marta yuklaymiz (dashboardga kirmasa ham
    // kutayotgan buyurtma/provayder/murojaat sonlari ko'rinsin).
    _loadInitialNavBadges();
})();

async function _loadInitialNavBadges() {
    if (typeof window.updateNavBadges !== 'function') return;
    var orders = 0, providers = 0, support = 0;
    try {
        var r = await window.api(window.API_BASE + '/stats');
        if (r && r.ok) {
            var s = await r.json();
            orders = (s.orders_by_status && s.orders_by_status.pending) || 0;
            providers = s.pending_providers || 0;
        }
    } catch (e) {}
    try {
        var tk = await window.api(window.API_BASE + '/support/tickets?status=open');
        if (tk && tk.ok) {
            var td = await tk.json();
            support = (td.tickets || td.items || td || []).length || 0;
        }
    } catch (e) {}
    window.updateNavBadges({ orders: orders, providers: providers, support: support });
}
