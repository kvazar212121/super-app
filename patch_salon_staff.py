import sys

with open('backend/app/api/v1/provider_portal.py', 'r') as f:
    content = f.read()

# 1. Update ManualCallOrderIn
old_model = """class ManualCallOrderIn(BaseModel):
    user_id: int
    service_name: str
    date: datetime
    price: float
    address: str | None = None
    notes: str | None = "Telefon orqali kelishildi\""""

new_model = """class ManualCallOrderIn(BaseModel):
    user_id: int
    service_name: str
    date: datetime
    price: float
    address: str | None = None
    notes: str | None = "Telefon orqali kelishildi"
    staff_provider_id: int | None = None"""

content = content.replace(old_model, new_model)

# 2. Update create_manual_order to use staff_provider_id
old_create = """    new_order = Order(
        user_id=target_user.id,
        category_id=provider.category_id,
        provider_id=provider.id,"""

new_create = """    actual_provider_id = parsed_data.staff_provider_id if parsed_data.staff_provider_id else provider.id
    new_order = Order(
        user_id=target_user.id,
        category_id=provider.category_id,
        provider_id=actual_provider_id,"""

content = content.replace(old_create, new_create)

# 3. Add my_staff endpoint
new_endpoint = """
@router.get("/my-staff")
async def get_my_staff(
    category_key: str | None = Query(None),
    user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    provider = await _get_user_provider(db, user, category_key)
    
    # Staff are providers with salon_role='salon_employee' and salon_provider_id=provider.id
    from app.models.provider import Provider
    result = await db.execute(
        select(Provider).where(
            Provider.is_active == True,
            Provider.category_id == provider.category_id
        )
    )
    staff_list = []
    for p in result.scalars().all():
        meta = p.metadata_json or {}
        if meta.get("salon_role") == "salon_employee" and meta.get("salon_provider_id") == provider.id:
            staff_list.append({
                "id": p.id,
                "name": meta.get("display_name") or p.name,
                "user_id": p.owner_user_id
            })
            
    return {"staff": staff_list}
"""

if "get_my_staff" not in content:
    content += new_endpoint

with open('backend/app/api/v1/provider_portal.py', 'w') as f:
    f.write(content)

print("Backend patched for staff selection")
