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
RUN chmod +x ./scripts/start_backend.dev.sh
# ---------------------------------------
# Production
# ---------------------------------------
FROM build AS production 
COPY ./scripts/start_backend.prod.sh ./scripts/start_backend.prod.sh
RUN chmod +x ./scripts/start_backend.prod.sh

COPY ./scripts/bootstrap.sh /bootstrap.sh
# COPY ../../../scripts/lotus/backend_bootstrap.sh /bootstrap.sh
RUN chmod +x /bootstrap.sh

# ---------------------------------------
# Run
# ---------------------------------------

EXPOSE 8000

ENTRYPOINT [ "/bootstrap.sh" ]