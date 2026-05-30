import sys
from os.path import abspath, dirname

sys.path.insert(0, dirname(dirname(abspath(__file__))))

from logging.config import fileConfig

from alembic import context

from app.db.base import Base

# Import all models so Alembic can detect them
from app.models.user import User          # noqa: F401
from app.models.category import Category, CategoryVariant  # noqa: F401
from app.models.provider import Provider  # noqa: F401
from app.models.order import Order        # noqa: F401
from app.models.review import Review      # noqa: F401
from app.models.payment import PaymentCard  # noqa: F401
from app.models.setting import PlatformSetting  # noqa: F401
from app.models.notification import Notification  # noqa: F401
from app.models.transaction import Transaction  # noqa: F401

config = context.config

if config.config_file_name is not None:
    fileConfig(config.config_file_name)

target_metadata = Base.metadata


def run_migrations_offline() -> None:
    """Run migrations in 'offline' mode."""
    url = config.get_main_option("sqlalchemy.url")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )

    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    """Run migrations in 'online' mode."""
    from sqlalchemy import create_engine

    connectable = create_engine(config.get_main_option("sqlalchemy.url"))

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )

        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
