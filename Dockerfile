FROM python:3.8

WORKDIR /app

COPY poetry.lock pyproject.toml ./
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir poetry \
 && poetry config virtualenvs.create false \
 && poetry install --no-dev \
 && pip uninstall --yes poetry

COPY . ./
CMD ./ticket_checker/manage.py runserver
