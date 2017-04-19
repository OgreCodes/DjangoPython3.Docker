FROM ubuntu:xenial
ENV PYTHONUNBUFFERED 1
RUN mkdir /code
WORKDIR /code
ADD requirements.txt /code/
run apt-get update \
  && apt-get install -y --no-install-recommends \
  	python3 \
	mysql-client \
	nginx \
	supervisor \
	libcurl4-openssl-dev \
	python3-pycurl \
	uwsgi \
	uwsgi-plugin-python3 \
	python3-pip \
	python3-setuptools \
	sqlite3 \
	gdal-bin \
	spatialite-bin \
  && rm -rf /var/lib/apt/lists/*

RUN pip3 install --upgrade pip
RUN pip3 install -r requirements.txt
RUN rm -rf build

RUN echo "daemon off;" >> /etc/nginx/nginx.conf

#RUN useradd -r -s /bin/false django
#RUN useradd -r -s /bin/false www
