import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: SETTINGS =====
        async function renderSettings() {
            var f = { commission_rate: 15, cashback_rate: 2, currency: 'UZS', min_withdrawal: 100000, maintenance_mode: false, registration_open: true, support_phone: '+998 71 200 00 00', support_telegram: '@superapp_support' };
            try {
                const r = await window.api(window.API_BASE + '/settings');
                if (r && r.ok) f = await r.json();
            } catch(e) {}
            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Sozlamalar</h1>' +
                    '<p class="page-subtitle">Platforma parametrlarini boshqarish</p>' +
                '</div>' +
                '<div class="card">' +
                    '<div class="card-body">' +
                        '<div class="settings-section">' +
                            '<h3 class="settings-section-title">Tizim sozlamalari</h3>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Maintenance rejimi</div>' +
                                    '<div class="setting-description">Yoqilganda platforma vaqtinchalik to\'xtatiladi</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<label class="toggle-switch">' +
                                        '<input type="checkbox" id="settingMaintenance"' + (f.maintenance_mode ? ' checked' : '') + '>' +
                                        '<span class="toggle-slider"></span>' +
                                    '</label>' +
                                '</div>' +
                            '</div>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Registratsiya ochiq</div>' +
                                    '<div class="setting-description">Yangi foydalanuvchilar ro\'yxatdan o\'tishi mumkin</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<label class="toggle-switch">' +
                                        '<input type="checkbox" id="settingRegistration"' + (f.registration_open !== false ? ' checked' : '') + '>' +
                                        '<span class="toggle-slider"></span>' +
                                    '</label>' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                        '<div class="settings-section">' +
                            '<h3 class="settings-section-title">Qo\'llab-quvvatlash</h3>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Support telefon</div>' +
                                    '<div class="setting-description">Mijozlar uchun qo\'llab-quvvatlash raqami</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<input type="text" class="form-input" id="settingSupportPhone" value="' + (f.support_phone || '+998 71 200 00 00') + '" style="width:200px;">' +
                                '</div>' +
                            '</div>' +
                            '<div class="setting-row">' +
                                '<div class="setting-info">' +
                                    '<div class="setting-label">Support Telegram</div>' +
                                    '<div class="setting-description">Telegram support kanali yoki bot</div>' +
                                '</div>' +
                                '<div class="setting-control">' +
                                    '<input type="text" class="form-input" id="settingSupportTelegram" value="' + (f.support_telegram || '@superapp_support') + '" style="width:200px;">' +
                                '</div>' +
                            '</div>' +
                        '</div>' +
                        '<div style="padding-top:16px;">' +
                            '<button class="btn btn-primary" onclick="saveSettings()">&#128190; Saqlash</button>' +
                        '</div>' +
                    '</div>' +
                '</div>';
        }

        function saveSettings() {
            var payload = {
                maintenance_mode: document.getElementById('settingMaintenance').checked,
                registration_open: document.getElementById('settingRegistration').checked,
                support_phone: document.getElementById('settingSupportPhone').value,
                support_telegram: document.getElementById('settingSupportTelegram').value
            };
            window.api(window.API_BASE + '/settings', {
                method: 'PATCH',
                body: JSON.stringify(payload)
            }).then(function(r) {
                if (r && r.ok) {
                    window.showToast('Sozlamalar muvaffaqiyatli saqlandi');
                } else {
                    window.showToast('Saqlab bo\'lmadi', 'error');
                }
            });
        }

        

// Exports for ES6 modules
export { saveSettings, renderSettings };
// Expose to window for inline onclick handlers
window.saveSettings = saveSettings;
window.renderSettings = renderSettings;
