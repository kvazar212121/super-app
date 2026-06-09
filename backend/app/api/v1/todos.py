from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from app.db.session import get_db
from app.api.dependencies import get_current_user
from app.models.user import User
from app.models.todo import Todo
from app.schemas.dailies import TodoOut, TodoCreate, TodoUpdate

router = APIRouter(prefix="/todos", tags=["todos"])

@router.get("/", response_model=list[TodoOut])
async def get_todos(
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Todo).where(Todo.user_id == current_user.id).order_by(Todo.created_at.desc()))
    return result.scalars().all()

@router.post("/", response_model=TodoOut, status_code=201)
async def create_todo(
    data: TodoCreate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    new_todo = Todo(**data.model_dump(), user_id=current_user.id)
    db.add(new_todo)
    await db.commit()
    await db.refresh(new_todo)
    return new_todo

@router.patch("/{todo_id}", response_model=TodoOut)
async def update_todo(
    todo_id: int,
    data: TodoUpdate,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Todo).where(Todo.id == todo_id, Todo.user_id == current_user.id))
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    
    update_data = data.model_dump(exclude_unset=True)
    for key, value in update_data.items():
        setattr(todo, key, value)
        
    await db.commit()
    await db.refresh(todo)
    return todo

@router.delete("/{todo_id}", status_code=204)
async def delete_todo(
    todo_id: int,
    current_user: User = Depends(get_current_user),
    db: AsyncSession = Depends(get_db)
):
    result = await db.execute(select(Todo).where(Todo.id == todo_id, Todo.user_id == current_user.id))
    todo = result.scalar_one_or_none()
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    
    await db.delete(todo)
    await db.commit()
