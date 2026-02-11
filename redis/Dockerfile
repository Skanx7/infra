FROM redis:8-alpine

# require for envsubst
RUN apk add --no-cache gettext

ENV REDIS_CONF_DIR=/usr/local/etc/redis

RUN mkdir -p ${REDIS_CONF_DIR} && \
    chown -R redis:redis ${REDIS_CONF_DIR}

COPY --chown=redis:redis redis.conf ${REDIS_CONF_DIR}/redis.conf
COPY --chown=redis:redis users.acl.template ${REDIS_CONF_DIR}/users.acl.template
COPY --chown=redis:redis entrypoint.sh /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/entrypoint.sh

VOLUME /data

EXPOSE 6379

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]