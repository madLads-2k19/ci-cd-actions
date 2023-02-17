FROM python:3.10-alpine as base

ARG APP_NAME
ARG PY_MODULE

ENV PYTHONUNBUFFERED=1
ENV PYTHONFAULTHANDLER=1
ENV MODULE_NAME $PY_MODULE

WORKDIR /app

# ------- Build Image
FROM base as build

ARG POETRY_VERSION=1.3.2
ARG PIP_NO_CACHE_DIR=1
ARG PIP_DEFAULT_TIMEOUT=100

RUN pip install "poetry==${POETRY_VERSION}"
RUN python -m venv /venv

COPY pyproject.toml poetry.lock README.md ./
RUN poetry export -f requirements.txt --without dev | /venv/bin/pip install -r /dev/stdin

ADD ango_auth /app/ango_auth
RUN poetry build && /venv/bin/pip install dist/*.whl

# ------- Final Image
FROM base as final
LABEL org.opencontainers.image.source=https://github.com/madLads-2k19/$APP_NAME

RUN apk add --no-cache libffi libpq
COPY --from=build /venv /venv

CMD . /venv/bin/activate && exec python -m $MODULE_NAME