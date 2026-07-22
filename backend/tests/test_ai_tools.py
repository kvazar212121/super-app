import os, asyncio, json
from datetime import datetime as DT
os.environ.setdefault('DATABASE_URL','postgresql+asyncpg://u:p@localhost/db')
os.environ.setdefault('DATABASE_SYNC_URL','postgresql+psycopg2://u:p@localhost/db')
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.ext.compiler import compiles
@compiles(JSONB,"sqlite")
def _c(e,c,**k): return "JSON"
from sqlalchemy.ext.asyncio import create_async_engine, async_sessionmaker, AsyncSession
from app.db.base import Base
import app.models
from app.models.user import User
from app.models.category import Category
from app.models.provider import Provider
from app.models.order import Order, OrderStatus
from app.models.plan import Plan
from app.services.ai_agent import handle_tool_call

def tc(name, args):
    return {"id":"x","function":{"name":name,"arguments":json.dumps(args)}}

async def main():
    NOW=DT(2026,1,1,12,0)
    eng=create_async_engine("sqlite+aiosqlite:///:memory:")
    async with eng.begin() as c: await c.run_sync(Base.metadata.create_all)
    S=async_sessionmaker(eng,class_=AsyncSession,expire_on_commit=False)
    async with S() as db:
        u1=User(name="A",surname="B",phone="+1",hashed_password="x",balance=5000.0,created_at=NOW); db.add(u1)
        u2=User(name="C",surname="D",phone="+2",hashed_password="x",created_at=NOW); db.add(u2); await db.flush()
        cat=Category(key="e",title_uz="E",icon="e"); db.add(cat); await db.flush()
        prov=Provider(category_id=cat.id,name="Usta",address="T",phone="+3",owner_user_id=u2.id,is_active=True); db.add(prov); await db.flush()
        # u1 order
        o1=Order(user_id=u1.id,category_id=cat.id,provider_id=prov.id,service_name="Ish",address="T",date=NOW,price=100000,status=OrderStatus.pending,created_at=NOW); db.add(o1)
        # u2 order (boshqa user)
        o2=Order(user_id=u2.id,category_id=cat.id,provider_id=prov.id,service_name="X",address="T",date=NOW,price=50000,status=OrderStatus.pending,created_at=NOW); db.add(o2)
        p1=Plan(user_id=u1.id,title="Majlis",due_date=NOW,is_completed=False); db.add(p1)
        await db.commit()

        # 1. list_orders — u1 faqat o'zinikini ko'radi
        r,_=await handle_tool_call(db,u1.id,tc("list_orders",{}))
        d=json.loads(r); assert d["count"]==1 and d["orders"][0]["order_id"]==o1.id, f"FAIL list: {d}"
        print("OK list_orders: u1 faqat o'z buyurtmasini ko'rdi (1 ta)")

        # 2. cancel_order confirm=false -> needs_confirmation (o'zgarmaydi)
        r,act=await handle_tool_call(db,u1.id,tc("cancel_order",{"order_id":o1.id,"confirm":False}))
        d=json.loads(r); assert d["status"]=="needs_confirmation" and act is None, f"FAIL confirm: {d}"
        await db.refresh(o1); assert o1.status==OrderStatus.pending, "FAIL: order o'zgardi (confirm=false)"
        print("OK cancel_order confirm=false: tasdiq so'radi, order o'zgarmadi")

        # 3. cancel_order confirm=true -> bekor
        r,act=await handle_tool_call(db,u1.id,tc("cancel_order",{"order_id":o1.id,"confirm":True}))
        d=json.loads(r); assert d["status"]=="success", f"FAIL cancel: {d}"
        await db.refresh(o1); assert o1.status==OrderStatus.cancelled, "FAIL: bekor bo'lmadi"
        print(f"OK cancel_order confirm=true: bekor qilindi (action={act})")

        # 4. XAVFSIZLIK: u1 u2'ning order'ini bekor qila olmasin
        r,_=await handle_tool_call(db,u1.id,tc("cancel_order",{"order_id":o2.id,"confirm":True}))
        d=json.loads(r); assert d["status"]=="error", f"FAIL security: {d}"
        await db.refresh(o2); assert o2.status==OrderStatus.pending, "FAIL: u1 u2 orderini o'zgartirdi!"
        print("OK xavfsizlik: u1 u2'ning buyurtmasini bekor qila OLMADI")

        # 5. get_account_info — balans
        r,_=await handle_tool_call(db,u1.id,tc("get_account_info",{}))
        d=json.loads(r); assert d["balance"]==5000.0, f"FAIL acc: {d}"
        print(f"OK get_account_info: balans={d['balance']}, premium={d['is_premium']}")

        # 6. complete_plan
        r,act=await handle_tool_call(db,u1.id,tc("complete_plan",{"plan_id":p1.id}))
        d=json.loads(r); await db.refresh(p1); assert p1.is_completed, "FAIL plan"
        print(f"OK complete_plan: bajarildi (action={act})")

        # 7. delete_plan confirm=false -> needs_confirmation
        r,_=await handle_tool_call(db,u1.id,tc("delete_plan",{"plan_id":p1.id,"confirm":False}))
        d=json.loads(r); assert d["status"]=="needs_confirmation", f"FAIL del confirm: {d}"
        print("OK delete_plan confirm=false: tasdiq so'radi")

    print("\n✅ BARCHA AI TOOL TESTLARI O'TDI")

asyncio.run(main())
