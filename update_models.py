import re
import os

files = [
    "beauty_salon.dart", "football_field.dart", "auto_workshop.dart",
    "auto_mobile_service.dart", "education_center.dart", "disinfection_service.dart",
    "appliance_repair.dart", "courier_service.dart", "nanny_service.dart",
    "tutor_service.dart", "nurse_service.dart", "dental_clinic.dart",
    "event_planning.dart", "master_worker.dart"
]

base_dir = "/home/devops/super-app/lib/models"

for file in files:
    path = os.path.join(base_dir, file)
    if not os.path.exists(path):
        continue
        
    with open(path, "r") as f:
        content = f.read()

    classes = re.findall(r'class\s+([A-Z]\w+)\s*\{', content)
    
    for cls in classes:
        # Skip models that shouldn't be modified
        if cls in ["Master", "BarberShop", "Barber", "SalonStaff", "ChemicalProduct", "NannyDocuments", "TodoItem", "ProductCatalogItem", "ShoppingListItem", "ShoppingListModel", "PlanItem", "ServiceOrder", "TimeSlot", "FieldAmenity", "UserProfile", "DentalDentist", "FinanceRecord", "FinanceCategoryStat", "FinanceStats", "PlannedPayment", "SavedPlace", "PaymentCard"]:
            continue
            
        # Check if subCategory already exists
        if f'final String? subCategory;' in content:
            continue
            
        # 1. Add final String? subCategory; before the constructor or at the end of fields
        # Find constructor start
        c_start = content.find(f'{cls}({{')
        if c_start != -1:
            content = content[:c_start] + "  final String? subCategory;\n\n  " + content[c_start:]
            
        # 2. Add this.subCategory, to constructor
        c_body_start = content.find(f'{cls}({{')
        if c_body_start != -1:
            c_body_end = content.find('});', c_body_start)
            if c_body_end != -1:
                content = content[:c_body_end] + "    this.subCategory,\n  " + content[c_body_end:]
                
        # 3. Add subCategory: meta['sub_category']?.toString(), to fromProviderJson
        f_start = content.find(f'factory {cls}.fromProviderJson')
        if f_start != -1:
            ret_start = content.find(f'return {cls}(', f_start)
            if ret_start != -1:
                ret_end = content.find(');', ret_start)
                if ret_end != -1:
                    has_meta = "meta =" in content[f_start:ret_start] or "meta['" in content[f_start:ret_start]
                    if not has_meta:
                        meta_line = "    final meta = json['metadata'] as Map<String, dynamic>? ?? {};\n"
                        body_open = content.find('{', f_start)
                        content = content[:body_open+1] + "\n" + meta_line + content[body_open+1:]
                        ret_start = content.find(f'return {cls}(', f_start)
                        ret_end = content.find(');', ret_start)
                    
                    content = content[:ret_end] + "      subCategory: meta['sub_category']?.toString(),\n    " + content[ret_end:]

    with open(path, "w") as f:
        f.write(content)

print("Done updating models")
