import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

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
            var cats = window.categoriesCache;

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
                            '<span class="variant-price">' + window.formatMoney(v.base_price) + '</span>' +
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
            window.openModal('Yangi kategoriya qo\'shish',
                '<div class="form-group"><label class="form-label">Kalit (key)</label><input type="text" class="form-input" id="catKey" placeholder="masalan: elektr"></div>' +
                '<div class="form-group"><label class="form-label">Nomi (o\'zbekcha)</label><input type="text" class="form-input" id="catTitle" placeholder="masalan: Elektrik xizmatlari"></div>' +
                '<div class="form-row">' +
                    '<div class="form-group"><label class="form-label">Icon (emoji)</label><input type="text" class="form-input" id="catIcon" placeholder="&#9889;"></div>' +
                    '<div class="form-group"><label class="form-label">Rang</label><input type="color" class="form-input" id="catColor" value="#6366F1" style="height:40px; padding:4px;"></div>' +
                '</div>',
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveCategory()">Saqlash</button>');
        }

        function saveCategory() {
            var key = document.getElementById('catKey').value.trim();
            var title = document.getElementById('catTitle').value.trim();
            var icon = document.getElementById('catIcon').value || '&#128194;';
            var color = document.getElementById('catColor').value;
            if (!key || !title) { window.showToast('Kalit va nomi majburiy', 'error'); return; }
            window.api(window.API_BASE + '/categories', {
                method: 'POST',
                body: JSON.stringify({ key: key, title_uz: title, icon: icon, accent_color: color })
            }).then(function(r) {
                if (r && r.ok) {
                    window.showToast('Kategoriya qo\'shildi');
                    window.closeModal();
                    renderCategories();
                } else {
                    window.showToast('Xatolik yuz berdi', 'error');
                }
            });
        }

        function editCategoryModal(idx) {
            var c = window.categoriesCache[idx];
            if (!c) return;
            window.openModal('Kategoriyani tahrirlash',
                '<div class="form-group"><label class="form-label">Kalit (key)</label><input type="text" class="form-input" id="catKey" value="' + c.key + '"></div>' +
                '<div class="form-group"><label class="form-label">Nomi (o\'zbekcha)</label><input type="text" class="form-input" id="catTitle" value="' + c.title_uz + '"></div>' +
                '<div class="form-row">' +
                    '<div class="form-group"><label class="form-label">Icon (emoji)</label><input type="text" class="form-input" id="catIcon" value="' + c.icon + '"></div>' +
                    '<div class="form-group"><label class="form-label">Rang</label><input type="color" class="form-input" id="catColor" value="' + c.accent_color + '" style="height:40px; padding:4px;"></div>' +
                '</div>',
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="updateCategory(' + idx + ', ' + c.id + ')">Saqlash</button>');
        }

        function updateCategory(idx, catId) {
            var payload = {
                key: document.getElementById('catKey').value.trim(),
                title_uz: document.getElementById('catTitle').value.trim(),
                icon: document.getElementById('catIcon').value,
                accent_color: document.getElementById('catColor').value
            };
            window.api(window.API_BASE + '/categories/' + catId, {
                method: 'PATCH',
                body: JSON.stringify(payload)
            }).then(function(r) {
                if (r && r.ok) {
                    window.showToast('Kategoriya yangilandi');
                    window.closeModal();
                    renderCategories();
                } else {
                    window.showToast('Xatolik yuz berdi', 'error');
                }
            });
        }

        function deleteCategory(idx, catId) {
            if (!catId) { window.showToast('Kategoriya ID topilmadi', 'error'); return; }
            if (confirm('Bu kategoriyani o\'chirmoqchimisiz?')) {
                window.api(window.API_BASE + '/categories/' + catId, { method: 'DELETE' }).then(function(r) {
                    if (r && (r.ok || r.status === 204)) {
                        window.showToast('Kategoriya o\'chirildi', 'error');
                        renderCategories();
                    } else {
                        window.showToast('O\'chirib bo\'lmadi', 'error');
                    }
                });
            }
        }

        function addVariantModal(catIdx, catId) {
            window.openModal('Yangi variant qo\'shish',
                '<div class="form-group"><label class="form-label">Variant nomi</label><input type="text" class="form-input" id="varLabel" placeholder="masalan: Rozetka o\'rnatish"></div>' +
                '<div class="form-group"><label class="form-label">Boshlang\'ich narx (so\'m)</label><input type="number" class="form-input" id="varPrice" placeholder="50000"></div>',
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveVariant(' + catIdx + ', ' + catId + ')">Saqlash</button>');
        }

        function saveVariant(catIdx, catId) {
            var label = document.getElementById('varLabel').value.trim();
            var price = parseInt(document.getElementById('varPrice').value);
            if (!label || !price) { window.showToast('Nomi va narx majburiy', 'error'); return; }
            window.api(window.API_BASE + '/categories/' + catId + '/variants', {
                method: 'POST',
                body: JSON.stringify({ label_uz: label, base_price: price })
            }).then(function(r) {
                if (r && r.ok) {
                    window.showToast('Variant qo\'shildi');
                    window.closeModal();
                    renderCategories();
                } else {
                    window.showToast('Xatolik yuz berdi', 'error');
                }
            });
        }

        function editVariantModal(catIdx, varId) {
            var cat = window.categoriesCache[catIdx];
            if (!cat) return;
            var v = (cat.variants || []).find(function(x) { return x.id === varId; });
            if (!v) return;
            window.openModal('Variantni tahrirlash',
                '<div class="form-group"><label class="form-label">Variant nomi</label><input type="text" class="form-input" id="varLabel" value="' + (v.label_uz || v.label) + '"></div>' +
                '<div class="form-group"><label class="form-label">Boshlang\'ich narx (so\'m)</label><input type="number" class="form-input" id="varPrice" value="' + v.base_price + '"></div>',
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="updateVariant(' + catIdx + ', ' + cat.id + ', ' + varId + ')">Saqlash</button>');
        }

        function updateVariant(catIdx, catId, varId) {
            var payload = {
                label_uz: document.getElementById('varLabel').value.trim(),
                base_price: parseInt(document.getElementById('varPrice').value)
            };
            window.api(window.API_BASE + '/categories/' + catId + '/variants/' + varId, {
                method: 'PATCH',
                body: JSON.stringify(payload)
            }).then(function(r) {
                if (r && r.ok) {
                    window.showToast('Variant yangilandi');
                    window.closeModal();
                    renderCategories();
                } else {
                    window.showToast('Xatolik yuz berdi', 'error');
                }
            });
        }

        function deleteVariant(catIdx, catId, varId) {
            if (confirm('Bu variantni o\'chirmoqchimisiz?')) {
                window.api(window.API_BASE + '/categories/' + catId + '/variants/' + varId, { method: 'DELETE' }).then(function(r) {
                    if (r && (r.ok || r.status === 204)) {
                        window.showToast('Variant o\'chirildi', 'error');
                        renderCategories();
                    } else {
                        window.showToast('O\'chirib bo\'lmadi', 'error');
                    }
                });
            }
        }

        

// Exports for ES6 modules
export { updateCategory, deleteVariant, updateVariant, getCategoryEmoji, toggleCategory, editCategoryModal, deleteCategory, addVariantModal, editVariantModal, saveCategory, saveVariant, addCategoryModal, renderCategories };
// Expose to window for inline onclick handlers
window.updateCategory = updateCategory;
window.deleteVariant = deleteVariant;
window.updateVariant = updateVariant;
window.getCategoryEmoji = getCategoryEmoji;
window.toggleCategory = toggleCategory;
window.editCategoryModal = editCategoryModal;
window.deleteCategory = deleteCategory;
window.addVariantModal = addVariantModal;
window.editVariantModal = editVariantModal;
window.saveCategory = saveCategory;
window.saveVariant = saveVariant;
window.addCategoryModal = addCategoryModal;
window.renderCategories = renderCategories;
