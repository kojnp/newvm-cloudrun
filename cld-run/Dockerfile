
FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine

ENV PYTHONUNBUFFERED True
RUN apk add --update py3-pip 

COPY requirements.txt ./
RUN pip3 install -r requirements.txt

RUN mkdir -p /scripts
COPY myscript.sh /scripts
WORKDIR /scripts
RUN chmod +x myscript.sh

ENV APP_HOME /app
WORKDIR $APP_HOME
COPY main.py ./

CMD exec gunicorn --bind :$PORT --workers 1 --threads 8 --timeout 0 main:app
