import re

filepath = '/home/devops/super-app/backend/app/static/admin/js/pages/finance.js'
with open(filepath, 'r') as f:
    c = f.read()

# Remove the action column from providers
c = re.sub(r"<th>Maxsus Fee</th><th>Amallar</th>", "<th>Maxsus Fee</th>", c)
c = re.sub(r"colspan=\"6\"", "colspan=\"5\"", c)
c = re.sub(r"'<td><button class=\"btn btn-sm btn-secondary\" onclick=\"openFinanceFeeModal\(' \+ p\.id \+ ', ' \+ \(p\.lead_fee \|\| 0\) \+ '\)\">Narx belgilash</button></td>' \+", "", c)

# Add categories fetching
fetch_categories_code = """
            var categoriesHtml = '';
            try {
                const cr = await window.api(window.API_BASE + '/categories');
                if (cr && cr.ok) {
                    var cdata = await cr.json();
                    categoriesHtml = cdata.map(function(c) {
                        return '<tr>' +
                            '<td>' + c.title_uz + '</td>' +
                            '<td>' + (c.lead_fee ? window.formatMoney(c.lead_fee) : 'Standart (5 000)') + '</td>' +
                            '<td><button class="btn btn-sm btn-secondary" onclick="openCategoryFeeModal(' + c.id + ', ' + (c.lead_fee || 0) + ')">Narx belgilash</button></td>' +
                            '</tr>';
                    }).join('');
                }
            } catch(e) {}
"""
if 'categoriesHtml =' not in c:
    c = c.replace("var providerOptions = '';", fetch_categories_code + "\n            var providerOptions = '';")

# Add categories table HTML after Providers table
cat_table_html = """
                '<div style="display:grid; grid-template-columns: 1fr; gap:24px; margin-top:24px;">' +
                    '<div class="card">' +
                        '<div class="card-header"><h3 class="card-title">Kategoriyalar bo\\'yicha Komissiya Narxlari</h3></div>' +
                        '<div class="card-body no-padding" style="max-height:300px;overflow-y:auto;">' +
                            '<table class="data-table">' +
                                '<thead><tr><th>Kategoriya</th><th>Maxsus Fee</th><th>Amallar</th></tr></thead>' +
                                '<tbody>' + (categoriesHtml || '<tr><td colspan="3">Topilmadi</td></tr>') + '</tbody>' +
                            '</table>' +
                        '</div>' +
                    '</div>' +
                '</div>' +
"""
if 'Kategoriyalar bo\\'yicha Komissiya Narxlari' not in c:
    c = c.replace("'</div>' +\n\n                '<div style=\"display:grid; grid-template-columns: 1fr 1fr 1fr;",
                  "'</div>' +\n" + cat_table_html + "\n                '<div style=\"display:grid; grid-template-columns: 1fr 1fr 1fr;")

# Add the functions for category fee modal
cat_functions = """
        function openCategoryFeeModal(id, currentFee) {
            var val = currentFee ? currentFee : '';
            window.openModal('Kategoriya uchun komissiya narxi',
                '<p class="text-muted" style="margin-bottom:12px;">Ushbu kategoriyadagi barcha ustalar uchun har bir kelgan mijozdan yechib olinadigan maxsus narxni belgilang. (Standart narxni tiklash uchun bosh qoldiring yoki 0 yozing)</p>' +
                '<div class="form-group">' +
                    '<label class="form-label">Summa (som)</label>' +
                    '<input type="number" id="catFeeInput_' + id + '" class="form-input" value="' + val + '" placeholder="Masalan: 7000">' +
                '</div>',
                '<button class="btn btn-secondary" onclick="window.closeModal()">Bekor qilish</button>' +
                '<button class="btn btn-primary" onclick="saveCategoryFee(' + id + ')">Saqlash</button>'
            );
        }

        async function saveCategoryFee(id) {
            var input = document.getElementById('catFeeInput_' + id);
            if (!input) return;
            var fee = parseFloat(input.value);
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
"""
if 'openCategoryFeeModal(' not in c:
    c = c.replace("// Exports for ES6 modules", cat_functions + "\n// Exports for ES6 modules")

# Add to exports and window
if 'openCategoryFeeModal' not in c.split('// Exports for ES6 modules')[1]:
    c = c.replace("export {", "export { openCategoryFeeModal, saveCategoryFee,")
    c += "\nwindow.openCategoryFeeModal = openCategoryFeeModal;\nwindow.saveCategoryFee = saveCategoryFee;"

with open(filepath, 'w') as f:
    f.write(c)

print("UI patched")
