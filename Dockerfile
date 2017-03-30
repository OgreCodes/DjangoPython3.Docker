FROM python:2.7
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
ADD requirements.txt /code/
run apt-get update \
  && apt-get install -y --no-install-recommends \
	mysql-client \
	nginx \
	supervisor \
  && rm -rf /var/lib/apt/lists/*

RUN pip install -r requirements.txt
RUN rm -rf build

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

#RUN useradd -r -s /bin/false django
#RUN useradd -r -s /bin/false www
