import { API_BASE, apiError, api, getAuthHeaders, emptyPage, logout } from '../api.js';
import { statusBadge, openModal, formatMoney, formatDate, closeModal, getInitials, renderStars, showToast } from '../ui.js';
import { navigateTo, renderPage } from '../router.js';

// ===== PAGE: FINANCE =====
        async function renderFinance() {
            var f = { total_topup: 0, total_lead_fee: 0, total_premium: 0, total_admin_withdraw: 0, net_profit: 0 };
            try {
                const r = await window.api(window.API_BASE + '/finance/stats');
                if (r && r.ok) f = await r.json();
            } catch(e) {}

            var providerOptions = '';
            var providersTableRows = '';
            try {
                const pr = await window.api(window.API_BASE + '/finance/providers');
                if (pr && pr.ok) {
                    var pdata = await pr.json();
                    providerOptions = pdata.map(function(p) {
                        return '<option value="' + p.id + '">' + window.escapeHtml(p.name) + ' (Balans: ' + window.formatMoney(p.balance) + ')</option>';
                    }).join('');
                    
                    providersTableRows = pdata.map(function(p) {
                        var balColor = p.balance < 0 ? 'var(--red-600)' : 'var(--green-600)';
                        return '<tr>' +
                            '<td>#' + p.id + '</td>' +
                            '<td>' + window.escapeHtml(p.name) + '</td>' +
                            '<td>' + window.escapeHtml(p.phone) + '</td>' +
                            '<td><strong style="color:' + balColor + '">' + window.formatMoney(p.balance) + '</strong></td>' +
                            '<td>' + (p.lead_fee ? window.formatMoney(p.lead_fee) : 'Standart (5 000)') + '</td>' +
                            '</tr>';
                    }).join('');
                }
            } catch(e) {}

            var txRows = '';
            try {
                const tr = await window.api(window.API_BASE + '/finance/transactions?per_page=15');
                if (tr && tr.ok) {
                    var tdata = await tr.json();
                    txRows = (tdata.items || []).map(function(t) {
                        var tType = t.type;
                        if(tType==='topup') tType='Balans to\'ldirish';
                        else if(tType==='topup_bonus') tType='Top-up Bonus';
                        else if(tType==='lead_fee') tType='Lead Fee (Komissiya)';
                        else if(tType==='premium_subscription') tType='Premium Obuna';
                        else if(tType==='admin_withdraw') tType='Platforma Xarajati';
                        
                        var amtColor = t.amount < 0 ? 'var(--red-600)' : 'var(--green-600)';
                        var userProv = t.provider_name ? ('Prov: '+window.escapeHtml(t.provider_name)) : (t.user_name ? ('Mijoz: '+window.escapeHtml(t.user_name)) : '—');
                        return '<tr>' +
                            '<td>' + window.formatDate(t.created_at) + '</td>' +
                            '<td>' + window.escapeHtml(tType) + '</td>' +
                            '<td>' + userProv + '</td>' +
                            '<td><strong style="color:' + amtColor + '">' + window.formatMoney(t.amount) + '</strong></td>' +
                            '<td>' + window.escapeHtml(t.description || '—') + '</td>' +
                            '</tr>';
                    }).join('');
                }
            } catch(e) {}

            var rulesHtml = '';
            try {
                const rls = await window.api(window.API_BASE + '/finance/bonus-rules');
                if (rls && rls.ok) {
                    var rules = await rls.json();
                    window._financeBonusRules = rules;
                    rulesHtml = rules.map(function(r, idx) {
                        return '<div style="margin-bottom:8px;font-size:13px;padding:8px;background:var(--gray-50);border-radius:4px;">' +
                            '<b>#' + (idx+1) + ':</b> ' + window.formatMoney(r.min_amount) + ' dan ' + window.formatMoney(r.max_amount) + ' gacha -> <b>' + window.formatMoney(r.bonus_amount) + ' bonus</b>' +
                            '</div>';
                    }).join('');
                }
            } catch(e) {}

            var categoriesHtml = '';
            try {
                const cr = await window.api(window.API_BASE + '/categories');
                if (cr && cr.ok) {
                    var cdata = await cr.json();
                    categoriesHtml = cdata.map(function(cat) {
                        return '<tr>' +
                            '<td><b>' + window.escapeHtml(cat.title_uz) + '</b></td>' +
                            '<td>' + (cat.lead_fee ? window.formatMoney(cat.lead_fee) : 'Standart (5 000)') + '</td>' +
                            '<td><button class="btn btn-sm btn-secondary" onclick="openCategoryFeeModal(' + cat.id + ', ' + (cat.lead_fee || 0) + ')">Narx belgilash</button></td>' +
                            '</tr>';
                    }).join('');
                }
            } catch(e) {}

            mainContent.innerHTML =
                '<div class="page-header">' +
                    '<h1 class="page-title">Moliya (Yangi Tizim)</h1>' +
                    '<p class="page-subtitle">Platforma daromadlari, komissiyalar va xarajatlar</p>' +
                '</div>' +
                '<div class="stats-grid">' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Jami Top-up (Kirim)</span>' +
                            '<div class="stat-card-icon green">&#128200;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + window.formatMoney(f.total_topup) + '</div>' +
                        '<span class="stat-card-change up">Mijoz/Usta hisob to\'ldirishi</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Sof Foyda (Daromad)</span>' +
                            '<div class="stat-card-icon purple">&#128176;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + window.formatMoney(f.net_profit) + '</div>' +
                        '<span class="stat-card-change up">Komissiya + Premium - Xarajat</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Premium Obunalar</span>' +
                            '<div class="stat-card-icon orange">&#11088;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + window.formatMoney(f.total_premium) + '</div>' +
                        '<span class="stat-card-change up">Mijozlar to\'lagan</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Platforma Xarajati (Yechish)</span>' +
                            '<div class="stat-card-icon blue">&#128184;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + window.formatMoney(f.total_admin_withdraw) + '</div>' +
                        '<span class="stat-card-change down">O\'zimiz yechib olgan</span>' +
                    '</div>' +
                '</div>' +
                
                '<div class="finance-actions-grid" style="display:grid; grid-template-columns: repeat(3, 1fr); gap:16px; margin-top:28px;">' +
                    '<button class="finance-action-btn" onclick="openFinancePanel(\'providers\')" style="background:#fff;border:2px solid #e5e7eb;border-radius:16px;padding:24px 20px;cursor:pointer;text-align:left;transition:all .2s;box-shadow:0 1px 4px rgba(0,0,0,.07);">' +
                        '<div style="font-size:28px;margin-bottom:10px;">👤</div>' +
                        '<div style="font-weight:700;font-size:15px;color:#1a1a2e;margin-bottom:4px;">Ustalar Hisobi</div>' +
                        '<div style="font-size:12px;color:#888;">Balans va Lead fee ko\'rish</div>' +
                    '</button>' +
                    '<button class="finance-action-btn" onclick="openFinancePanel(\'categories\')" style="background:#fff;border:2px solid #e5e7eb;border-radius:16px;padding:24px 20px;cursor:pointer;text-align:left;transition:all .2s;box-shadow:0 1px 4px rgba(0,0,0,.07);">' +
                        '<div style="font-size:28px;margin-bottom:10px;">🏷️</div>' +
                        '<div style="font-weight:700;font-size:15px;color:#1a1a2e;margin-bottom:4px;">Sohalar Komissiyasi</div>' +
                        '<div style="font-size:12px;color:#888;">Har bir soha uchun narx</div>' +
                    '</button>' +
                    '<button class="finance-action-btn" onclick="openFinancePanel(\'transactions\')" style="background:#fff;border:2px solid #e5e7eb;border-radius:16px;padding:24px 20px;cursor:pointer;text-align:left;transition:all .2s;box-shadow:0 1px 4px rgba(0,0,0,.07);">' +
                        '<div style="font-size:28px;margin-bottom:10px;">📋</div>' +
                        '<div style="font-weight:700;font-size:15px;color:#1a1a2e;margin-bottom:4px;">Tranzaksiyalar Tarixi</div>' +
                        '<div style="font-size:12px;color:#888;">So\'nggi to\'lovlar</div>' +
                    '</button>' +
                    '<button class="finance-action-btn" onclick="openFinancePanel(\'withdraw\')" style="background:#fff;border:2px solid #fecaca;border-radius:16px;padding:24px 20px;cursor:pointer;text-align:left;transition:all .2s;box-shadow:0 1px 4px rgba(0,0,0,.07);">' +
                        '<div style="font-size:28px;margin-bottom:10px;">💸</div>' +
                        '<div style="font-weight:700;font-size:15px;color:#dc2626;margin-bottom:4px;">Xarajat / Yechish</div>' +
                        '<div style="font-size:12px;color:#888;">Platformadan pul yechish</div>' +
                    '</button>' +
                    '<button class="finance-action-btn" onclick="openFinancePanel(\'premium\')" style="background:#fff;border:2px solid #fed7aa;border-radius:16px;padding:24px 20px;cursor:pointer;text-align:left;transition:all .2s;box-shadow:0 1px 4px rgba(0,0,0,.07);">' +
                        '<div style="font-size:28px;margin-bottom:10px;">⭐</div>' +
                        '<div style="font-weight:700;font-size:15px;color:#ea580c;margin-bottom:4px;">Premium Tushum</div>' +
                        '<div style="font-size:12px;color:#888;">Premium to\'lovlarni qayd etish</div>' +
                    '</button>' +
                    '<button class="finance-action-btn" onclick="openFinancePanel(\'bonus\')" style="background:#fff;border:2px solid #bbf7d0;border-radius:16px;padding:24px 20px;cursor:pointer;text-align:left;transition:all .2s;box-shadow:0 1px 4px rgba(0,0,0,.07);">' +
                        '<div style="font-size:28px;margin-bottom:10px;">🎁</div>' +
                        '<div style="font-weight:700;font-size:15px;color:#16a34a;margin-bottom:4px;">Bonus Qoidalari</div>' +
                        '<div style="font-size:12px;color:#888;">Top-up bonus chegaralari</div>' +
                    '</button>' +
                '</div>' +

                '<div id="financePanelOverlay" onclick="closeFinancePanel()" style="display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:1000;"></div>' +
                '<div id="financePanel" style="display:none;position:fixed;top:0;right:0;width:780px;max-width:96vw;height:100vh;background:#fff;z-index:1001;box-shadow:-8px 0 40px rgba(0,0,0,.18);overflow-y:auto;padding:32px;">' +
                    '<button onclick="closeFinancePanel()" style="position:absolute;top:18px;right:18px;background:none;border:none;font-size:22px;cursor:pointer;color:#555;">✕</button>' +
                    '<div id="financePanelContent"></div>' +
                '</div>';

            window._financeProvidersHtml = providersTableRows;
            window._financeCategoriesHtml = categoriesHtml;
            window._financeTxRows = txRows;
            window._financeRulesHtml = rulesHtml;

            document.querySelectorAll('.finance-action-btn').forEach(function(btn) {
                btn.addEventListener('mouseenter', function() {
                    this.style.borderColor = '#6366f1';
                    this.style.boxShadow = '0 4px 20px rgba(99,102,241,.15)';
                    this.style.transform = 'translateY(-2px)';
                });
                btn.addEventListener('mouseleave', function() {
                    this.style.borderColor = this.dataset.color || '#e5e7eb';
                    this.style.boxShadow = '0 1px 4px rgba(0,0,0,.07)';
                    this.style.transform = '';
                });
            });
        }

        function openFinancePanel(type) {
            var overlay = document.getElementById('financePanelOverlay');
            var panel = document.getElementById('financePanel');
            var content = document.getElementById('financePanelContent');
            if (!panel) return;

            var html = '';
            if (type === 'providers') {
                html = '<h2 style="margin-bottom:20px;font-size:20px;">👤 Ustalar Hisobi</h2>' +
                    '<div style="overflow-x:auto;"><table class="data-table" style="width:100%;">' +
                    '<thead><tr><th>ID</th><th>Ism</th><th>Telefon</th><th>Balans</th><th>Maxsus Fee</th></tr></thead>' +
                    '<tbody>' + (window._financeProvidersHtml || '<tr><td colspan="5">Topilmadi</td></tr>') + '</tbody>' +
                    '</table></div>';
            } else if (type === 'categories') {
                html = '<h2 style="margin-bottom:20px;font-size:20px;">🏷️ Sohalar Komissiyasi</h2>' +
                    '<p style="margin-bottom:16px;color:#666;font-size:13px;">Har bir soha (Sartarosh, Santexnik...) uchun yagona narx belgilang. Shu sohaga tegishli barcha ustalardan o\'sha narx yechiladi.</p>' +
                    '<div style="overflow-x:auto;"><table class="data-table" style="width:100%;">' +
                    '<thead><tr><th>Soha nomi</th><th>Har bir mijoz uchun narx</th><th>Amallar</th></tr></thead>' +
                    '<tbody>' + (window._financeCategoriesHtml || '<tr><td colspan="3">Topilmadi</td></tr>') + '</tbody>' +
                    '</table></div>';
            } else if (type === 'transactions') {
                html = '<h2 style="margin-bottom:20px;font-size:20px;">📋 Tranzaksiyalar Tarixi</h2>' +
                    '<div style="overflow-x:auto;"><table class="data-table" style="width:100%;">' +
                    '<thead><tr><th>Sana</th><th>Turi</th><th>Shaxs</th><th>Summa</th><th>Izoh</th></tr></thead>' +
                    '<tbody>' + (window._financeTxRows || '<tr><td colspan="5">Tranzaksiyalar topilmadi</td></tr>') + '</tbody>' +
                    '</table></div>';
            } else if (type === 'withdraw') {
                html = '<h2 style="margin-bottom:20px;font-size:20px;color:#dc2626;">💸 Xarajat / Yechish</h2>' +
                    '<div style="max-width:420px;">' +
                    '<div class="form-group"><label class="form-label">Summa (som)</label><input type="number" class="form-input" id="withdrawAmount"></div>' +
                    '<div class="form-group"><label class="form-label">Izoh (Nimaga)</label><input type="text" class="form-input" id="withdrawNote"></div>' +
                    '<button class="btn btn-primary" onclick="submitWithdraw()" style="width:100%;background:#dc2626;border-color:#dc2626;padding:14px;">Xarajat qilish / Yechish</button>' +
                    '</div>';
            } else if (type === 'premium') {
                html = '<h2 style="margin-bottom:20px;font-size:20px;color:#ea580c;">⭐ Premium Tushum Qayd Etish</h2>' +
                    '<div style="max-width:420px;">' +
                    '<div class="form-group"><label class="form-label">Summa (som)</label><input type="number" class="form-input" id="premiumAmount" value="20000"></div>' +
                    '<div class="form-group"><label class="form-label">Izoh</label><input type="text" class="form-input" id="premiumNote" value="1 oylik premium"></div>' +
                    '<button class="btn btn-primary" onclick="submitPremium()" style="width:100%;background:#ea580c;border-color:#ea580c;padding:14px;">Tushumni Qo\'shish</button>' +
                    '</div>';
            } else if (type === 'bonus') {
                var existingRulesCards = window._financeBonusRules && window._financeBonusRules.length > 0
                    ? window._financeBonusRules.map(function(r, i) {
                        return '<div style="display:flex;align-items:center;gap:12px;padding:12px 16px;background:#f0fdf4;border:1px solid #bbf7d0;border-radius:10px;margin-bottom:8px;">' +
                            '<span style="font-size:18px;">🎁</span>' +
                            '<span style="flex:1;font-size:13px;"><b>' + window.formatMoney(r.min_amount) + '</b> dan <b>' + window.formatMoney(r.max_amount) + '</b> gacha → <b style="color:#16a34a;">' + window.formatMoney(r.bonus_amount) + ' bonus</b></span>' +
                            '<button onclick="deleteBonusRule(' + i + ')" style="background:none;border:none;color:#dc2626;font-size:18px;cursor:pointer;padding:2px 6px;">✕</button>' +
                        '</div>';
                    }).join('')
                    : '<p style="color:#888;font-size:13px;margin-bottom:16px;">Hali qoidalar yo\'q</p>';

                html = '<h2 style="margin-bottom:6px;font-size:20px;color:#16a34a;">🎁 Bonus Qoidalari</h2>' +
                    '<p style="color:#666;font-size:13px;margin-bottom:20px;">Soha egasi hisobiga qancha pul topamlganida qancha bonus berish qoidalarini belgilang.</p>' +

                    '<h4 style="margin-bottom:10px;font-size:14px;color:#333;">Mavjud qoidalar</h4>' +
                    '<div id="existingRulesContainer" style="margin-bottom:24px;">' + existingRulesCards + '</div>' +

                    '<h4 style="margin-bottom:10px;font-size:14px;color:#333;">Yangi qoidalar qo\'shish</h4>' +
                    '<div id="bonusRulesForm">' +
                        '<div class="bonus-rule-row" style="display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:10px;align-items:end;margin-bottom:8px;">' +
                            '<div><label style="font-size:11px;color:#888;display:block;margin-bottom:4px;">Min summa (so\'m)</label><input type="number" class="form-input br-min" placeholder="100 000"></div>' +
                            '<div><label style="font-size:11px;color:#888;display:block;margin-bottom:4px;">Max summa (so\'m)</label><input type="number" class="form-input br-max" placeholder="500 000"></div>' +
                            '<div><label style="font-size:11px;color:#888;display:block;margin-bottom:4px;">Bonus miqdori (so\'m)</label><input type="number" class="form-input br-bonus" placeholder="10 000"></div>' +
                            '<button onclick="this.closest(\'.bonus-rule-row\').remove()" style="background:none;border:1px solid #fca5a5;border-radius:6px;color:#dc2626;padding:8px 12px;cursor:pointer;font-size:16px;">✕</button>' +
                        '</div>' +
                    '</div>' +
                    '<div style="display:flex;gap:10px;margin-top:12px;">' +
                        '<button onclick="addBonusRuleRow()" class="btn btn-secondary btn-sm">+ Yana qator qo\'shish</button>' +
                        '<button onclick="saveBonusRules()" class="btn btn-primary" style="background:#16a34a;border-color:#16a34a;">💾 Hammasini Saqlash</button>' +
                    '</div>';
            }

            content.innerHTML = html;
            overlay.style.display = 'block';
            panel.style.display = 'block';
            panel.style.transform = 'translateX(100%)';
            requestAnimationFrame(function() {
                panel.style.transition = 'transform .3s cubic-bezier(.4,0,.2,1)';
                panel.style.transform = 'translateX(0)';
            });
        }

        function closeFinancePanel() {
            var overlay = document.getElementById('financePanelOverlay');
            var panel = document.getElementById('financePanel');
            panel.style.transform = 'translateX(100%)';
            setTimeout(function() {
                overlay.style.display = 'none';
                panel.style.display = 'none';
            }, 300);
        }

        function openCategoryFeeModal(id, currentFee) {
            var val = (currentFee && currentFee > 0) ? currentFee : '';
            window.openModal('Soha uchun komissiya narxi',
                '<p style="margin-bottom:12px;color:#666;">Ushbu sohada (masalan: barcha sartaroshlar) har bir kelgan mijoz uchun yechib olinadigan narxni belgilang. Bosh qoldiring yoki 0 yozing - standart narx (5000) ishlaydi.</p>' +
                '<div class="form-group">' +
                    '<label class="form-label">Summa (som)</label>' +
                    '<input type="number" id="catFeeInput" class="form-input" value="' + val + '" placeholder="Masalan: 7000">' +
                    '<input type="hidden" id="catFeeId" value="' + id + '">' +
                '</div>',
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveCategoryFee()">Saqlash</button>'
            );
        }

        async function saveCategoryFee() {
            var id = document.getElementById('catFeeId').value;
            var fee = parseFloat(document.getElementById('catFeeInput').value);
            var payload = { lead_fee: isNaN(fee) || fee <= 0 ? null : fee };

            try {
                const r = await window.api(window.API_BASE + '/categories/' + id, {
                    method: 'PATCH',
                    body: JSON.stringify(payload)
                });
                if (r && r.ok) {
                    window.showToast('Komissiya narxi muvaffaqiyatli saqlandi');
                    window.closeModal();
                    renderFinance();
                } else {
                    window.showToast('Xatolik yuz berdi', 'error');
                }
            } catch (e) {
                window.showToast('Tarmoq xatosi', 'error');
            }
        }

        async function submitWithdraw() {
            var amt = document.getElementById('withdrawAmount').value;
            var note = document.getElementById('withdrawNote').value;
            if(!amt) return;
            const r = await window.api(window.API_BASE + '/finance/admin-withdraw', {
                method: 'POST', body: JSON.stringify({amount: parseFloat(amt), note: note})
            });
            if(r && r.ok) { window.showToast('Pul yechib olindi (Xarajat)'); renderFinance(); } else { window.showToast('Xatolik', 'error'); }
        }

        async function submitPremium() {
            var amt = document.getElementById('premiumAmount').value;
            var note = document.getElementById('premiumNote').value;
            if(!amt) return;
            const r = await window.api(window.API_BASE + '/finance/premium-purchase', {
                method: 'POST', body: JSON.stringify({amount: parseFloat(amt), note: note})
            });
            if(r && r.ok) { window.showToast('Premium tushum qo\'shildi'); renderFinance(); } else { window.showToast('Xatolik', 'error'); }
        }

        function showBonusRuleModal() {
            // Redirect to bonus panel instead of using old modal
            openFinancePanel('bonus');
        }

        async function addBonusRule() {
            // Legacy - kept for compatibility
            openFinancePanel('bonus');
        }

        function addBonusRuleRow() {
            var form = document.getElementById('bonusRulesForm');
            if (!form) return;
            var row = document.createElement('div');
            row.className = 'bonus-rule-row';
            row.style.cssText = 'display:grid;grid-template-columns:1fr 1fr 1fr auto;gap:10px;align-items:end;margin-bottom:8px;';
            row.innerHTML =
                '<div><label style="font-size:11px;color:#888;display:block;margin-bottom:4px;">Min summa (so\'m)</label><input type="number" class="form-input br-min" placeholder="100 000"></div>' +
                '<div><label style="font-size:11px;color:#888;display:block;margin-bottom:4px;">Max summa (so\'m)</label><input type="number" class="form-input br-max" placeholder="500 000"></div>' +
                '<div><label style="font-size:11px;color:#888;display:block;margin-bottom:4px;">Bonus miqdori (so\'m)</label><input type="number" class="form-input br-bonus" placeholder="10 000"></div>' +
                '<button onclick="this.closest(\'.bonus-rule-row\').remove()" style="background:none;border:1px solid #fca5a5;border-radius:6px;color:#dc2626;padding:8px 12px;cursor:pointer;font-size:16px;">✕</button>';
            form.appendChild(row);
        }

        async function deleteBonusRule(index) {
            var rules = (window._financeBonusRules || []).filter(function(_, i) { return i !== index; });
            const req = await window.api(window.API_BASE + '/finance/bonus-rules', {
                method: 'POST', body: JSON.stringify({rules: rules})
            });
            if (req && req.ok) {
                window.showToast('Qoida o\'chirildi');
                // Refresh panel
                await refreshBonusRules();
                openFinancePanel('bonus');
            } else {
                window.showToast('Xatolik', 'error');
            }
        }

        async function refreshBonusRules() {
            try {
                const rls = await window.api(window.API_BASE + '/finance/bonus-rules');
                if (rls && rls.ok) {
                    var rules = await rls.json();
                    window._financeBonusRules = rules;
                    window._financeRulesHtml = rules.map(function(r, idx) {
                        return '<div style="margin-bottom:8px;font-size:13px;padding:8px;background:var(--gray-50);border-radius:4px;">' +
                            '<b>#' + (idx+1) + ':</b> ' + window.formatMoney(r.min_amount) + ' dan ' + window.formatMoney(r.max_amount) + ' gacha -> <b>' + window.formatMoney(r.bonus_amount) + ' bonus</b>' +
                            '</div>';
                    }).join('');
                }
            } catch(e) {}
        }

        async function saveBonusRules() {
            var rows = document.querySelectorAll('#bonusRulesForm .bonus-rule-row');
            var newRules = [];
            rows.forEach(function(row) {
                var min = parseFloat(row.querySelector('.br-min').value);
                var max = parseFloat(row.querySelector('.br-max').value);
                var bonus = parseFloat(row.querySelector('.br-bonus').value);
                if (!isNaN(min) && !isNaN(max) && !isNaN(bonus) && min >= 0 && max > min && bonus > 0) {
                    newRules.push({min_amount: min, max_amount: max, bonus_amount: bonus});
                }
            });

            if (newRules.length === 0) {
                window.showToast('Kamida 1 ta to\'g\'ri qoida kiriting', 'error');
                return;
            }

            var allRules = (window._financeBonusRules || []).concat(newRules);
            const req = await window.api(window.API_BASE + '/finance/bonus-rules', {
                method: 'POST', body: JSON.stringify({rules: allRules})
            });
            if (req && req.ok) {
                window.showToast(newRules.length + ' ta qoida saqlandi! ✅');
                await refreshBonusRules();
                openFinancePanel('bonus');
            } else {
                window.showToast('Xatolik yuz berdi', 'error');
            }
        }

        

        function openFinanceFeeModal(id, currentFee) {
            var val = currentFee ? currentFee : '';
            window.openModal('Kliyent uchun komissiya narxi',
                '<p class="text-muted" style="margin-bottom:12px;">Tanlangan provayder (usta/salon) uchun har bir kelgan mijozdan yechib olinadigan maxsus narxni belgilang. (Standart narxni tiklash uchun bosh qoldiring yoki 0 yozing)</p>' +
                '<div class="form-group">' +
                    '<label class="form-label">Summa (som)</label>' +
                    '<input type="number" id="financeFeeInput_' + id + '" class="form-input" value="' + val + '" placeholder="Masalan: 7000">' +
                '</div>',
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveFinanceFee(' + id + ')">Saqlash</button>'
            );
        }

        async function saveFinanceFee(id) {
            var input = document.getElementById('financeFeeInput_' + id);
            if (!input) return;
            var fee = parseFloat(input.value);
            var payload = { lead_fee: isNaN(fee) || fee <= 0 ? null : fee };

            try {
                const r = await window.api(window.API_BASE + '/providers/' + id, {
                    method: 'PATCH',
                    body: JSON.stringify(payload)
                });
                if (r && r.ok) {
                    window.showToast('Komissiya narxi muvaffaqiyatli saqlandi');
                    window.closeModal();
                    renderFinance(); // Jadvalni yangilash
                } else {
                    window.showToast('Xatolik yuz berdi', 'error');
                }
            } catch (e) {
                window.showToast('Tarmoq xatosi', 'error');
            }
        }

// Exports for ES6 modules
export { submitPremium, renderFinance, submitWithdraw, addBonusRule, showBonusRuleModal, openFinanceFeeModal, saveFinanceFee, openCategoryFeeModal, saveCategoryFee, openFinancePanel, closeFinancePanel, addBonusRuleRow, deleteBonusRule, saveBonusRules, refreshBonusRules };
// Expose to window for inline onclick handlers
window.submitPremium = submitPremium;
window.renderFinance = renderFinance;
window.submitWithdraw = submitWithdraw;
window.addBonusRule = addBonusRule;
window.showBonusRuleModal = showBonusRuleModal;
window.openFinanceFeeModal = openFinanceFeeModal;
window.saveFinanceFee = saveFinanceFee;
window.openCategoryFeeModal = openCategoryFeeModal;
window.saveCategoryFee = saveCategoryFee;
window.openFinancePanel = openFinancePanel;
window.closeFinancePanel = closeFinancePanel;
window.addBonusRuleRow = addBonusRuleRow;
window.deleteBonusRule = deleteBonusRule;
window.saveBonusRules = saveBonusRules;
window.refreshBonusRules = refreshBonusRules;
