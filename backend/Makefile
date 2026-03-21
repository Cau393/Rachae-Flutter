# Use targets here so ASGI always runs with .venv (plain `uvicorn` may resolve to system Python).
.PHONY: asgi
asgi:
	./.venv/bin/python -m uvicorn backend.asgi:application --reload --port 8000
