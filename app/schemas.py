from datetime import datetime
from ipaddress import ip_address

from pydantic import BaseModel, ConfigDict, Field, field_validator


class AssetCreate(BaseModel):
    hostname: str = Field(min_length=1, max_length=253, pattern=r"^[A-Za-z0-9][A-Za-z0-9.-]*$")
    ip_address: str
    environment: str = Field(pattern=r"^(dev|test|staging|prod)$")
    description: str = Field(default="", max_length=1000)

    @field_validator("ip_address")
    @classmethod
    def validate_ip(cls, value: str) -> str:
        return str(ip_address(value))


class AssetRead(AssetCreate):
    model_config = ConfigDict(from_attributes=True)
    id: int
    created_at: datetime
