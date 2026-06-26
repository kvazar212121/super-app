import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: PROMOS & BANNERS =====
        async function renderPromos() {
            var promos = [];
            try {
                const r = await window.api(window.API_BASE + '/promos');
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
                const r = await window.api(window.API_BASE + '/promos', {
                    method: 'POST',
                    body: JSON.stringify({ title, subtitle, badge, colors, image_url: image_url || null })
                });
                if (r && r.ok) {
                    window.showToast('Yangi aksiya banneri qo\'shildi');
                    renderPromos();
                } else {
                    apiError('Banner qo\'shib bo\'lmadi');
                }
            } catch(e) { apiError('Banner qo\'shib bo\'lmadi'); }
        }

        async function deletePromo(id) {
            if (!confirm('Ushbu aksiyani o\'chirishni xohlaysizmi?')) return;
            try {
                const r = await window.api(window.API_BASE + '/promos/' + id, {
                    method: 'DELETE'
                });
                if (r && r.ok) {
                    window.showToast('Aksiya o\'chirildi');
                    renderPromos();
                } else {
                    apiError('O\'chirib bo\'lmadi');
                }
            } catch(e) { apiError('O\'chirib bo\'lmadi'); }
        }

        

// Exports for ES6 modules
export { createPromo, renderPromos, deletePromo };
// Expose to window for inline onclick handlers
window.createPromo = createPromo;
window.renderPromos = renderPromos;
window.deletePromo = deletePromo;
