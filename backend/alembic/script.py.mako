"""${message}

Revision ID: ${up_revision}
Revises: ${down_revision}
Create Date: ${create_date}

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa
## `imports` faqat --autogenerate da beriladi. Shartsiz yozilsa
## oddiy `alembic revision` "NameError: Undefined" bilan yiqilardi.
${imports if imports is not UNDEFINED else ""}

# revision identifiers, used by alembic.
revision: str = '${up_revision}'
down_revision: Union[str, None] = ${repr(down_revision)}
branch_labels: Union[str, Sequence[str], None] = ${repr(branch_labels)}
depends_on: Union[str, Sequence[str], None] = ${repr(depends_on)}


def upgrade() -> None:
    ${upgrades if upgrades else "pass"}

def downgrade() -> None:
    ${downgrades if downgrades else "pass"}
