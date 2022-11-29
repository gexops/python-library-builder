#!/bin/bash

# This script is used to bootstrap the backend configuration for the lotus node.

RUN_MODE=${RUN_MODE:-api}
# api, celery, celery-beat, event-consumer
RUN_CMD=${RUN_CMD:-}
CMD=""

if [[ "$RUN_CMD" != "" ]]; then
    CMD="$RUN_CMD"
    echo " - Running Custom Command: ${CMD}"

elif [[ "$RUN_MODE" == "api" ]]; then
    CMD="sh -c './scripts/start_backend.prod.sh'"
    echo " - Starting: API Server: ${CMD}"

elif [[ "$RUN_MODE" == "event-consumer" ]]; then
    CMD="sh -c './scripts/start_consumer.sh'"
    echo " - Starting: Event Consumer: ${CMD}"

elif [[ "$RUN_MODE" == "celery" ]]; then
    CMD="celery -A lotus worker -l info"
    echo " - Starting: Celery Worker: ${CMD}"

elif [[ "$RUN_MODE" == "celery-beat" ]]; then
    CMD="celery -A lotus beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler"
    echo " - Starting: Celery Beat: ${CMD}"

fi


# run the command
eval $CMD