FROM astral/uv:python3.12-bookworm-slim

WORKDIR /app

RUN uv pip install --system redis

COPY init.py ./init.py
COPY scripts/ /scripts/

ENTRYPOINT ["python3", "init.py"]



