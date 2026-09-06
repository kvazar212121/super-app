from pydantic import BaseModel


class UrlResponse(BaseModel):
    url: str


class PaginatedResponse(BaseModel):
    items: list
    total: int
    page: int
    per_page: int
    pages: int