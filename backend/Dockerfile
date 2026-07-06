FROM python:3.12-slim

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app ./app
COPY .env.example ./.env.example

EXPOSE 8000
# Worker soni WEB_CONCURRENCY env orqali (default 3). `exec` — uvicorn PID 1 bo'lib
# SIGTERM'ni qabul qiladi (to'g'ri graceful shutdown).
CMD ["sh", "-c", "exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers ${WEB_CONCURRENCY:-3}"]
