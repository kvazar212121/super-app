import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from './api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from './ui.js';
import { navigateTo, renderPage } from './router.js';

// ===== GLOBAL SEARCH =====
        document.getElementById('globalSearch').addEventListener('keydown', function(e) {
            if (e.key === 'Enter') {
                var query = e.target.value.trim().toLowerCase();
                if (!query) return;
                window.showToast('"' + query + '" bo\'yicha qidirilmoqda...', 'info');
            }
        });

        