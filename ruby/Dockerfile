FROM docker.xilopix.net/debian-xilopix
MAINTAINER luiza.orosanu@xilopix.com

RUN apt-get update \
 && apt-get install -y ruby ruby-dev rake \
    make gcc libmagic-dev xz-utils \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/models_details.txt /tmp/ml-resources/models_details.txt
ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/dictionary.txt /tmp/ml-resources/dictionary.txt
ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/model_TFIDF.json /tmp/ml-resources/model_TFIDF.json
ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/model_LSI.bin /tmp/ml-resources/model_LSI.bin
ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/model_LR-multiclass-2c_LSI_offline-1000000.json /tmp/ml-resources/model_LR-multiclass-2c.json
ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/model_LR-multiclass-3c_LSI_offline-1000000.json /tmp/ml-resources/model_LR-multiclass-3c.json
ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/model_MLP-multiclass-2c_LSI_offline-1000000.json /tmp/ml-resources/model_MLP-multiclass-2c.json
ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/model_MLP-multiclass-3c_LSI_offline-1000000.json /tmp/ml-resources/model_MLP-multiclass-3c.json
ADD http://oueb.xilopix.net/ml/models/fr_es1preprod_24102016-22022017_PDLW/model_MLP-multilabel-3c_LSI_offline-1000000.json /tmp/ml-resources/model_MLP-multilabel-3c.json

RUN chown xilopix:xilopix /tmp/ml-resources/*

USER xilopix

RUN gem sources -a https://gem.xilopix.net/
RUN gem install --user-install --development --no-document xi-ml

CMD rake test
