# Classify new documents


## Description

* prepare data for training and testing
    - extract the 'id, url, title, content' data from ES based on a list of targeted url hosts
    - split the extracted data into training, validation and testing subsets
    - clean each data subset by aplying different cleaners / filters
* the extracted and cleaned training data is used by the
  *python topic-discovery module* to train the LSI model
  and the LR/MLP classification models; each model is stored under .json format
  for further 'manual' use in the *ruby topic-discovery module*
* use those models to evaluate classification performance on category tagged documents
    - transform clean corpora
    - classify transformed corpora
    - evaluate the accuracy, precision and recall on generated predictions
* example of how to clean, transform and classify raw text documents


## Usage

* ./bin/xi-ml-preparedata [arguments]

    ```
    Object: extract content from  ES, build corpus, clean data
    Usage:  ./bin/xi-ml-preparedata [options]
      -c, --conf CONF        Config file
      -h, --help             Show this message
    ```

* ./bin/xi-ml-evaluatedata [arguments]

    ```
    Object: evaluate classification of known documents
    Usage:  ./bin/xi-ml-evaluatedata [options]
    -c, --conf CONF        Config file
    -h, --help             Show this message
    ```

* ./bin/xi-ml-classify [arguments]

    ```
    Object: preprocess, transform and classify new documents
    Usage:  ./bin/xi-ml-classify [options]
      -i, --input INPUT      Input file
      -c, --conf CONF        Config file
      -h, --help             Show this message
    ```


## Local Execution

Data preparation for document classification tasks
(needed to build and test models)


### Install requirements on your local machine

* check Dockerfile
* check gems/*.gemspec file(s)


### Extract, divide and clean entire corpora

```
./bin/xi-ml-preparedata -c conf/fr/config_preparedata_3categories.yml
```

Configuration

```
:res: /mnt/data/ml/docs/resources/fr/3categories/ssu/
:classes:
  - :society
  - :sport
  - :_UNK_
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
      - :id
      - :lang
      - :site
      - :url
      - :title
      - :content
    :min_nchars: 200
  :hosts:
    :society: ./conf/fr/hosts_3classes/society_hosts.yml
    :sport: ./conf/fr/hosts_3classes/sport_hosts.yml
    :_UNK_: ./conf/fr/hosts_3classes/unk_hosts.yml
  :lang: :fr
  :query_filter: :url-regexp
:build:
  :division:
    :train: 80
    :dev: 10
    :test: 10
  :shuffle: false
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
```

Examples of category hosts configuration files

* ./conf/fr/hosts_3classes/society_hosts.yml

    ```
    ---
    - www.lesechos.fr
    - www.ladepeche.fr
    ```

* ./conf/fr/hosts_3classes/sport_hosts.yml

    ```
    ---
    - www.eurosport.fr
    - www.sport365.fr
    ```

* ./conf/fr/hosts_3classes/unk_hosts.yml

    ```
    ---
    - www.voilesetvoiliers.com
    - www.conseils-courseapied.com
    ```


## Docker Execution

### Extract, divide and clean entire corpora


```
docker-compose run --rm ml-devel ./bin/xi-ml-preparedata \
  -c conf/fr/config_preparedata_3categories.yml
```

Update config file

* the ES's host name is not 'localhost' inside a docker container
* replace the ES's host name with the ip address under docker container

    ```
    docker run --rm ml-devel ip route
    ```


### Document transformation, classification and evaluation of entire corpora

Some examples of transformation and classification models are present
in the docker image, under the /usr/share/xi-ml/td/models/ repository.

```
total 596M
-rw-r--r-- 1 xilopix xilopix  11M Oct 16 14:57 dictionary.json
-rw-r--r-- 1 xilopix xilopix 7.8K Oct 17 11:37 model_LR-multiclass_2c.json
-rw-r--r-- 1 xilopix xilopix  23K Oct 17 11:38 model_LR-multiclass_3c.json
-rw-r--r-- 1 xilopix xilopix  31K Oct 17 11:38 model_LR-multiclass_4c.json
-rw-r--r-- 1 xilopix xilopix 571M Oct 16 14:16 model_LSI.bin
-rw-r--r-- 1 xilopix xilopix 816K Oct 17 15:32 model_MLP-multiclass_2c.json
-rw-r--r-- 1 xilopix xilopix 850K Oct 17 15:32 model_MLP-multiclass_3c.json
-rw-r--r-- 1 xilopix xilopix 852K Oct 17 15:32 model_MLP-multiclass_4c.json
-rw-r--r-- 1 xilopix xilopix 824K Oct 17 15:32 model_MLP-multilabel_2c.json
-rw-r--r-- 1 xilopix xilopix 847K Oct 17 15:32 model_MLP-multilabel_3c.json
-rw-r--r-- 1 xilopix xilopix 851K Oct 17 15:32 model_MLP-multilabel_4c.json
-rw-r--r-- 1 xilopix xilopix 4.8K Oct 17 14:03 models_details.txt
-rw-r--r-- 1 xilopix xilopix  11M Oct 16 14:10 model_TFIDF.json
```

See more details under /usr/share/xi-ml/td/models/models_details.txt


#### Use a LogisticRegression classifier

```
docker-compose run --rm ml-devel ./bin/xi-ml-evaluatedata \
  -c conf/fr/config_docker_evaluate_LR.yml
```

Configuration

```
:res: /mnt/data/ml/docs/resources/fr/3categories/ssu/es1preprod_06102017/
:classes:
  - :society
  - :sport
  - :_UNK_
:preprocess: :PDLW
:execution:
  - :transform
  - :classify
  - :evaluate
:transform:
  :name: :LSI
  :files:
    :dict: /usr/share/xi-ml/td/models/dictionary.json
    :tfidf: /usr/share/xi-ml/td/models/model_TFIDF.json
    :lsi: /usr/share/xi-ml/td/models/model_LSI.bin
:classify:
  :name: :LogisticRegression
  :file: /usr/share/xi-ml/td/models/model_LR-multiclass_3c.json
```

Output

```
INFO [19-10-2017 16:05:20] [xi::ml::classify::predictionstatistics]: Confusion matrix and marginals
               _UNK_   society     sport     total
_UNK_         531515     37439     60964    629918
society        15455    423234     12595    451284
sport          19570      5421    285938    310929
total         566540    466094    359497   1392131

INFO [19-10-2017 16:05:20] [xi::ml::classify::predictionstatistics]: Correctly classified '_UNK_' documents : 531515 / 629918 = 84.38 %
INFO [19-10-2017 16:05:20] [xi::ml::classify::predictionstatistics]: Correctly classified 'society' documents : 423234 / 451284 = 93.78 %
INFO [19-10-2017 16:05:20] [xi::ml::classify::predictionstatistics]: Correctly classified 'sport' documents : 285938 / 310929 = 91.96 %
INFO [19-10-2017 16:05:20] [xi::ml::classify::predictionstatistics]: Correctly classified documents: 1240687 / 1392131 = 89.12 %
INFO [19-10-2017 16:05:20] [xi::ml::classify::predictionstatistics]: Confusion matix, precision, recall for _UNK_
========================================
Class=_UNK_
========================================
      | declare H1 |  declare H0 |
is H1 |     531515 |       98403 |
is H0 |      35025 |      727188 |
----------------------------------------
Precision = 93.82 %
Recall    = 84.38 %

INFO [19-10-2017 16:05:20] [xi::ml::classify::predictionstatistics]: Confusion matix, precision, recall for society
========================================
Class=society
========================================
      | declare H1 |  declare H0 |
is H1 |     423234 |       28050 |
is H0 |      42860 |      897987 |
----------------------------------------
Precision = 90.8 %
Recall    = 93.78 %

INFO [19-10-2017 16:05:20] [xi::ml::classify::predictionstatistics]: Confusion matix, precision, recall for sport
========================================
Class=sport
========================================
      | declare H1 |  declare H0 |
is H1 |     285938 |       24991 |
is H0 |      73559 |     1007643 |
----------------------------------------
Precision = 79.54 %
Recall    = 91.96 %
```


#### Use a Multi-layer Perceptron multiclass classifier

```
docker-compose run --rm ml-devel ./bin/xi-ml-evaluatedata \
  -c conf/fr/config_docker_evaluate_MLP.yml
```

Configuration

```
:res: /mnt/data/ml/docs/resources/fr/3categories/ssu/es1preprod_06102017/
:classes:
  - :society
  - :sport
  - :_UNK_
:preprocess: :PDLW
:execution:
  - :transform
  - :classify
  - :evaluate
:transform:
  :name: :LSI
  :files:
    :dict: /usr/share/xi-ml/td/models/dictionary.json
    :tfidf: /usr/share/xi-ml/td/models/model_TFIDF.json
    :lsi: /usr/share/xi-ml/td/models/model_LSI.bin
:classify:
  :name: :MLPClassifier
  :file: /usr/share/xi-ml/td/models/model_MLP-multiclass_3c.json
```

Output

```
INFO [19-10-2017 16:17:58] [xi::ml::classify::predictionstatistics]: Confusion matrix and marginals
               _UNK_   society     sport     total
_UNK_         609858      9043     11017    629918
society         6913    440357      4014    451284
sport           5645      1600    303684    310929
total         622416    451000    318715   1392131

INFO [19-10-2017 16:17:58] [xi::ml::classify::predictionstatistics]: Correctly classified '_UNK_' documents : 609858 / 629918 = 96.82 %
INFO [19-10-2017 16:17:58] [xi::ml::classify::predictionstatistics]: Correctly classified 'society' documents : 440357 / 451284 = 97.58 %
INFO [19-10-2017 16:17:58] [xi::ml::classify::predictionstatistics]: Correctly classified 'sport' documents : 303684 / 310929 = 97.67 %
INFO [19-10-2017 16:17:58] [xi::ml::classify::predictionstatistics]: Correctly classified documents: 1353899 / 1392131 = 97.25 %
INFO [19-10-2017 16:17:58] [xi::ml::classify::predictionstatistics]: Confusion matix, precision, recall for _UNK_
========================================
Class=_UNK_
========================================
      | declare H1 |  declare H0 |
is H1 |     609858 |       20060 |
is H0 |      12558 |      749655 |
----------------------------------------
Precision = 97.98 %
Recall    = 96.82 %

INFO [19-10-2017 16:17:58] [xi::ml::classify::predictionstatistics]: Confusion matix, precision, recall for society
========================================
Class=society
========================================
      | declare H1 |  declare H0 |
is H1 |     440357 |       10927 |
is H0 |      10643 |      930204 |
----------------------------------------
Precision = 97.64 %
Recall    = 97.58 %

INFO [19-10-2017 16:17:58] [xi::ml::classify::predictionstatistics]: Confusion matix, precision, recall for sport
========================================
Class=sport
========================================
      | declare H1 |  declare H0 |
is H1 |     303684 |        7245 |
is H0 |      15031 |     1066171 |
----------------------------------------
Precision = 95.28 %
Recall    = 97.67 %
```


### Clean, transform and classify raw documents

#### Use a LogisticRegression classifier

```
docker-compose run --rm ml-devel ./bin/xi-ml-classify \
  -i conf/fr/docs.txt \
  -c conf/fr/config_docker_classify_LR.yml
```

Configuration

```
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
  :name: :LSI
  :files:
    :dict: /usr/share/xi-ml/td/models/dictionary.json
    :tfidf: /usr/share/xi-ml/td/models/model_TFIDF.json
    :lsi: /usr/share/xi-ml/td/models/model_LSI.bin
:classify:
  :name: :LogisticRegression
  :file: /usr/share/xi-ml/td/models/model_LR-multiclass_3c.json
```

Output

```
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.739, "society":0.000, "sport":0.260) for document of  65 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class sport     ("_UNK_":0.080, "society":0.133, "sport":0.787) for document of  39 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.636, "society":0.163, "sport":0.202) for document of  73 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.528, "society":0.280, "sport":0.192) for document of  54 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class sport     ("_UNK_":0.327, "society":0.183, "sport":0.489) for document of 102 words in 0.001 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.621, "society":0.119, "sport":0.260) for document of  64 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class sport     ("_UNK_":0.204, "society":0.326, "sport":0.470) for document of 112 words in 0.001 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.482, "society":0.118, "sport":0.400) for document of  99 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.598, "society":0.205, "sport":0.197) for document of  72 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class sport     ("_UNK_":0.109, "society":0.151, "sport":0.740) for document of  49 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.455, "society":0.369, "sport":0.175) for document of 139 words in 0.001 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.711, "society":0.236, "sport":0.054) for document of  86 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class society   ("_UNK_":0.122, "society":0.549, "sport":0.329) for document of  83 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class society   ("_UNK_":0.344, "society":0.528, "sport":0.128) for document of 110 words in 0.000 seconds
INFO [12-10-2017 13:02:41] [xi::ml::tools::timer]: Predicted class society   ("_UNK_":0.345, "society":0.560, "sport":0.095) for document of 242 words in 0.001 seconds
```

#### Use a Multi-layer Perceptron multi-class classifier

```
docker-compose run --rm ml-devel ./bin/xi-ml-classify \
  -i conf/fr/docs.txt \
  -c conf/fr/config_docker_classify_MLP_multiclass.yml
```

Configuration

```
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
  :name: :LSI
  :files:
    :dict: /usr/share/xi-ml/td/models/dictionary.json
    :tfidf: /usr/share/xi-ml/td/models/model_TFIDF.json
    :lsi: /usr/share/xi-ml/td/models/model_LSI.bin
:classify:
  :name: :MLPClassifier
  :file: /usr/share/xi-ml/td/models/model_MLP-multiclass_3c.json
```

Output

```
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.971, "society":0.000, "sport":0.029) for document of  65 words in 0.001 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class sport     ("_UNK_":0.027, "society":0.016, "sport":0.956) for document of  39 words in 0.000 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.793, "society":0.206, "sport":0.001) for document of  73 words in 0.000 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.900, "society":0.037, "sport":0.063) for document of  54 words in 0.000 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.802, "society":0.101, "sport":0.096) for document of 102 words in 0.001 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.640, "society":0.288, "sport":0.072) for document of  64 words in 0.000 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class sport     ("_UNK_":0.073, "society":0.011, "sport":0.916) for document of 112 words in 0.001 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.621, "society":0.011, "sport":0.368) for document of  99 words in 0.001 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.977, "society":0.005, "sport":0.018) for document of  72 words in 0.000 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class sport     ("_UNK_":0.092, "society":0.040, "sport":0.868) for document of  49 words in 0.000 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class society   ("_UNK_":0.121, "society":0.872, "sport":0.007) for document of 139 words in 0.001 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.992, "society":0.007, "sport":0.001) for document of  86 words in 0.000 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class society   ("_UNK_":0.433, "society":0.493, "sport":0.074) for document of  83 words in 0.000 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class society   ("_UNK_":0.147, "society":0.851, "sport":0.002) for document of 110 words in 0.001 seconds
INFO [12-10-2017 13:07:16] [xi::ml::tools::timer]: Predicted class _UNK_     ("_UNK_":0.443, "society":0.385, "sport":0.173) for document of 242 words in 0.001 seconds
```

#### Use a Multi-layer Perceptron multi-label classifier

```
docker-compose run --rm ml-devel ./bin/xi-ml-classify \
  -i conf/fr/docs.txt \
  -c conf/fr/config_docker_classify_MLP_multilabel.yml
```

Configuration

```
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
  :name: :LSI
  :files:
    :dict: /usr/share/xi-ml/td/models/dictionary.json
    :tfidf: /usr/share/xi-ml/td/models/model_TFIDF.json
    :lsi: /usr/share/xi-ml/td/models/model_LSI.bin
:classify:
  :name: :MLPClassifier
  :file: /usr/share/xi-ml/td/models/model_MLP-multilabel_3c.json
```

Output

```
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.000, "sport":0.000, "_UNK_":1.000) for document of  65 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class sport     ("society":0.004, "sport":0.989, "_UNK_":0.050) for document of  39 words in 0.000 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.061, "sport":0.200, "_UNK_":0.422) for document of  73 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.111, "sport":0.033, "_UNK_":0.490) for document of  54 words in 0.000 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.034, "sport":0.069, "_UNK_":0.878) for document of 102 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.021, "sport":0.136, "_UNK_":0.722) for document of  64 words in 0.000 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class sport     ("society":0.061, "sport":0.920, "_UNK_":0.056) for document of 112 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.017, "sport":0.110, "_UNK_":0.899) for document of  99 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.015, "sport":0.005, "_UNK_":0.960) for document of  72 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class sport     ("society":0.148, "sport":0.944, "_UNK_":0.005) for document of  49 words in 0.000 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.209, "sport":0.126, "_UNK_":0.395) for document of 139 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.021, "sport":0.006, "_UNK_":0.911) for document of  86 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class _UNK_     ("society":0.086, "sport":0.049, "_UNK_":0.353) for document of  83 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class society   ("society":0.772, "sport":0.035, "_UNK_":0.052) for document of 110 words in 0.001 seconds
INFO [12-10-2017 13:09:31] [xi::ml::tools::timer]: Predicted class society   ("society":0.683, "sport":0.054, "_UNK_":0.123) for document of 242 words in 0.001 seconds
```


