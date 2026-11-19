from sqlalchemy import text

ASSET = {
    "hostname": "web-01.example.local",
    "ip_address": "10.20.1.10",
    "environment": "prod",
    "description": "Reverse proxy node",
}


def test_health_and_version(client):
    assert client.get("/health/live").json() == {"status": "alive"}
    assert client.get("/health/ready").json() == {"status": "ready"}
    assert client.get("/version").json() == {"version": "test-version"}


def test_asset_crud(client):
    created = client.post("/api/assets", json=ASSET)
    assert created.status_code == 201
    asset_id = created.json()["id"]
    assert client.get(f"/api/assets/{asset_id}").json()["hostname"] == ASSET["hostname"]
    assert len(client.get("/api/assets").json()) == 1
    assert client.delete(f"/api/assets/{asset_id}").status_code == 204
    assert client.get(f"/api/assets/{asset_id}").status_code == 404


def test_input_validation(client):
    invalid = {**ASSET, "ip_address": "999.1.1.1", "environment": "unknown"}
    response = client.post("/api/assets", json=invalid)
    assert response.status_code == 422


def test_duplicate_hostname_returns_conflict(client):
    assert client.post("/api/assets", json=ASSET).status_code == 201
    assert client.post("/api/assets", json=ASSET).status_code == 409


def test_database_access(db_session):
    assert db_session.execute(text("SELECT 1")).scalar_one() == 1


def test_missing_asset_error(client):
    response = client.get("/api/assets/999")
    assert response.status_code == 404
    assert response.json()["detail"] == "asset not found"
