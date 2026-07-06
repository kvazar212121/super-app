import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: PRODUCTS CATALOG =====
        let productsPage = 1;
        let productsData = { items: [], total: 0, pages: 1 };

        async function renderProducts(page) {
            if (page === undefined) page = 1;
            productsPage = page;
            var search = '';
            var searchEl = document.getElementById('productSearch');
            if (searchEl) search = searchEl.value;

            let url = window.API_BASE + '/products?page=' + page + '&per_page=20';
            if (search) url += '&search=' + encodeURIComponent(search);

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Mahsulotlar katalogi</h1>' +
                    '<p class="page-subtitle">Aqlli bozorlik mahsulotlari va o\'rtacha narxlarni boshqarish</p>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-header">' +
                        '<div class="filters-bar" style="margin-bottom:0; width:100%; display:flex; justify-content:space-between; align-items:center;">' +
                            '<div class="filter-search" style="flex-grow:1; max-width:400px;">' +
                                '<span class="search-icon">&#128269;</span>' +
                                '<input type="text" placeholder="Mahsulot nomi bo\'yicha qidirish..." id="productSearch" value="' + (search || '') + '">' +
                            '</div>' +
                            '<div style="display:flex; gap:10px;">' +
                                '<button class="btn btn-secondary" onclick="runMarketScraper()" id="btnRunScraper">🔄 Bozor narxlarini avto-yangilash</button>' +
                                '<button class="btn btn-primary" onclick="openAddProductModal()">+ Yangi mahsulot</button>' +
                            '</div>' +
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
                const r = await window.api(url);
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
                            '<td style="font-weight:bold;color:var(--success);">' + (p.average_price > 0 ? window.formatMoney(p.average_price) : 'Kiritilmagan') + '</td>' +
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
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveNewProduct()">Saqlash</button>';
            window.openModal('Yangi mahsulot qo\'shish', bodyHtml, footerHtml);
        }

        async function saveNewProduct() {
            var name = document.getElementById('newProdName').value.trim();
            var unit = document.getElementById('newProdUnit').value;
            var price = parseFloat(document.getElementById('newProdPrice').value) || 0.0;

            if (!name) { window.showToast('Mahsulot nomini kiriting', 'error'); return; }

            try {
                const r = await window.api(window.API_BASE + '/products/', {
                    method: 'POST',
                    body: JSON.stringify({ name: name, unit: unit, average_price: price })
                });
                if (r && r.ok) {
                    window.showToast('Mahsulot muvaffaqiyatli qo\'shildi');
                    window.closeModal();
                    renderProducts(productsPage);
                } else {
                    const data = await r.json();
                    window.showToast(data.detail || 'Qo\'shib bo\'lmadi', 'error');
                }
            } catch(e) { window.showToast('Xatolik yuz berdi', 'error'); }
        }

        async function deleteProduct(id) {
            if (!confirm('Haqiqatdan ham bu mahsulotni o\'chirmoqchimisiz? Narxlar tarixi ham o\'chib ketadi.')) return;
            try {
                const r = await window.api(window.API_BASE + '/products/' + id, { method: 'DELETE' });
                if (r && r.ok) {
                    window.showToast('Mahsulot o\'chirildi', 'error');
                    renderProducts(productsPage);
                } else { window.showToast('O\'chirishda xatolik yuz berdi', 'error'); }
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        function openAddPriceModal(id) {
            var bodyHtml = 
                '<div class="form-group">' +
                    '<label class="form-label">Bozordagi yangi narx (so\'m)</label>' +
                    '<input type="number" class="form-input" id="manualPriceVal" placeholder="Masalan: 12000">' +
                '</div>';
            var footerHtml = 
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveAdminPrice(' + id + ')">Saqlash</button>';
            window.openModal('Bozor narxini kiritish', bodyHtml, footerHtml);
        }

        async function saveAdminPrice(id) {
            var price = parseFloat(document.getElementById('manualPriceVal').value) || 0.0;
            if (price <= 0) { window.showToast('Narx 0 dan katta bo\'lishi kerak', 'error'); return; }

            try {
                const r = await window.api(window.API_BASE + '/products/' + id + '/price', {
                    method: 'POST',
                    body: JSON.stringify({ source_type: 'admin', price: price })
                });
                if (r && r.ok) {
                    window.showToast('Yangi narx kiritildi va o\'rtacha narx qayta hisoblandi');
                    window.closeModal();
                    renderProducts(productsPage);
                } else { window.showToast('Narxni kiritib bo\'lmadi', 'error'); }
            } catch(e) { window.showToast('Xatolik', 'error'); }
        }

        async function savePriceEntry() {
            var priceEl = document.getElementById('newPriceValue');
            var price = parseFloat(priceEl.value);
            if (!price || isNaN(price)) {
                showToast("Iltimos, narxni to'g'ri kiriting", "error");
                return;
            }

            try {
                const res = await api('/products/' + currentProductId + '/price', {
                    method: 'POST',
                    body: JSON.stringify({ price: price })
                });
                closePriceModal();
                showToast("Narx qo'shildi", "success");
                renderProducts(productsPage);
            } catch (err) {
                console.error(err);
                showToast("Xatolik: " + err.message, "error");
            }
        }

        async function runMarketScraper() {
            const btn = document.getElementById('btnRunScraper');
            if (btn) {
                btn.disabled = true;
                btn.innerHTML = 'Kuting...';
            }
            try {
                const res = await api('/products/run-scraper', {
                    method: 'POST'
                });
                showToast(res.message + ` (Yangi: ${res.new_count}, Yangilandi: ${res.updated_count})`, "success");
                renderProducts(productsPage);
            } catch (err) {
                console.error(err);
                showToast("Xatolik: " + err.message, "error");
            } finally {
                if (btn) {
                    btn.disabled = false;
                    btn.innerHTML = '🔄 Bozor narxlarini avto-yangilash';
                }
            }
        }

        async function runAiEstimation(id) {
            window.showToast('AI narx baholash boshlandi...', 'info');
            try {
                const r = await window.api(window.API_BASE + '/products/' + id + '/ai-estimate', { method: 'POST' });
                if (r && r.ok) {
                    const data = await r.json();
                    window.showToast('AI narxi: ' + window.formatMoney(data.estimated_price) + ' qilib belgilandi va o\'rtacha narx yangilandi');
                    renderProducts(productsPage);
                } else { window.showToast('AI baholashda xatolik', 'error'); }
            } catch(e) { window.showToast('Xatolik', 'error'); }
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
                    '<td style="font-weight:bold;">' + window.formatMoney(e.price) + '</td>' +
                    '<td>' + window.formatDate(e.created_at) + '</td>' +
                '</tr>';
            }).join('');

            var bodyHtml = 
                '<div style="margin-bottom:12px;font-size:14px;">' +
                    'Mahsulot: <b>' + p.name + '</b> (' + p.unit + ')<br>' +
                    'Hozirgi o\'rtacha narx: <b style="color:var(--success);">' + (p.average_price > 0 ? window.formatMoney(p.average_price) : 'Kiritilmagan') + '</b>' +
                '</div>' +
                '<div class="table-container" style="max-height:300px;overflow-y:auto;">' +
                    '<table class="data-table">' +
                        '<thead><tr><th>Manba</th><th>Narx (birlik uchun)</th><th>Sana</th></tr></thead>' +
                        '<tbody>' + (tableRows || '<tr><td colspan="3" style="text-align:center;padding:16px;">Tarix topilmadi</td></tr>') + '</tbody>' +
                    '</table>' +
                '</div>';

            var footerHtml = '<button class="btn btn-secondary" onclick="window.closeModal()">Yopish</button>';
            window.openModal('Narxlar tarixi va manbalar', bodyHtml, footerHtml);
        }

        

// Exports for ES6 modules
export { openAddProductModal, runAiEstimation, deleteProduct, viewPriceHistory, fetchAndRenderProductRows, openAddPriceModal, renderProducts, saveAdminPrice, saveNewProduct, runMarketScraper };
// Expose to window for inline onclick handlers
window.openAddProductModal = openAddProductModal;
window.runAiEstimation = runAiEstimation;
window.deleteProduct = deleteProduct;
window.viewPriceHistory = viewPriceHistory;
window.fetchAndRenderProductRows = fetchAndRenderProductRows;
window.openAddPriceModal = openAddPriceModal;
window.renderProducts = renderProducts;
window.saveAdminPrice = saveAdminPrice;
window.saveNewProduct = saveNewProduct;
window.runMarketScraper = runMarketScraper;

// Export for router
export default {
    render: renderProducts
};
