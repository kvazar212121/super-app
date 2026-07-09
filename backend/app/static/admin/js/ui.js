import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from './api.js';

// ===== UTILITY FUNCTIONS =====
        // XSS himoyasi: innerHTML'ga qo'yiladigan har qanday foydalanuvchi ma'lumotini escape qiladi
        function escapeHtml(v) {
            if (v === null || v === undefined) return '';
            return String(v)
                .replace(/&/g, '&amp;')
                .replace(/</g, '&lt;')
                .replace(/>/g, '&gt;')
                .replace(/"/g, '&quot;')
                .replace(/'/g, '&#39;');
        }

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

        document.getElementById('modalClose').addEventListener('click', window.closeModal);
        document.getElementById('modalOverlay').addEventListener('click', function(e) {
            if (e.target === e.currentTarget) window.closeModal();
        });

        

// Exports for ES6 modules
export { escapeHtml, statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast };
// Expose to window for inline onclick handlers
window.escapeHtml = escapeHtml;
window.statusBadge = statusBadge;
window.openModal = openModal;
window.formatMoney = formatMoney;
window.formatDate = formatDate;
window.closeModal = closeModal;
window.getInitials = getInitials;
window.renderStars = renderStars;
window.showToast = showToast;
