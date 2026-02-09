envsubst < /usr/local/etc/redis/users.acl.template > /usr/local/etc/redis/users.acl

# 2. Lancer Redis avec les arguments passés au script (le CMD du Dockerfile)
exec "$@"