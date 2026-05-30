"""initial migration - create all tables

Revision ID: 001_initial_migration
Revises:
Create Date: 2026-05-19

"""

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by alembic.
revision = "001_initial_migration"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── users ────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("name", sa.String(length=100), nullable=False),
        sa.Column("surname", sa.String(length=100), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column("hashed_password", sa.String(length=255), nullable=False),
        sa.Column("avatar_url", sa.String(length=500), nullable=True),
        sa.Column("telegram_username", sa.String(length=100), nullable=True),
        sa.Column("balance", sa.Float(), nullable=False),
        sa.Column("cashback", sa.Float(), nullable=False),
        sa.Column("is_premium", sa.Boolean(), nullable=False),
        sa.Column("is_admin", sa.Boolean(), nullable=False),
        sa.Column("is_active", sa.Boolean(), nullable=False),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_unique_constraint("uq_users_phone", "users", ["phone"])
    op.create_index("ix_users_phone", "users", ["phone"])

    # ── categories ───────────────────────────────────────────────────────
    op.create_table(
        "categories",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column("key", sa.String(length=50), nullable=False),
        sa.Column("title_uz", sa.String(length=200), nullable=False),
        sa.Column("subtitle_uz", sa.String(length=300), nullable=True),
        sa.Column("icon", sa.String(length=50), nullable=False),
        sa.Column("accent_color", sa.String(length=7), nullable=False),
    )
    op.create_unique_constraint("uq_categories_key", "categories", ["key"])
    op.create_index("ix_categories_key", "categories", ["key"])

    # ── category_variants ────────────────────────────────────────────────
    op.create_table(
        "category_variants",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "category_id",
            sa.Integer(),
            sa.ForeignKey("categories.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("label_uz", sa.String(length=200), nullable=False),
        sa.Column("base_price", sa.Float(), nullable=False),
    )
    op.create_index(
        "ix_category_variants_category_id", "category_variants", ["category_id"]
    )

    # ── providers ────────────────────────────────────────────────────────
    op.create_table(
        "providers",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "category_id",
            sa.Integer(),
            sa.ForeignKey("categories.id"),
            nullable=False,
        ),
        sa.Column("name", sa.String(length=300), nullable=False),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("phone", sa.String(length=20), nullable=False),
        sa.Column("lat", sa.Float(), nullable=False),
        sa.Column("lng", sa.Float(), nullable=False),
        sa.Column("rating", sa.Float(), nullable=False),
        sa.Column("review_count", sa.Integer(), nullable=False),
        sa.Column("cover_image", sa.String(length=500), nullable=True),
        sa.Column("metadata_json", sa.JSON(), nullable=True),
        sa.Column("is_active", sa.Boolean(), nullable=False),
    )
    op.create_index("ix_providers_category_id", "providers", ["category_id"])

    # ── orders ───────────────────────────────────────────────────────────
    op.create_table(
        "orders",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id"),
            nullable=False,
        ),
        sa.Column(
            "category_id",
            sa.Integer(),
            sa.ForeignKey("categories.id"),
            nullable=False,
        ),
        sa.Column(
            "provider_id",
            sa.Integer(),
            sa.ForeignKey("providers.id"),
            nullable=False,
        ),
        sa.Column(
            "variant_id",
            sa.Integer(),
            sa.ForeignKey("category_variants.id"),
            nullable=True,
        ),
        sa.Column("service_name", sa.String(length=300), nullable=False),
        sa.Column("service_icon", sa.String(length=50), nullable=True),
        sa.Column("address", sa.String(length=500), nullable=False),
        sa.Column("notes", sa.String(length=1000), nullable=True),
        sa.Column("date", sa.DateTime(), nullable=False),
        sa.Column("price", sa.Float(), nullable=False),
        sa.Column("cashback_earned", sa.Float(), nullable=False),
        sa.Column(
            "status",
            sa.Enum(
                "pending",
                "confirmed",
                "in_progress",
                "completed",
                "cancelled",
                name="orderstatus",
            ),
            nullable=False,
        ),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.text("now()"),
            nullable=False,
        ),
    )
    op.create_index("ix_orders_user_id", "orders", ["user_id"])
    op.create_index("ix_orders_category_id", "orders", ["category_id"])
    op.create_index("ix_orders_provider_id", "orders", ["provider_id"])

    # ── reviews ──────────────────────────────────────────────────────────
    op.create_table(
        "reviews",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id"),
            nullable=False,
        ),
        sa.Column(
            "provider_id",
            sa.Integer(),
            sa.ForeignKey("providers.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("rating", sa.Integer(), nullable=False),
        sa.Column("comment", sa.String(length=1000), nullable=True),
        sa.Column(
            "created_at",
            sa.DateTime(timezone=True),
            server_default=sa.func.now(),
            nullable=False,
        ),
    )
    op.create_index("ix_reviews_user_id", "reviews", ["user_id"])
    op.create_index("ix_reviews_provider_id", "reviews", ["provider_id"])

    # ── payment_cards ────────────────────────────────────────────────────
    op.create_table(
        "payment_cards",
        sa.Column("id", sa.Integer(), primary_key=True, autoincrement=True),
        sa.Column(
            "user_id",
            sa.Integer(),
            sa.ForeignKey("users.id", ondelete="CASCADE"),
            nullable=False,
        ),
        sa.Column("masked_number", sa.String(length=19), nullable=False),
        sa.Column("bank", sa.String(length=100), nullable=False),
        sa.Column("card_type", sa.String(length=20), nullable=False),
        sa.Column("exp_month", sa.Integer(), nullable=False),
        sa.Column("exp_year", sa.Integer(), nullable=False),
        sa.Column("is_default", sa.Boolean(), nullable=False),
    )
    op.create_index(
        "ix_payment_cards_user_id", "payment_cards", ["user_id"]
    )


def downgrade() -> None:
    op.drop_table("payment_cards")
    op.drop_table("reviews")
    op.drop_table("orders")
    op.drop_table("providers")
    op.drop_table("category_variants")
    op.drop_table("categories")
    op.drop_table("users")
    # Drop the enum type created for OrderStatus
    op.execute("DROP TYPE IF EXISTS orderstatus")
