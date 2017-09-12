# News

## Python Xi-ML 0.2.0 - 08/08/2017
* add a script allowing to train a color classifier (pixel => colorname)
* update docker-compose configuration
* update requirements for pytest

## Python Xi-ML 0.1.0 - 31/05/2017
Initial release

* use gensim to:
  * create dictionary from train data
  * create bag-of-words corpus (word => word_id)
  * train TF-IDF model (word => word_idf_weight)
  * train LSI/LDA/RP vector space models
  * transform documents: apply gensim bow, tf-idf, lsi models
    on documents => features arrays

* use sklearn to:
  * train document classifiers on transformed data
  * classify documents: apply LogisticRegression/MLPClassifier/... model
    on features arrays => category sport/society/...