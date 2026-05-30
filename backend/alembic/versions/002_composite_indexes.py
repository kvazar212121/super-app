"""add composite indexes for orders, reviews, and providers

Revision ID: 002_composite_indexes
Revises: 001_initial_migration
Create Date: 2026-05-19

"""

from alembic import op


# revision identifiers, used by alembic.
revision = "002_composite_indexes"
down_revision = "001_initial_migration"
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Buyurtmalar — foydalanuvchi bo'yicha holat filtrlash
    op.create_index(
        "ix_orders_user_id_status",
        "orders",
        ["user_id", "status"],
    )

    # Buyurtmalar — provayder bo'yicha holat filtrlash
    op.create_index(
        "ix_orders_provider_id_status",
        "orders",
        ["provider_id", "status"],
    )

    # Buyurtmalar — vaqt va holat bo'yicha filtrlash
    op.create_index(
        "ix_orders_created_at_status",
        "orders",
        ["created_at", "status"],
    )

    # Sharhlar — provayder bo'yicha vaqt tartibi
    op.create_index(
        "ix_reviews_provider_id_created_at",
        "reviews",
        ["provider_id", "created_at"],
    )

    # Provayderlar — kategoriya va faollik holati
    op.create_index(
        "ix_providers_category_id_is_active",
        "providers",
        ["category_id", "is_active"],
    )


def downgrade() -> None:
    op.drop_index("ix_providers_category_id_is_active", table_name="providers")
    op.drop_index("ix_reviews_provider_id_created_at", table_name="reviews")
    op.drop_index("ix_orders_created_at_status", table_name="orders")
    op.drop_index("ix_orders_provider_id_status", table_name="orders")
    op.drop_index("ix_orders_user_id_status", table_name="orders")
