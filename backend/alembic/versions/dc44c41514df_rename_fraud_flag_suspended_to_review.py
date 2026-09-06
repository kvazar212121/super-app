"""rename fraud flag suspended to review

Revision ID: dc44c41514df
Revises: ece5f1b1b853
Create Date: 2026-09-06 13:20:22.526611

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by alembic.
revision: str = 'dc44c41514df'
down_revision: Union[str, None] = 'ece5f1b1b853'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """`suspended` -> `review`.

    Nomi yolg'on edi: bu daraja hech qachon provayderni bloklamagan
    (qidiruv `providers.is_blocked` ni tekshiradi), lekin ham provayderga,
    ham adminga "to'xtatilgan" deb ko'rsatilardi.

    `ALTER TYPE ... RENAME VALUE` faqat katalogni o'zgartiradi — jadval
    qayta yozilmaydi, shuning uchun katta jadvalda ham tez.
    """
    op.execute("ALTER TYPE fraudflaglevel RENAME VALUE 'suspended' TO 'review'")


def downgrade() -> None:
    op.execute("ALTER TYPE fraudflaglevel RENAME VALUE 'review' TO 'suspended'")
