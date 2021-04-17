FROM node AS checker-site

COPY ./ticket_checker/panel/npm /npm
RUN cd /npm \
 && yarn install \
 && yarn run build

FROM python:3.8

WORKDIR /app

COPY poetry.lock pyproject.toml ./
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir poetry \
 && poetry config virtualenvs.create false \
 && poetry install --no-dev \
 && pip uninstall --yes poetry

EXPOSE 80

COPY ./ticket_checker ./ticket_checker
COPY --from=checker-site /static ./ticket_checker/panel/static
CMD ./ticket_checker/manage.py migrate --noinput \
 && ./ticket_checker/manage.py collectstatic --noinput \
 && ./ticket_checker/manage.py runserver 0.0.0.0:80
