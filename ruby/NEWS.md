# News

## Xi-ML 0.4.0 - 03/04/2017
* update code
    - use stricter rules in the punctuation cleaner
* optimise code
    - speed up the LSI transformer lib
* add execution scripts
    - to transform documents from json corpora
    - to classify documents from json corpora and evaluate predictions
* add new features
    - add a new class to split badly formatted 'upcase' words
      (for words like 'JOURNEEJeudi')
    - add a new class to format the document's url, text or nlp content
      (extract possible usefull words)
    - add prefix and regex based queries to match urls list
    - include a lemmatizer into the NLP preprocessing lib
      and add lemma-based filters
    - add a new class for an MLP classifier (multiclass & multilabel)

## Xi-ML 0.3.0 - 02/02/2017
* fix code after review
    - use constants where needed
    - fix method names inconsistencies in 'utils'
    - remove duplicate code in corpus based classes
    - update 'process_nlp' method in data_fetcher (with respect to 'pos_inc')
    - separate transformer class into transformer & lsi_transformer classes
    - separate classifier class into classifier & lr_classifier classes
    - update nlp configuration file

## Xi-ML 0.2.0 - 29/12/2016
* convert lsi model from json format into binary format
    - model size: 3.5GB => 0.6GB
* use binary lsi model to transform documents
    - model load time: 1' => 17sec

## Xi-ML 0.1.0 - 22/12/2016
Initial release

* extract documents from ES based on a list of urls
* build train, dev, test corpora
* preprocess data: remove punctuation/digits/extra whitespaces, lowercase chars
* preprocess data with nlp filtering: keep only stems of nouns/nouns&verbs words
* transform documents: apply gensim bow, tf-idf, lsi models on documents
  => features arrays
* classify documents: apply sklearn LogisticRegression model on features arrays
  => category sport/_unk_
