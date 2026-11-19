from fastapi.testclient import TestClient

from app.database import get_db
from app.main import app


class BrokenSession:
    def execute(self, _statement):
        from sqlalchemy.exc import OperationalError

        raise OperationalError("SELECT 1", {}, Exception("db down"))


def test_readiness_returns_503_when_database_fails():
    app.dependency_overrides[get_db] = lambda: BrokenSession()
    try:
        response = TestClient(app).get("/health/ready")
        assert response.status_code == 503
        assert response.json()["detail"] == "database unavailable"
    finally:
        app.dependency_overrides.clear()
