FROM docker.xilopix.net/debian-xilopix
MAINTAINER luiza.orosanu@xilopix.com

RUN apt-get update \
 && apt-get install -y ruby ruby-dev rake \
    make gcc libmagic-dev xz-utils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /usr/share/xi-ml/td/models/ && chown -R xilopix:xilopix /usr/share/xi-ml/td/models/
RUN wget -qO- http://oueb.xilopix.net/ml/caid_models/docs/archives/25092017/models_based_on_LSI=fr-UPDLW-38Mdocs-500kwords-299topics-25092017.tar.xz | tar -xJ -C /usr/share/xi-ml/td/models/

USER xilopix

RUN gem sources -a https://gem.xilopix.net/
RUN gem install --user-install --development --no-document xi-ml

CMD rake test
