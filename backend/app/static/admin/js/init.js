import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from './api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from './ui.js';
import { navigateTo, renderPage } from './router.js';

// ===== INIT =====
        window.renderPage('dashboard');
        lucide.createIcons();