# -*-coding:utf-8 -*


import pickle
import numpy

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import CaughtException
from xi.ml.corpus import StreamCorpus, PushCorpus

class LoadClassifier(Component):
    """
    Class used to load classification models
    and to predict class and class-probability for new documents.
    """

    def __init__(self, model_file):
        """Load classifier model from binary file"""

        super().__init__()

        utils.check_file_readable(model_file)

        self.model = None
        with open(model_file, 'rb') as icstream:
            try:
                self.model = pickle.load(icstream)
            except Exception as e:
                raise CaughtException(
                    "Exception encountered when loading the classifier: {}"
                    .format(e))

        self.name = type(self.model).__name__
        self.categories = self.model.classes_

        self.logger.info(
            "Loaded already-trained {} classifier model "
            "from '{}' file".format(self.name, model_file))

    def classify_doc(self, feat):
        """Test the classifier on a new document"""

        if not self.prediction_checkups():
            return ''

        categories = list(self.model.classes_)
        features = [float(x) for x in feat]

        doc_class = self.model.predict([features])
        doc_class = list(doc_class)[0]

        doc_proba = self.model.predict_proba([features])
        doc_proba = dict(zip(categories, list(doc_proba[0])))

        # return real class names when using a multi-label classifier
        if isinstance(doc_class, numpy.ndarray):
            doc_class = [categories[index] \
                for index, val in enumerate(doc_class) if val == 1]

        prediction = {}
        prediction['category'] = doc_class
        prediction['probas'] = doc_proba

        return prediction

    def store_prediction(self, input_file, output_file):
        """
        Test the classifier on 'untagged' documents.
        Store prediction category and prediction probability in file.
        """

        if not self.prediction_checkups():
            return

        utils.check_file_readable(input_file)
        utils.create_path(output_file)

        sc = StreamCorpus(input_file)

        try:
            pc = PushCorpus(output_file)

            for doc in sc:
                if 'features' in doc:
                    prediction = self.classify_doc(doc['features'])

                    if isinstance(prediction, dict) and \
                        'category' in prediction and \
                        'probas' in prediction:

                        doc['season'] = prediction['category']
                        doc['season_prob'] = prediction['probas']
                        pc.add(doc)
        except Exception as e:
            raise CaughtException(
                "Exception encountered when storing classified documents: {}"
                .format(e))
        else:
            self.logger.info("Stored {} documents to file".format(pc.size))
        finally:
            pc.close_stream()

    def prediction_checkups(self):
        """Predictions checkups"""

        if self.model is None:
            self.logger.warning('Null classifier for prediction')
            return False

        if not (
                hasattr(self.model, 'predict') and
                hasattr(self.model, 'predict_proba') and
                callable(self.model.predict) and
                callable(self.model.predict_proba)):

            self.logger.warning(
                "{} classifier can not be used for class prediction"
                .format(self.name))

            return False

        return True
