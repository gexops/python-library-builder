
#!/bin/bash
set -eux

# Taken from https://github.com/neondatabase/neon/blob/main/docker-compose/compute_wrapper/shell/compute.sh


PG_VERSION=${PG_VERSION:-14}

SPEC_FILE_ORG=${SPEC_FILE_ORG:-/var/db/postgres/specs/spec.json}
SPEC_FILE=${SPEC_FILE:-/tmp/spec.json}

PAGESERVER_PROTOCOL=${PAGESERVER_PROTOCOL:-http}
PAGESERVER_HOST=${PAGESERVER_HOST:-neon-pageserver.gateways.svc}
PAGESERVER_PORT=${PAGESERVER_PORT:-9898}

PAGESERVER_URL=${PAGESERVER_URL:-"${PAGESERVER_PROTOCOL}://${PAGESERVER_HOST}:${PAGESERVER_PORT}"}
PAGESERVER_PG_PORT=${PAGESERVER_PG_PORT:-6400}

# We'll just use the service name
SAFEKEEPER_HOST=${SAFEKEEPER_HOST:-neon-safekeeper.gateways.svc}
SAFEKEEPER_PORT=${SAFEKEEPER_PORT:-5454}
SAFEKEEPER_CONN=${SAFEKEEPER_CONN:-"${SAFEKEEPER_HOST}:${SAFEKEEPER_PORT}"}
SAFEKEEPER_REPLICAS=${SAFEKEEPER_REPLICAS:-3}


echo "Waiting pageserver become ready on ${PAGESERVER_URL}..."
while ! nc -z ${PAGESERVER_HOST} 6400; do
     sleep 1;
done
echo "Page server is ready."

echo "Create a tenant and timeline"
PARAMS=(
     -sb 
     -X POST
     -H "Content-Type: application/json"
     -d "{}"
     ${PAGESERVER_URL}/v1/tenant/
)
tenant_id=$(curl "${PARAMS[@]}" | sed 's/"//g')

result=$(curl "${PARAMS[@]}")
echo $result | jq .


echo "Overwrite tenant id and timeline id in spec file"
tenant_id=$(echo ${result} | jq -r .tenant_id)
timeline_id=$(echo ${result} | jq -r .timeline_id)

sed "s/TENANT_ID/${tenant_id}/" ${SPEC_FILE_ORG} > ${SPEC_FILE}
sed -i "s/TIMELINE_ID/${timeline_id}/" ${SPEC_FILE}

echo "Overwriting Other Specs"

NEON_PAGESERVER_CONNSTRING=${NEON_PAGESERVER_CONNSTRING:-"host=${PAGESERVER_HOST} port=${PAGESERVER_PG_PORT}"}

sed -i "s/NEON_PAGESERVER_CONNSTRING/${NEON_PAGESERVER_CONNSTRING}/" ${SPEC_FILE}
sed -i "s/NEON_SAFEKEEPERS/${SAFEKEEPER_CONN}/" ${SPEC_FILE}


cat ${SPEC_FILE}

echo "Start compute node"
/usr/local/bin/compute_ctl \
    --pgdata /var/db/postgres/compute \
    -C "postgresql://cloud_admin@localhost:55433/postgres"  \
    -b /usr/local/bin/postgres                              \
    -S ${SPEC_FILE}