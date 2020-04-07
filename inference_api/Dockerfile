FROM python:3.8-buster

RUN apt-get -y update && apt-get -y install tesseract-ocr libtesseract-dev

RUN python -m pip install --upgrade pip poetry
RUN poetry config virtualenvs.create false

WORKDIR /usr/src/app
ENV PYTHONPATH "${PYTHONPATH}:/usr/src/app"

COPY pyproject.toml .
COPY poetry.lock .
RUN poetry install

COPY . .

EXPOSE 5000

ENTRYPOINT [ "poetry", "run" ]
CMD [ "python", "./api.py"]
