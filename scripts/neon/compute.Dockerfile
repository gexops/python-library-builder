
ARG COMPUTE_IMAGE=compute-node-v14
# ARG TAG=latest
# ARG REPOSITORY=369495373322.dkr.ecr.eu-central-1.amazonaws.com

FROM neondatabase/${COMPUTE_IMAGE}:latest
# FROM $REPOSITORY/${COMPUTE_IMAGE}:$TAG
# FROM neondatabase/compute-node:latest

USER root
RUN apt-get update &&       \
    apt-get install -y curl \
                       jq   \
                       netcat


COPY ./scripts/neon/bootstrap.sh /shell/compute.sh
RUN chmod +x /shell/compute.sh

USER postgres

COPY ./scripts/neon/k8_spec.json /var/db/postgres/specs/spec.json

ENTRYPOINT [ "/shell/compute.sh" ]