ARG REPOSITORY=369495373322.dkr.ecr.eu-central-1.amazonaws.com
ARG COMPUTE_IMAGE=compute-node-v14
ARG TAG=latest

FROM $REPOSITORY/${COMPUTE_IMAGE}:$TAG

USER root
RUN apt-get update &&       \
    apt-get install -y curl \
                       jq   \
                       netcat

USER postgres

COPY ./scripts/neon/bootstrap.sh /shell/compute.sh
COPY ./scripts/neon/k8_spec.json /var/db/postgres/specs/spec.json

RUN chmod +x /shell/compute.sh

ENTRYPOINT [ "/shell/compute.sh" ]