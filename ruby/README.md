# Classify new documents


## Description

* clean the input documents
* transform the cleaned documents
* classify the transformed documents


## Usage

* ./bin/xi-ml-classify [arguments]

  Object: preprocess, transform and classify new documents
  Usage:  ./bin/xi-ml-classify [options]
    -i, --input INPUT      Input file
    -c, --conf CONF        Config file
    -h, --help             Show this message


## Execution

#### Docker execution: models present in docker image (under /tmp/ml-resources/)

* Document classification with a LogisticRegression classifier

  docker-compose run --rm ml-devel ./bin/xi-ml-classify \
    -i conf/fr/docs.txt \
    -c conf/fr/config_docker_classify_LR.yml

  Configuration
    :execution:
      - :clean
      - :transform
      - :classify
    :clean:
      - :name: Xi::ML::Preprocess::Cleaner::PunctCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::DigitCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::LowercaseCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::WhitespaceCleaner
        :args:
    :transform:
      :name: LSI
      :files:
        :dict: /tmp/ml-resources/dictionary.txt
        :tfidf: /tmp/ml-resources/model_TFIDF.json
        :lsi: /tmp/ml-resources/model_LSI.bin
    :classify:
      :name: LogisticRegression
      :file: /tmp/ml-resources/model_LR-multiclass-2c.json

  Output
    INFO [01-02-2017 15:20:34] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9802726, "non-sport":0.0197274) for document of 65 words in 0.004 seconds
    INFO [01-02-2017 15:20:34] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.6432293, "non-sport":0.3567707) for document of 39 words in 0.003 seconds
    INFO [01-02-2017 15:20:34] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9584984, "non-sport":0.0415016) for document of 73 words in 0.004 seconds
    INFO [01-02-2017 15:20:34] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.8141999, "non-sport":0.1858001) for document of 54 words in 0.003 seconds
    INFO [01-02-2017 15:20:34] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9535165, "non-sport":0.0464835) for document of 102 words in 0.006 seconds
    INFO [01-02-2017 15:20:34] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.940616,  "non-sport":0.059384)  for document of 64 words in 0.003 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.4620142, "non-sport":0.5379858) for document of 112 words in 0.007 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.85675,   "non-sport":0.14325)   for document of 99 words in 0.005 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.8782199, "non-sport":0.1217801) for document of 72 words in 0.004 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9498788, "non-sport":0.0501212) for document of 49 words in 0.003 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.2633787, "non-sport":0.7366213) for document of 139 words in 0.007 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.4866169, "non-sport":0.5133831) for document of 86 words in 0.004 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.3979557, "non-sport":0.6020443) for document of 83 words in 0.004 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.0226956, "non-sport":0.9773044) for document of 110 words in 0.007 seconds
    INFO [01-02-2017 15:20:35] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.2689223, "non-sport":0.7310777) for document of 242 words in 0.012 seconds


* Document classification with a Multi-layer Perceptron classifier

  docker-compose run --rm ml-devel ./bin/xi-ml-classify \
    -i conf/fr/docs.txt \
    -c conf/fr/config_docker_classify_MLP.yml

  Configuration
    :execution:
      - :clean
      - :transform
      - :classify
    :clean:
      - :name: Xi::ML::Preprocess::Cleaner::PunctCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::DigitCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::LowercaseCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::WhitespaceCleaner
        :args:
    :transform:
      :name: LSI
      :files:
        :dict: /tmp/ml-resources/dictionary.txt
        :tfidf: /tmp/ml-resources/model_TFIDF.json
        :lsi: /tmp/ml-resources/model_LSI.bin
    :classify:
      :name: MLPClassifier
      :file: /tmp/ml-resources/model_MLP-multiclass-2c.json

  Output
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9997933, "non-sport":0.0002067) for document of 65 words in 0.005 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9979418, "non-sport":0.0020582) for document of 39 words in 0.004 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9357487, "non-sport":0.0642513) for document of 73 words in 0.005 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9943826, "non-sport":0.0056174) for document of 54 words in 0.004 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9941475, "non-sport":0.0058525) for document of 102 words in 0.008 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9981075, "non-sport":0.0018925) for document of 64 words in 0.004 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.8626387, "non-sport":0.1373613) for document of 112 words in 0.009 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9995038, "non-sport":0.0004962) for document of 99 words in 0.007 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9987927, "non-sport":0.0012073) for document of 72 words in 0.005 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class sport     ("sport":0.9998974, "non-sport":0.0001026) for document of 49 words in 0.003 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.0597105, "non-sport":0.9402895) for document of 139 words in 0.010 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.0768734, "non-sport":0.9231266) for document of 86 words in 0.005 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.0318259, "non-sport":0.9681741) for document of 83 words in 0.005 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class non-sport ("sport":1.0e-07,   "non-sport":0.9999999) for document of 110 words in 0.007 seconds
    INFO [16-02-2017 10:06:41] [xi::ml::tools::timer]: Predicted class non-sport ("sport":0.0003728, "non-sport":0.9996272) for document of 242 words in 0.015 seconds


#### Docker execution: clean new documents WITH NLP preprocessing

  docker-compose run --rm ml-nlp-devel ./bin/xi-ml-classify \
      -i conf/fr/docs.txt \
      -c conf/fr/config_docker_clean_NLP.yml

  Configuration
    :execution:
      - :clean
    :clean:
      - :name: Xi::ML::Preprocess::Cleaner::NLPCleaner
        :args:
          :lang: fr
          :filter: Xi::ML::Preprocess::Filter::PosNVFilter
      - :name: Xi::ML::Preprocess::Cleaner::PunctCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::DigitCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::LowercaseCleaner
        :args:
      - :name: Xi::ML::Preprocess::Cleaner::WhitespaceCleaner
        :args:

  Output
  INFO [02-02-2017 10:07:12] [xi::ml]: Clean documents
  INFO [02-02-2017 10:07:12] [xi::ml::tools::timer]: Document of 65 words cleaned in 0.051 seconds
  INFO [02-02-2017 10:07:12] [xi::ml]: semain refus xav hernand rejoindr new york city andre pirlo aur accept offre rejoindr club fond vient entrer championnat as vétéran milieu terrain va jou samed match couleur juventus lor final ligu champion
  INFO [02-02-2017 10:07:12] [xi::ml::tools::timer]: Document of 39 words cleaned in 0.025 seconds
  INFO [02-02-2017 10:07:12] [xi::ml]: san antonio a officialis mercred prolong bail gregg popovich entraîneur champion titr command franchis a sign contrat anné term ont été rével
  INFO [02-02-2017 10:07:12] [xi::ml::tools::timer]: Document of 73 words cleaned in 0.030 seconds
  INFO [02-02-2017 10:07:12] [xi::ml]: om affront bordeau dimanch vélodrom compt em journ ligu choc europ devr disput rod fann bless rem classiqu revanch provenc mario lemin dimitr payet touch toulous final coup ligu devr postul plac group match fac girondin
  INFO [02-02-2017 10:07:12] [xi::ml::tools::timer]: Document of 54 words cleaned in 0.033 seconds
  INFO [02-02-2017 10:07:12] [xi::ml]: group avant blin szarzewsk correi roncero marconnet attoub marchois tchal watchou vigouroux taylor mau bergamasco leguizamon pariss rabadan arrier oelschig bouhraou beaux hernand bouss bastareaud liebenberg mir bergamasco gasni ari saubad camar


# Data preparation for document classification tasks (needed to build models)


## Description

* extract the 'id, url, title, content' data from ES
  based on a list of targeted url hosts
* split the extracted data into training, validation and testing subsets
* clean each data subset by aplying different cleaners / filters


## Usage

* ./bin/xi-ml-preparedata [arguments]

  Object: extract content from  ES, build corpus, clean data
  Usage:  ./bin/xi-ml-preparedata [options]
    -c, --conf CONF        Config file
    -h, --help             Show this message


## Execution

#### Install requirements on your local machine
* check Dockerfile and gems/*.gemspec file(s)


#### Local execution: extract, divide and clean data WITHOUT NLP preprocessing

* Usage example
    ./bin/xi-ml-preparedata -c conf/fr/config_preparedata.yml

* Configuration
    :res: /mnt/data/ml/resources/
    :lang: fr
    :classes:
      - sport
      - non-sport
    :execution:
      - :extract
      - :build
      - :clean
    :extract:
      :es:
        :name: es1preprod
        :ip: localhost
        :host: localhost
        :port: '9223'
      :esquery:
        :index:
          - article
          - product
        :type:
          - content
        :source:
          - id
          - lang
          - site
          - url
          - title
          - content
        :min_nchars: 200
      :hosts:
        sport: ./conf/fr/hosts_2classes/sport_hosts.yml
        non-sport: ./conf/fr/hosts_2classes/non-sport_hosts.yml
      :query_filter: host
    :build:
      :division:
        :train: 80
        :dev: 10
        :test: 10
    :clean:
      :preprocs:
        :PDLW:
          - :name: Xi::ML::Preprocess::Cleaner::PunctCleaner
            :args:
          - :name: Xi::ML::Preprocess::Cleaner::DigitCleaner
            :args:
          - :name: Xi::ML::Preprocess::Cleaner::LowercaseCleaner
            :args:
          - :name: Xi::ML::Preprocess::Cleaner::WhitespaceCleaner
            :args:

* Hosts config examples:

  * ./conf/fr/hosts_2classes/sport_hosts.yml
    ---
    - "http://www.lequipe.fr/",
    - "http://www.sports.fr/"

  * ./conf/fr/hosts_2classes/non-sport_hosts.yml
    ---
    - "http://actu.cotetoulouse.fr/",
    - "http://epinalinfos.fr",


#### Docker execution: extract, divide and clean data WITHOUT NLP preprocessing

* Usage example
    docker-compose run --rm ml-devel \
      ./bin/xi-ml-preparedata -c conf/fr/config_preparedata.yml

* Update config file
    - the ES's host name is not 'localhost' inside a docker container
    - replace the ES's host name with the local pc's ip address
      Run: docker run --rm ml-devel ip route


#### Docker execution: clean data WITH NLP preprocessing

* Usage example
    (NLP based docker image; used only for cleaning data)

    docker-compose run --rm ml-nlp-devel ./bin/xi-ml-preparedata \
      -c conf/fr/config_docker_preparedata-NLP.yml

* Configuration
    :res: /mnt/data/ml/resources/
    :version: es1preprod_24102016
    :lang: fr
    :classes:
      - sport
      - non-sport
    :execution:
      - :clean
    :clean:
      :preprocs:
        :NS-PDLW:
          - :name: Xi::ML::Preprocess::Cleaner::NLPCleaner
            :args:
              :lang: fr
              :filter: Xi::ML::Preprocess::Filter::OnlyStemsFilter
          - :name: Xi::ML::Preprocess::Cleaner::PunctCleaner
            :args:
          - :name: Xi::ML::Preprocess::Cleaner::DigitCleaner
            :args:
          - :name: Xi::ML::Preprocess::Cleaner::LowercaseCleaner
            :args:
          - :name: Xi::ML::Preprocess::Cleaner::WhitespaceCleaner
            :args:


# Evaluate classification performance of known documents

## Description

* transform clean corpora
* classify transformed corpora
* evaluate the accuracy, precision and recall on generated predictions


## Usage

* ./bin/xi-ml-evaluatedata [arguments]

  Object: evaluate classification of known documents
  Usage:  ./bin/xi-ml-evaluatedata [options]
    -c, --conf CONF        Config file
    -h, --help             Show this message


## Execution

#### Docker execution: classify known document (models present in docker image)

* Document classification with a LogisticRegression classifier

  docker-compose run --rm ml-devel ./bin/xi-ml-evaluatedata \
    -c conf/fr/config_docker_evaluate_LR.yml

  Configuration
    :res: /mnt/data/ml/resources/fr/es1preprod_24102016/
    :classes:
      - sport
      - non-sport
    :preprocess: PDLW
    :execution:
      - :transform
      - :classify
      - :evaluate
    :transform:
      :name: LSI
      :files:
        :dict: /tmp/ml-resources/dictionary.txt
        :tfidf: /tmp/ml-resources/model_TFIDF.json
        :lsi: /tmp/ml-resources/model_LSI.bin
    :classify:
      :name: LogisticRegression
      :file: /tmp/ml-resources/model_LR-multiclass-2c.json

  Output
    INFO [16-02-2017 11:43:25] [xi::ml::classify::predictionstatistics]: Correctly classified documents of class=sport: 105004 / 110761 = 94.80
    INFO [16-02-2017 11:43:25] [xi::ml::classify::predictionstatistics]: Correctly classified documents of class=non-sport: 115746 / 125792 = 92.01
    INFO [16-02-2017 11:43:25] [xi::ml::classify::predictionstatistics]: Correctly classified documents: 220750 / 236553 = 93.32
    INFO [16-02-2017 11:43:25] [xi::ml::classify::predictionstatistics]: Confusion matix, precision and recall stats for the sport class:
    ========================================
    Class=sport
    ========================================
          | declare H1 |  declare H0 |
    is H1 |     105004 |        5757 |
    is H0 |      10046 |      115746 |
    ----------------------------------------
    Precision = 91.27
    Recall    = 94.80

    INFO [16-02-2017 11:43:25] [xi::ml::classify::predictionstatistics]: Confusion matix, precision and recall stats for the non-sport class:
    ========================================
    Class=non-sport
    ========================================
          | declare H1 |  declare H0 |
    is H1 |     115746 |       10046 |
    is H0 |       5757 |      105004 |
    ----------------------------------------
    Precision = 95.26
    Recall    = 92.01


* Document classification with a Multi-layer Perceptron classifier

  docker-compose run --rm ml-devel ./bin/xi-ml-evaluate \
    -c conf/fr/config_docker_evaluate_MLP.yml

  Configuration
    :res: /mnt/data/ml/resources/fr/es1preprod_24102016/
    :classes:
      - sport
      - non-sport
    :preprocess: PDLW
    :execution:
      - :transform
      - :classify
      - :evaluate
    :transform:
      :name: LSI
      :files:
        :dict: /tmp/ml-resources/dictionary.txt
        :tfidf: /tmp/ml-resources/model_TFIDF.json
        :lsi: /tmp/ml-resources/model_LSI.bin
    :classify:
      :name: LogisticRegression
      :file: /tmp/ml-resources/model_MLP-multiclass-2c.json

  Output
    INFO [16-02-2017 11:36:36] [xi::ml::classify::predictionstatistics]: Correctly classified documents of class=sport: 107167 / 110761 = 96.76
    INFO [16-02-2017 11:36:36] [xi::ml::classify::predictionstatistics]: Correctly classified documents of class=non-sport: 119453 / 125792 = 94.96
    INFO [16-02-2017 11:36:36] [xi::ml::classify::predictionstatistics]: Correctly classified documents: 226620 / 236553 = 95.80
    INFO [16-02-2017 11:36:36] [xi::ml::classify::predictionstatistics]: Confusion matix, precision and recall stats for the sport class:
    ========================================
    Class=sport
    ========================================
          | declare H1 |  declare H0 |
    is H1 |     107167 |        3594 |
    is H0 |       6339 |      119453 |
    ----------------------------------------
    Precision = 94.42
    Recall    = 96.76

    INFO [16-02-2017 11:36:36] [xi::ml::classify::predictionstatistics]: Confusion matix, precision and recall stats for the non-sport class:
    ========================================
    Class=non-sport
    ========================================
          | declare H1 |  declare H0 |
    is H1 |     119453 |        6339 |
    is H0 |       3594 |      107167 |
    ----------------------------------------
    Precision = 97.08
    Recall    = 94.96
