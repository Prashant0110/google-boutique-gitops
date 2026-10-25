FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir --disable-pip-version-check -r requirements.txt \
    && useradd --uid 10001 --no-create-home --shell /usr/sbin/nologin recovery

COPY qdrant_recovery.py /app/qdrant_recovery.py
USER 10001:10001
ENTRYPOINT ["python", "/app/qdrant_recovery.py"]
