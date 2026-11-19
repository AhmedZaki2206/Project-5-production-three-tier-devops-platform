import json
import logging
import os
from datetime import datetime, timezone
from typing import Annotated

from fastapi import Depends, FastAPI, HTTPException, Response, status
from sqlalchemy import select, text
from sqlalchemy.exc import IntegrityError, SQLAlchemyError
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import Asset
from app.schemas import AssetCreate, AssetRead


class JsonFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        return json.dumps(
            {
                "timestamp": datetime.now(timezone.utc).isoformat(),
                "level": record.levelname,
                "service": "portal-api",
                "message": record.getMessage(),
            }
        )


handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logger = logging.getLogger("portal")
logger.handlers = [handler]
logger.setLevel(logging.INFO)

app = FastAPI(title="Infrastructure Service Portal", version=os.getenv("APP_VERSION", "dev"))
DbSession = Annotated[Session, Depends(get_db)]


@app.get("/")
def root() -> dict[str, str]:
    return {"service": "Infrastructure Service Portal", "docs": "/docs"}


@app.get("/health/live")
def liveness() -> dict[str, str]:
    return {"status": "alive"}


@app.get("/health/ready")
def readiness(db: DbSession) -> dict[str, str]:
    try:
        db.execute(text("SELECT 1"))
    except SQLAlchemyError as exc:
        logger.error("database readiness check failed")
        raise HTTPException(status_code=503, detail="database unavailable") from exc
    return {"status": "ready"}


@app.get("/version")
def version() -> dict[str, str]:
    return {"version": os.getenv("APP_VERSION", "dev")}


@app.get("/api/assets", response_model=list[AssetRead])
def list_assets(db: DbSession) -> list[Asset]:
    return list(db.scalars(select(Asset).order_by(Asset.id)))


@app.post("/api/assets", response_model=AssetRead, status_code=status.HTTP_201_CREATED)
def create_asset(payload: AssetCreate, db: DbSession) -> Asset:
    asset = Asset(**payload.model_dump())
    db.add(asset)
    try:
        db.commit()
        db.refresh(asset)
    except IntegrityError as exc:
        db.rollback()
        raise HTTPException(status_code=409, detail="hostname already exists") from exc
    logger.info("asset created")
    return asset


def find_asset(asset_id: int, db: Session) -> Asset:
    asset = db.get(Asset, asset_id)
    if asset is None:
        raise HTTPException(status_code=404, detail="asset not found")
    return asset


@app.get("/api/assets/{asset_id}", response_model=AssetRead)
def get_asset(asset_id: int, db: DbSession) -> Asset:
    return find_asset(asset_id, db)


@app.delete("/api/assets/{asset_id}", status_code=status.HTTP_204_NO_CONTENT)
def delete_asset(asset_id: int, db: DbSession) -> Response:
    asset = find_asset(asset_id, db)
    db.delete(asset)
    db.commit()
    return Response(status_code=status.HTTP_204_NO_CONTENT)
