FROM python:3.11-slim-bookworm
RUN apt-get update && apt-get install -y --no-install-recommends ffmpeg ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && useradd --create-home --uid 1000 app
WORKDIR /app
COPY processor-source.tar.gz /tmp/pmxp-source.tar.gz
RUN echo 'f9a8664c19de1b8d0bcec6af8fef47a1f01f6020c1c7f6fcfa22dd49a78e99f1  /tmp/pmxp-source.tar.gz' | sha256sum -c - \
    && tar -xzf /tmp/pmxp-source.tar.gz -C /app \
    && rm /tmp/pmxp-source.tar.gz \
    && pip install --no-cache-dir --disable-pip-version-check -r /app/requirements.txt \
    && chown -R app:app /app
ENV PYTHONUNBUFFERED=1 PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app:/app/legacy MINI_PROCESSOR_NETWORK_GUARD=1 \
    PMP_RUNTIME_ROOT=/tmp/pmxp-processor PORT=7860 \
    SITE_ORIGIN=https://pmxp.fun MALLOC_ARENA_MAX=2
USER app
EXPOSE 7860
CMD ["python", "-B", "/app/processor.py"]
