import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: REVIEWS =====
        let reviewsData = { items: [], total: 0, pages: 1 };

        async function renderReviews(page) {
            if (page === undefined) page = 1;
            let url = window.API_BASE + '/reviews?page=' + page + '&per_page=20';
            try {
                const r = await window.api(url);
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
                    '<td><div class="table-user"><div class="table-avatar">' + window.getInitials(r.user_name || r.user || '?') + '</div><span>' + (r.user_name || r.user || '-') + '</span></div></td>' +
                    '<td>' + (r.provider_name || r.provider || '-') + '</td>' +
                    '<td>' + window.renderStars(r.rating) + '</td>' +
                    '<td style="max-width:300px;">' + (r.comment || r.text || '') + '</td>' +
                    '<td>' + window.formatDate(r.created_at) + '</td>' +
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
                window.api(window.API_BASE + '/reviews/' + id, { method: 'DELETE' }).then(function(r) {
                    if (r && (r.ok || r.status === 204)) {
                        window.showToast('Sharh o\'chirildi', 'error');
                        renderReviews();
                    } else {
                        window.showToast('O\'chirib bo\'lmadi', 'error');
                    }
                });
            }
        }

        
        

// Exports for ES6 modules
export { renderReviews, filterReviews, renderReviewRowsApi, deleteReview, renderReviewRows };
// Expose to window for inline onclick handlers
window.renderReviews = renderReviews;
window.filterReviews = filterReviews;
window.renderReviewRowsApi = renderReviewRowsApi;
window.deleteReview = deleteReview;
window.renderReviewRows = renderReviewRows;
