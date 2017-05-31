# -*-coding:utf-8 -*


import gensim.models

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import ConfigError, CaughtException
from xi.ml.corpus import dictionary
from xi.ml.corpus import StreamCorpus, PushCorpus


class LoadTransformer(Component):
    """Transformer class to transform data into the current vector space"""

    TRANSFORMERS = {
        'TFIDF': gensim.models.TfidfModel,
        'LSI': gensim.models.LsiModel,
        'LDA': gensim.models.LdaModel,
        'RP': gensim.models.RpModel
    }

    def __init__(self, model_name, model_file):
        """Initialize the transformation model"""

        super().__init__()

        if model_name.upper() not in self.TRANSFORMERS:
            raise ConfigError(
                "Unknown model name '{}'. Choose from {}"
                .format(model_name, self.TRANSFORMERS.keys()))

        utils.check_file_readable(model_file)

        self.name = model_name.upper()
        self.model = self.TRANSFORMERS[self.name].load(model_file)

        self.ntopics = 0

        if hasattr(self.model, 'num_topics'):
            self.ntopics = self.model.num_topics

        if self.name == "LSI" \
                and self.ntopics != self.model.projection.u[0].size:
            self.ntopics = self.model.projection.u[0].size

        self.logger.info("Loaded {} transformation model".format(self.name))

    def transform(self, corpus):
        """Apply the transformation model on the given gensim corpus"""

        self.check_model()

        if self.name == "TFIDF":
            return self.model[corpus]

        full_corpus = []
        transformed_corpus = self.model[corpus]

        # set weight 0.0 for missing features in transformed document
        # doc = array of tuples (index, weight)
        for doc in transformed_corpus:
            dictdoc = dict(doc)
            full_corpus.append(
                [dictdoc.get(i, 0.0) for i in range(self.ntopics)])

        return full_corpus

    def transform_doc(self, cdictionary, tfidf_model, doc, doc_id=-1):
        """
        Apply the transformation model on the given document.
        Return the features array.
        """

        self.check_model()

        features = None

        # transform document into bag-of-words format
        bow_content = cdictionary.doc2bow(doc.split())

        # extract features
        if self.name == 'LDA':
            features = self.model[bow_content]
        else:
            # first, transform bow content into tf-idf format
            tfidf_content = tfidf_model[bow_content]
            features = self.model[tfidf_content]

        if features:
            # set weight 0.0 for missing features in transformed document;
            # features = array of tuples (index, weight)
            featdict = dict(features)
            return [featdict.get(i, 0.0) for i in range(self.ntopics)]

        self.logger.warning(
            "No features generated for the content '{}'. Document id={}."
            .format(doc, doc_id))

        return [0.0] * self.ntopics

    def store_transformation(
            self, input_file, output_file, dict_file, tfidf_file):

        """
        Apply the transformation model on the given hash documents.
        Store transformed 'features' in file.
        """

        self.check_model()

        utils.check_file_readable(dict_file)
        cdictionary = dictionary.load(dict_file)

        tfidf_model = None
        if self.name != 'LDA':
            utils.check_file_readable(tfidf_file)
            tfidf_model = self.TRANSFORMERS['TFIDF'].load(tfidf_file)

        sc = StreamCorpus(input_file)

        try:
            pc = PushCorpus(output_file)

            for doc in sc:
                if 'content' in doc and 'id' in doc:
                    doc['features'] = self.transform_doc(
                        cdictionary, tfidf_model, doc['content'], doc['id'])
                    pc.add(doc)
        except Exception as e:
            raise CaughtException(
                "Exception encountered when storing transformed documents: {}"
                .format(e))
        else:
            self.logger.info("Stored {} documents to file".format(pc.size))
        finally:
            pc.close_stream()

    def check_model(self):
        """Check if the model was properly loaded"""

        if self.model is None:
            raise ConfigError(
                "Null {} transformation model".format(self.name))
