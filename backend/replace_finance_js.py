import re

with open('/home/devops/super-app/backend/app/static/admin/js/app.js', 'r', encoding='utf-8') as f:
    content = f.read()

new_finance_js = """
        // ===== PAGE: FINANCE =====
        async function renderFinance() {
            var f = { total_topup: 0, total_lead_fee: 0, total_premium: 0, total_admin_withdraw: 0, net_profit: 0 };
            try {
                const r = await api(API_BASE + '/finance/stats');
                if (r && r.ok) f = await r.json();
            } catch(e) {}

            var providerOptions = '';
            var providersTableRows = '';
            try {
                const pr = await api(API_BASE + '/finance/providers');
                if (pr && pr.ok) {
                    var pdata = await pr.json();
                    providerOptions = pdata.map(function(p) {
                        return '<option value="' + p.id + '">' + p.name + ' (Balans: ' + formatMoney(p.balance) + ')</option>';
                    }).join('');
                    
                    providersTableRows = pdata.map(function(p) {
                        var balColor = p.balance < 0 ? 'var(--red-600)' : 'var(--green-600)';
                        return '<tr>' +
                            '<td>#' + p.id + '</td>' +
                            '<td>' + p.name + '</td>' +
                            '<td>' + p.phone + '</td>' +
                            '<td><strong style="color:' + balColor + '">' + formatMoney(p.balance) + '</strong></td>' +
                            '<td>' + (p.lead_fee ? formatMoney(p.lead_fee) : 'Standart (5 000)') + '</td>' +
                            '</tr>';
                    }).join('');
                }
            } catch(e) {}

            var txRows = '';
            try {
                const tr = await api(API_BASE + '/finance/transactions?per_page=15');
                if (tr && tr.ok) {
                    var tdata = await tr.json();
                    txRows = (tdata.items || []).map(function(t) {
                        var tType = t.type;
                        if(tType==='topup') tType='Balans to\\'ldirish';
                        else if(tType==='topup_bonus') tType='Top-up Bonus';
                        else if(tType==='lead_fee') tType='Lead Fee (Komissiya)';
                        else if(tType==='premium_subscription') tType='Premium Obuna';
                        else if(tType==='admin_withdraw') tType='Platforma Xarajati';
                        
                        var amtColor = t.amount < 0 ? 'var(--red-600)' : 'var(--green-600)';
                        var userProv = t.provider_name ? ('Prov: '+t.provider_name) : (t.user_name ? ('Mijoz: '+t.user_name) : '—');
                        return '<tr>' +
                            '<td>' + formatDate(t.created_at) + '</td>' +
                            '<td>' + tType + '</td>' +
                            '<td>' + userProv + '</td>' +
                            '<td><strong style="color:' + amtColor + '">' + formatMoney(t.amount) + '</strong></td>' +
                            '<td>' + (t.description || '—') + '</td>' +
                            '</tr>';
                    }).join('');
                }
            } catch(e) {}

            var rulesHtml = '';
            try {
                const rls = await api(API_BASE + '/finance/bonus-rules');
                if (rls && rls.ok) {
                    var rules = await rls.json();
                    rulesHtml = rules.map(function(r, idx) {
                        return '<div style="margin-bottom:8px;font-size:13px;padding:8px;background:var(--gray-50);border-radius:4px;">' +
                            '<b>#' + (idx+1) + ':</b> ' + formatMoney(r.min_amount) + ' dan ' + formatMoney(r.max_amount) + ' gacha -> <b>' + formatMoney(r.bonus_amount) + ' bonus</b>' +
                            '</div>';
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
                        '<div class="stat-card-value">' + formatMoney(f.total_topup) + '</div>' +
                        '<span class="stat-card-change up">Mijoz/Usta hisob to\\'ldirishi</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Sof Foyda (Daromad)</span>' +
                            '<div class="stat-card-icon purple">&#128176;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + formatMoney(f.net_profit) + '</div>' +
                        '<span class="stat-card-change up">Komissiya + Premium - Xarajat</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Premium Obunalar</span>' +
                            '<div class="stat-card-icon orange">&#11088;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + formatMoney(f.total_premium) + '</div>' +
                        '<span class="stat-card-change up">Mijozlar to\\'lagan</span>' +
                    '</div>' +
                    '<div class="stat-card">' +
                        '<div class="stat-card-header">' +
                            '<span class="stat-card-label">Platforma Xarajati (Yechish)</span>' +
                            '<div class="stat-card-icon blue">&#128184;</div>' +
                        '</div>' +
                        '<div class="stat-card-value">' + formatMoney(f.total_admin_withdraw) + '</div>' +
                        '<span class="stat-card-change down">O\\'zimiz yechib olgan</span>' +
                    '</div>' +
                '</div>' +
                
                '<div style="display:grid; grid-template-columns: 1.5fr 1fr; gap:24px; margin-top:24px;">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Ustalar Hisobi (Top-up & Lead fee)</h3></div>' +
                        '<div class="card-body no-padding" style="max-height:300px;overflow-y:auto;">' +
                            '<table class="data-table">' +
                                '<thead><tr><th>ID</th><th>Ism</th><th>Telefon</th><th>Balans</th><th>Maxsus Fee</th></tr></thead>' +
                                '<tbody>' + (providersTableRows || '<tr><td colspan="5">Topilmadi</td></tr>') + '</tbody>' +
                            '</table>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Balans To\\'ldirish (Top-up)</h3></div>' +
                        '<div class="card-body">' +
                            '<div class="form-group">' +
                                '<label class="form-label">Usta (Provayder)</label>' +
                                '<select class="form-input" id="topupProvider"><option value="">Tanlang...</option>' + providerOptions + '</select>' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Summa (so\\'m)</label>' +
                                '<input type="number" class="form-input" id="topupAmount" placeholder="Masalan: 100000">' +
                            '</div>' +
                            '<div class="form-group">' +
                                '<label class="form-label">Izoh</label>' +
                                '<input type="text" class="form-input" id="topupNote" placeholder="Naqd pul olingan">' +
                            '</div>' +
                            '<button class="btn btn-primary" onclick="submitTopup()" style="width:100%;">Balansni to\\'ldirish</button>' +
                        '</div>' +
                    '</div>' +
                '</div>' +

                '<div style="display:grid; grid-template-columns: 1fr 1fr 1fr; gap:24px; margin-top:24px;">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Platformadan Yechib Olish</h3></div>' +
                        '<div class="card-body">' +
                            '<div class="form-group"><label class="form-label">Summa (so\\'m)</label><input type="number" class="form-input" id="withdrawAmount"></div>' +
                            '<div class="form-group"><label class="form-label">Izoh (Nimaga)</label><input type="text" class="form-input" id="withdrawNote"></div>' +
                            '<button class="btn btn-primary" onclick="submitWithdraw()" style="width:100%; background:var(--red-600);border-color:var(--red-600);">Xarajat qilish / Yechish</button>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Premium Tushum Qayd Etish</h3></div>' +
                        '<div class="card-body">' +
                            '<div class="form-group"><label class="form-label">Summa (so\\'m)</label><input type="number" class="form-input" id="premiumAmount" value="20000"></div>' +
                            '<div class="form-group"><label class="form-label">Izoh</label><input type="text" class="form-input" id="premiumNote" value="1 oylik premium"></div>' +
                            '<button class="btn btn-primary" onclick="submitPremium()" style="width:100%; background:var(--orange-500);border-color:var(--orange-500);">Tushumni Qo\\'shish</button>' +
                        '</div>' +
                    '</div>' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Top-up Bonus Qoidalari</h3></div>' +
                        '<div class="card-body">' +
                            rulesHtml +
                            '<button class="btn btn-secondary btn-sm" onclick="showBonusRuleModal()" style="margin-top:8px;">Qoidalarni tahrirlash</button>' +
                        '</div>' +
                    '</div>' +
                '</div>' +

                '<div class="card" style="margin-top:24px;">' +
                    '<div class="card-header"><h3 class="card-title">So\\'nggi Tranzaksiyalar (Tarix)</h3></div>' +
                    '<div class="card-body no-padding">' +
                        '<table class="data-table">' +
                            '<thead><tr><th>Sana</th><th>Turi</th><th>Shaxs</th><th>Summa</th><th>Izoh</th></tr></thead>' +
                            '<tbody>' + (txRows || '<tr><td colspan="5">Tranzaksiyalar topilmadi</td></tr>') + '</tbody>' +
                        '</table>' +
                    '</div>' +
                '</div>';
        }

        async function submitTopup() {
            var prov = document.getElementById('topupProvider').value;
            var amt = document.getElementById('topupAmount').value;
            var note = document.getElementById('topupNote').value;
            if(!prov || !amt) { showToast('Usta va summa majburiy', 'error'); return; }
            const r = await api(API_BASE + '/finance/topup', {
                method: 'POST', body: JSON.stringify({provider_id: parseInt(prov), amount: parseFloat(amt), note: note})
            });
            if(r && r.ok) { showToast('Balans to\\'ldirildi'); renderFinance(); } else { showToast('Xatolik', 'error'); }
        }

        async function submitWithdraw() {
            var amt = document.getElementById('withdrawAmount').value;
            var note = document.getElementById('withdrawNote').value;
            if(!amt) return;
            const r = await api(API_BASE + '/finance/admin-withdraw', {
                method: 'POST', body: JSON.stringify({amount: parseFloat(amt), note: note})
            });
            if(r && r.ok) { showToast('Pul yechib olindi (Xarajat)'); renderFinance(); } else { showToast('Xatolik', 'error'); }
        }

        async function submitPremium() {
            var amt = document.getElementById('premiumAmount').value;
            var note = document.getElementById('premiumNote').value;
            if(!amt) return;
            const r = await api(API_BASE + '/finance/premium-purchase', {
                method: 'POST', body: JSON.stringify({amount: parseFloat(amt), note: note})
            });
            if(r && r.ok) { showToast('Premium tushum qo\\'shildi'); renderFinance(); } else { showToast('Xatolik', 'error'); }
        }

        function showBonusRuleModal() {
            openModal('Bonus Qoidalari',
                '<p class="text-muted" style="margin-bottom:12px;">Yangi qoidani kiriting. Barcha eski qoidalar saqlanadi. (Masalan: 100000 dan 500000 gacha -> 10000 bonus)</p>' +
                '<div class="form-row">' +
                    '<div class="form-group"><label>Min</label><input type="number" id="brMin" class="form-input"></div>' +
                    '<div class="form-group"><label>Max</label><input type="number" id="brMax" class="form-input"></div>' +
                    '<div class="form-group"><label>Bonus</label><input type="number" id="brBonus" class="form-input"></div>' +
                '</div>',
                '<button class="btn btn-secondary" onclick="closeModal()">Yopish</button>' +
                '<button class="btn btn-primary" onclick="addBonusRule()">Qo\\'shish</button>'
            );
        }

        async function addBonusRule() {
            var minAmt = parseFloat(document.getElementById('brMin').value);
            var maxAmt = parseFloat(document.getElementById('brMax').value);
            var bonusAmt = parseFloat(document.getElementById('brBonus').value);
            if(isNaN(minAmt) || isNaN(maxAmt) || isNaN(bonusAmt)) return;
            
            var existingRules = [];
            try {
                const r = await api(API_BASE + '/finance/bonus-rules');
                if(r && r.ok) existingRules = await r.json();
            } catch(e){}
            
            existingRules.push({min_amount: minAmt, max_amount: maxAmt, bonus_amount: bonusAmt});
            
            const req = await api(API_BASE + '/finance/bonus-rules', {
                method: 'POST', body: JSON.stringify({rules: existingRules})
            });
            if(req && req.ok) {
                showToast('Qoida qo\\'shildi');
                closeModal();
                renderFinance();
            } else {
                showToast('Xatolik yuz berdi', 'error');
            }
        }
"""

start_str = "// ===== PAGE: FINANCE ====="
end_str = "// ===== PAGE: PROMOS & BANNERS ====="

start_idx = content.find(start_str)
end_idx = content.find(end_str)

if start_idx != -1 and end_idx != -1:
    new_content = content[:start_idx] + new_finance_js + "\n        " + content[end_idx:]
    with open('/home/devops/super-app/backend/app/static/admin/js/app.js', 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Finance JS successfully replaced!")
else:
    print("Could not find start or end strings.")
