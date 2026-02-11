#!/usr/bin/env python3
import glob
import os
import time
import logging
import redis

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

REDIS_HOST = os.getenv("REDIS_HOST", "redis")
REDIS_PORT = int(os.getenv("REDIS_CONTAINER_PORT", "6379"))
REDIS_USER = os.getenv("REDIS_WORKER_USER", "default")
REDIS_PASS = os.getenv("REDIS_WORKER_PASSWORD", "")
REDIS_INIT_KEY = "init:redis"

SCRIPTS_DIR = "/scripts"


def wait_for_redis(client, timeout=60):
    start = time.time()
    while True:
        try:
            if client.ping():
                return
        except redis.RedisError:
            pass
        if time.time() - start > timeout:
            raise RuntimeError("Redis did not become ready in time")
        time.sleep(1)


def load_scripts(client):
    scripts = sorted(glob.glob(os.path.join(SCRIPTS_DIR, "*.lua")))
    for script in scripts:
        name = os.path.basename(script)
        with open(script, "r", encoding="utf-8") as handle:
            content = handle.read()
        logger.info(f"Loading {name}...")
        client.execute_command("FUNCTION", "LOAD", "REPLACE", content)


def main():
    logger.info("Redis init")
    client = redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        username=REDIS_USER,
        password=REDIS_PASS,
        decode_responses=True,
    )

    wait_for_redis(client)

    if client.exists(REDIS_INIT_KEY):
        logger.info(f"Init key already set: {REDIS_INIT_KEY}. Skipping.")
        return

    load_scripts(client)
    client.set(REDIS_INIT_KEY, "1")
    logger.info("Redis libraries loaded.")
    logger.info("Redis init complete")


if __name__ == "__main__":
    main()
