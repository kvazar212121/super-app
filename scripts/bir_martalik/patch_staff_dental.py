import sys

with open('backend/app/api/v1/provider_portal.py', 'r') as f:
    content = f.read()

old_staff_check = """        is_salon_staff = meta.get("salon_role") == "salon_employee" and meta.get("salon_provider_id") == provider.id
        is_massage_staff = meta.get("massage_role") == "center_employee" and meta.get("center_provider_id") == provider.id
        
        if is_salon_staff or is_massage_staff:"""

new_staff_check = """        is_salon_staff = meta.get("salon_role") == "salon_employee" and meta.get("salon_provider_id") == provider.id
        is_massage_staff = meta.get("massage_role") == "center_employee" and meta.get("center_provider_id") == provider.id
        is_dental_staff = meta.get("clinic_role") == "clinic_employee" and meta.get("clinic_provider_id") == provider.id
        
        if is_salon_staff or is_massage_staff or is_dental_staff:"""

content = content.replace(old_staff_check, new_staff_check)

with open('backend/app/api/v1/provider_portal.py', 'w') as f:
    f.write(content)

print("staff api patched for dental clinics")
