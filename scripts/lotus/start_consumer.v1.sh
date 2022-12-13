while ! nc -q 1 ${POSTGRES_HOST:-db} ${POSTGRES_PORT:-5432} </dev/null; do sleep 5; done

python3 manage.py event_consumer