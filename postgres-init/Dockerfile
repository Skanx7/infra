FROM alpine:3.19

RUN apk add --no-cache postgresql-client bash

WORKDIR /app

COPY ./init-db/ /app/init-db/

# Copy entrypoint script
COPY ./entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

CMD ["/app/entrypoint.sh"]
