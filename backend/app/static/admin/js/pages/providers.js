import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: PROVIDERS =====
        let providersPage = 1;
        let providersData = { items: [], total: 0, pages: 1 };
        window.categoriesCache = [];

        async function loadCategoriesCache() {
            if (window.categoriesCache && window.categoriesCache.length > 0) return window.categoriesCache;
            try {
                const r = await window.api(window.API_BASE + '/categories');
                if (r && r.ok) window.categoriesCache = await r.json();
            } catch(e) {
                window.categoriesCache = []; apiError('Kategoriyalarni yuklab bo\'lmadi');
            }
            return window.categoriesCache;
        }

        async function renderProviders(page) {
            if (page === undefined) page = 1;
            providersPage = page;
            await loadCategoriesCache();

            var search = '';
            var searchEl = document.getElementById('providerSearch');
            if (searchEl) search = searchEl.value;

            let url = window.API_BASE + '/providers?page=' + page + '&per_page=20';
            if (search) url += '&search=' + encodeURIComponent(search);
            var statusFilterEl = document.getElementById('providerStatusFilter');
            var statusFilter = statusFilterEl ? statusFilterEl.value : '';
            if (statusFilter === 'pending') url += '&is_active=false';
            else if (statusFilter === 'active') url += '&is_active=true';

            try {
                const r = await window.api(url);
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
                                '<input type="text" placeholder="Nomi yoki telefon bo\'yicha qidirish..." id="providerSearch" value="' + window.escapeHtml(search || '') + '">' +
                            '</div>' +
                            '<select class="filter-select" id="providerCategoryFilter">' +
                                '<option value="all">Barcha kategoriyalar</option>' +
                                window.categoriesCache.map(function(c) { return '<option value="' + window.escapeHtml(c.key) + '">' + window.escapeHtml(c.title_uz) + '</option>'; }).join('') +
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
                var actions = '<button class="btn-icon" title="Ko\'rish / KYC" onclick="viewProviderKyc(' + p.id + ')">&#128065;</button>';
                if (providerNeedsApproval(p)) {
                    actions += '<button class="btn-icon" title="Tasdiqlash" style="color:var(--success)" onclick="approveProvider(' + p.id + ')">&#10003;</button>';
                    actions += '<button class="btn-icon danger" title="Rad etish" onclick="rejectProvider(' + p.id + ')">&#10007;</button>';
                }
                actions += '<button class="btn-icon" title="Verified" style="color:#7c3aed" onclick="verifyProvider(' + p.id + ')">&#10004;</button>';
                if (p.is_blocked) {
                    actions += '<button class="btn-icon" title="Blokni olish" style="color:var(--success)" onclick="unblockProvider(' + p.id + ')">&#128275;</button>';
                } else {
                    actions += '<button class="btn-icon danger" title="Bloklash" onclick="blockProvider(' + p.id + ')">&#128683;</button>';
                }
                actions += '<button class="btn-icon danger" title="O\'chirish" onclick="deleteProvider(' + p.id + ')">&#128465;</button>';
                return '<tr>' +
                    '<td>' + p.id + '</td>' +
                    '<td><div class="table-user"><div class="table-avatar">' + window.getInitials(p.name) + '</div><span>' + window.escapeHtml(p.name) + (typeLabel ? '<br><small style="color:#64748b">' + typeLabel + '</small>' : '') + '</span></div></td>' +
                    '<td>' + window.escapeHtml(p.category_title || p.category_key || '-') + '</td>' +
                    '<td>' + window.escapeHtml(p.phone) + '</td>' +
                    '<td>' + window.renderStars(Math.round(p.rating || 0)) + ' ' + (p.rating || 0) + '</td>' +
                    '<td>' + window.statusBadge(status) + '</td>' +
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
                    (subs ? '<div class="detail-item"><div class="detail-label">Fanlar / kurslar</div><div class="detail-value">' + window.escapeHtml(subs) + '</div></div>' : '') +
                    (modes ? '<div class="detail-item"><div class="detail-label">Dars formati</div><div class="detail-value">' + window.escapeHtml(modes) + '</div></div>' : '') +
                    '<div class="detail-item"><div class="detail-label">Tasdiqlash</div><div class="detail-value">' + (meta.verification_status || (p.is_active ? 'verified' : 'pending')) + '</div></div>';
            }
            if (meta.type === 'nanny') {
                extra = '<div class="detail-item"><div class="detail-label">Tasdiqlash</div><div class="detail-value">' + (meta.verification_status || 'pending') + '</div></div>';
            }
            if (meta.type === 'disinfection') {
                var areas = (meta.area_types || []).join(', ');
                extra = '<div class="detail-item"><div class="detail-label">Turi</div><div class="detail-value">Dezinfeksiya xizmati</div></div>' +
                    (areas ? '<div class="detail-item"><div class="detail-label">Hudud turlari</div><div class="detail-value">' + window.escapeHtml(areas) + '</div></div>' : '') +
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
                    (vm ? '<div class="detail-item"><div class="detail-label">Qabul usuli</div><div class="detail-value">' + window.escapeHtml(vm) + '</div></div>' : '') +
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
                    (ot ? '<div class="detail-item"><div class="detail-label">Xizmatlar</div><div class="detail-value">' + window.escapeHtml(ot) + '</div></div>' : '') +
                    (vt ? '<div class="detail-item"><div class="detail-label">Joy turlari</div><div class="detail-value">' + window.escapeHtml(vt) + '</div></div>' : '') +
                    '<div class="detail-item"><div class="detail-label">Hudud</div><div class="detail-value">' + window.escapeHtml(meta.service_area || '-') + '</div></div>' +
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
                    (meta.service_area ? '<div class="detail-item"><div class="detail-label">Hudud</div><div class="detail-value">' + window.escapeHtml(meta.service_area) + '</div></div>' : '') +
                    (meta.qualifications ? '<div class="detail-item"><div class="detail-label">Malaka</div><div class="detail-value">' + window.escapeHtml(meta.qualifications) + '</div></div>' : '') +
                    (medTypes ? '<div class="detail-item"><div class="detail-label">Tibbiy xizmatlar</div><div class="detail-value">' + window.escapeHtml(medTypes) + '</div></div>' : '') +
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
                '<div class="detail-item"><div class="detail-label">Nomi</div><div class="detail-value">' + window.escapeHtml(p.name) + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Kategoriya</div><div class="detail-value">' + window.escapeHtml(p.category_title || p.category || '-') + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Telefon</div><div class="detail-value">' + window.escapeHtml(p.phone) + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Manzil</div><div class="detail-value">' + window.escapeHtml(p.address || '-') + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Holat</div><div class="detail-value">' + window.statusBadge(providerDisplayStatus(p)) + '</div></div>' +
                '<div class="detail-item"><div class="detail-label">Reyting</div><div class="detail-value">' + (p.rating || 0) + ' ' + window.renderStars(Math.round(p.rating || 0)) + '</div></div>' +
                extra +
                '<div class="detail-item" style="grid-column:1/-1; margin-top: 10px; border-top: 1px solid #e2e8f0; padding-top: 10px;">' +
                    '<div class="detail-label">Maxsus Komissiya (Mijoz topilganlik uchun)</div>' +
                    '<div class="detail-value">' +
                        '<input type="number" id="editProviderLeadFee_' + p.id + '" class="form-input" style="width: 150px; display: inline-block; margin-right: 10px;" value="' + (p.lead_fee || '') + '" placeholder="Standart 5000"> ' +
                        '<button class="btn btn-primary btn-sm" onclick="saveProviderLeadFee(' + p.id + ')">Saqlash</button>' +
                        '<p style="font-size: 11px; color: #64748b; margin-top: 4px;">Bo\'sh qoldirilsa tizimning standart komissiyasi olinadi.</p>' +
                    '</div>' +
                '</div>' +
            '</div>';
        }

        async function viewProvider(id) {
            var p = providersData.items.find(function(x) { return x.id === id; });
            if (!p) return;
            var footer = '<button class="btn btn-secondary" onclick="window.closeModal()">Yopish</button>';
            if (providerNeedsApproval(p)) {
                footer = '<button class="btn btn-primary" onclick="approveProvider(' + p.id + '); window.closeModal();">Tasdiqlash</button>' +
                    '<button class="btn btn-secondary" onclick="rejectProvider(' + p.id + '); window.closeModal();">Rad etish</button>' + footer;
            }
            window.openModal('Soha egasi ma\'lumotlari', providerDetailHtml(p), footer);
        }

        function editProvider(id) {
            viewProvider(id);
        }

        function saveProvider(id) {
            window.closeModal();
        }

        async function saveProviderLeadFee(id) {
            var input = document.getElementById('editProviderLeadFee_' + id);
            if (!input) return;
            var val = input.value;
            var payload = { lead_fee: val ? parseFloat(val) : null };
            try {
                const r = await window.api(window.API_BASE + '/providers/' + id, {
                    method: 'PATCH',
                    body: JSON.stringify(payload)
                });
                if (r && r.ok) {
                    window.showToast('Maxsus komissiya saqlandi');
                    renderProviders(providersPage);
                    window.closeModal();
                } else {
                    window.showToast('Saqlashda xatolik', 'error');
                }
            } catch (e) {
                window.showToast('Xatolik yuz berdi', 'error');
            }
        }

        async function approveProvider(id) {
            try {
                await window.api(window.API_BASE + '/providers/' + id + '/approve', { method: 'PATCH' });
                window.showToast('Soha egasi tasdiqlandi'); renderProviders();
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        async function rejectProvider(id) {
            if (!confirm('Bu soha egasini rad etmoqchimisiz?')) return;
            try {
                await window.api(window.API_BASE + '/providers/' + id + '/reject', { method: 'PATCH' });
                window.showToast('Soha egasi rad etildi', 'warning'); renderProviders();
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        async function deleteProvider(id) {
            if (!confirm('Rostdan ham bu soha egasini o\'chirmoqchimisiz?')) return;
            try {
                await window.api(window.API_BASE + '/providers/' + id, { method: 'DELETE' });
                window.showToast('Soha egasi o\'chirildi', 'error'); renderProviders();
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        

// Exports for ES6 modules
        function _providerAction(id, path, label) {
            window.api(window.API_BASE + '/providers/' + id + path, { method: 'PATCH' }).then(function(r) {
                window.showToast(r && r.ok ? label : 'Xatolik', r && r.ok ? 'success' : 'error');
                if (r && r.ok && window.renderProviders) window.renderProviders();
            });
        }
        function verifyProvider(id) { _providerAction(id, '/verify', 'Tasdiqlandi (verified) ✅'); }
        function blockProvider(id) { if (confirm('Provayderni bloklaysizmi? Ilovada ko\'rinmaydi.')) _providerAction(id, '/block', 'Bloklandi'); }
        function unblockProvider(id) { _providerAction(id, '/unblock', 'Blok olindi'); }
        async function viewProviderKyc(id) {
            try {
                var r = await window.api(window.API_BASE + '/providers/' + id + '/kyc');
                if (!r || !r.ok) { window.showToast('KYC yuklanmadi', 'error'); return; }
                var d = await r.json();
                var docs = d.documents || {};
                var docHtml = Object.keys(docs).length
                    ? Object.keys(docs).map(function(k) {
                        var v = docs[k];
                        var val = (typeof v === 'string' && v.indexOf('http') === 0)
                            ? '<a href="' + v + '" target="_blank">Faylni ochish</a>'
                            : window.escapeHtml(String(v));
                        return '<div class="detail-item"><div class="detail-label">' + window.escapeHtml(k) + '</div><div class="detail-value">' + val + '</div></div>';
                    }).join('')
                    : '<p>Hujjat yuklanmagan</p>';
                var html = '<div style="margin-bottom:10px;">' +
                    '<b>Holat:</b> ' + (d.is_blocked ? '🚫 Bloklangan' : (d.is_verified ? '✅ Tasdiqlangan' : '⏳ Tasdiqlanmagan')) +
                    ' | <b>verification:</b> ' + (d.verification_status || '—') + '</div>' + docHtml;
                window.openModal('KYC / Hujjatlar — ' + (d.name || ''), html, '');
            } catch (e) { window.showToast('Xatolik', 'error'); }
        }
        window.verifyProvider = verifyProvider;
        window.blockProvider = blockProvider;
        window.unblockProvider = unblockProvider;
        window.viewProviderKyc = viewProviderKyc;

export { providerMeta, renderProviderRowsApi, filterProviders, rejectProvider, providerDetailHtml, deleteProvider, renderProviderRows, saveProvider, providerNeedsApproval, editProvider, providerDisplayStatus, loadCategoriesCache, saveProviderLeadFee, renderProviders, approveProvider, viewProvider, verifyProvider, blockProvider, unblockProvider, viewProviderKyc };
// Expose to window for inline onclick handlers
window.providerMeta = providerMeta;
window.renderProviderRowsApi = renderProviderRowsApi;
window.filterProviders = filterProviders;
window.rejectProvider = rejectProvider;
window.providerDetailHtml = providerDetailHtml;
window.deleteProvider = deleteProvider;
window.renderProviderRows = renderProviderRows;
window.saveProvider = saveProvider;
window.providerNeedsApproval = providerNeedsApproval;
window.editProvider = editProvider;
window.providerDisplayStatus = providerDisplayStatus;
window.loadCategoriesCache = loadCategoriesCache;
window.saveProviderLeadFee = saveProviderLeadFee;
window.renderProviders = renderProviders;
window.approveProvider = approveProvider;
window.viewProvider = viewProvider;
