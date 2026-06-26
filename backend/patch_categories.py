import os

# 1. Patch models/category.py
with open('/home/devops/super-app/backend/app/models/category.py', 'r') as f:
    c = f.read()
if 'lead_fee:' not in c:
    c = c.replace('accent_color: Mapped[str] = mapped_column(String(7), default="#4285F4")',
                  'accent_color: Mapped[str] = mapped_column(String(7), default="#4285F4")\n    lead_fee: Mapped[float | None] = mapped_column(Float, nullable=True)')
    c = c.replace('"accent_color": self.accent_color,',
                  '"accent_color": self.accent_color,\n            "lead_fee": self.lead_fee,')
    with open('/home/devops/super-app/backend/app/models/category.py', 'w') as f:
        f.write(c)

# 2. Patch schemas/category.py
with open('/home/devops/super-app/backend/app/schemas/category.py', 'r') as f:
    c = f.read()
if 'lead_fee: Optional[float]' not in c:
    c = c.replace('accent_color: Optional[str] = "#4285F4"',
                  'accent_color: Optional[str] = "#4285F4"\n    lead_fee: Optional[float] = None')
    with open('/home/devops/super-app/backend/app/schemas/category.py', 'w') as f:
        f.write(c)

# 3. Patch order_service.py
with open('/home/devops/super-app/backend/app/services/order_service.py', 'r') as f:
    c = f.read()
if 'provider.category.lead_fee' not in c:
    old = 'actual_fee = provider.lead_fee if provider.lead_fee is not None else default_fee'
    new = '''actual_fee = default_fee
                if provider.lead_fee is not None:
                    actual_fee = provider.lead_fee
                elif provider.category and provider.category.lead_fee is not None:
                    actual_fee = provider.category.lead_fee'''
    c = c.replace(old, new)
    with open('/home/devops/super-app/backend/app/services/order_service.py', 'w') as f:
        f.write(c)

print("Backend patched")
