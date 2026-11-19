"""Create assets table."""

import sqlalchemy as sa
from alembic import op

revision = "20261118_01"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "assets",
        sa.Column("id", sa.Integer(), primary_key=True),
        sa.Column("hostname", sa.String(length=253), nullable=False),
        sa.Column("ip_address", sa.String(length=45), nullable=False),
        sa.Column("environment", sa.String(length=32), nullable=False),
        sa.Column("description", sa.Text(), nullable=False, server_default=""),
        sa.Column("created_at", sa.DateTime(timezone=True), nullable=False),
        sa.UniqueConstraint("hostname"),
    )
    op.create_index("ix_assets_hostname", "assets", ["hostname"])
    op.create_index("ix_assets_environment", "assets", ["environment"])


def downgrade() -> None:
    op.drop_table("assets")
