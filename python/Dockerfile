FROM debian:jessie
MAINTAINER luiza.orosanu@xilopix.com

ENV TZ=Europe/Paris

ADD requirements_dev.txt requirements_runtime.txt ./

RUN apt-get update \
 && apt-get install -y build-essential \
 && apt-get install -y python3 python3-dev python3-setuptools \
 && apt-get install -y python3-numpy=1:1.8.2-2 python3-scipy=0.14.0-2 \
 && apt-get install -y python3-pip pylint \
 && pip3 install -U pip setuptools \
 && pip install -r requirements_dev.txt -r requirements_runtime.txt \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

