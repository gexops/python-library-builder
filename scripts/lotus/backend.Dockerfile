# ---------------------------------------
# Build
# ---------------------------------------
# FROM --platform=linux/arm64 python:3.9-bullseye AS build
FROM python:3.9-bullseye AS build
ENV PYTHONUNBUFFERED 1
#make lotus user
WORKDIR /lotus
# pip install optimization
COPY Pipfile Pipfile.lock ./
RUN pip install -U --no-cache-dir --disable-pip-version-check pipenv
RUN pipenv install --system --deploy --ignore-pipfile --dev

# Add additional libs
COPY ./extra_requirements.txt /tmp/requirements.txt
RUN pip install -r /tmp/requirements.txt

# copy python files,
COPY ./lotus/ ./lotus/
COPY ./metering_billing/ ./metering_billing/
COPY ./manage.py ./
# ---------------------------------------
# Development
# ---------------------------------------
FROM build AS development
COPY ./pytest.ini ./.coveragerc ./
COPY ./scripts/start_backend.dev.sh ./scripts/start_backend.dev.sh
COPY ./scripts/start_consumer.sh ./scripts/start_consumer.sh

RUN chmod +x ./scripts/start_backend.dev.sh
RUN chmod +x ./scripts/start_consumer.sh
# ---------------------------------------
# Production
# ---------------------------------------
FROM build AS production 

# Update libpq
RUN echo "deb http://apt.postgresql.org/pub/repos/apt bullseye-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y postgresql-14 libpq-dev netcat

COPY ./scripts/start_backend.prod.sh ./scripts/start_backend.prod.sh
RUN chmod +x ./scripts/start_backend.prod.sh

COPY ./scripts/start_consumer.sh ./scripts/start_consumer.sh
RUN chmod +x ./scripts/start_consumer.sh

COPY ./scripts/bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

# ---------------------------------------
# Run
# ---------------------------------------

EXPOSE 8000

ENTRYPOINT [ "/bootstrap.sh" ]