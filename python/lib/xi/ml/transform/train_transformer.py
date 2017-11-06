# -*-coding:utf-8 -*


import json
import gensim.models

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import ConfigError


class TrainTransformer(Component):
    """Class training and saving tfidf/lsi/lda/rp transformation models"""

    TRANSFORMERS = {
        'TFIDF': {
            'model':gensim.models.TfidfModel,
            'kwargs': {}
        },
        'LSI':  {
            'model':gensim.models.LsiModel,
            'kwargs': {'num_topics':300, 'id2word':None, 'distributed':False}
        },
        'LDA': {
            'model':gensim.models.LdaModel,
            'kwargs': {'num_topics':100, 'id2word':None, 'distributed':False}
        },
        'RP': {
            'model':gensim.models.RpModel,
            'kwargs': {'num_topics':500, 'id2word':None}
        }
    }

    def __init__(self, model_name, **kwargs):
        """Initialize the transformation model"""

        super().__init__()

        if model_name.upper() not in self.TRANSFORMERS:
            raise ConfigError(
                "Unknown model name '{}'. Choose from {}"
                .format(model_name, self.TRANSFORMERS.keys()))

        self.model = None
        self.name = model_name.upper()

        # define the model's training configuration
        # update default arguments when new provided
        self.kwargs = dict(self.TRANSFORMERS[self.name]['kwargs'])
        self.kwargs.update(kwargs)

        self.ntopics = self.kwargs.get('num_topics', 0)

        self.logger.info(
            "Initialize the {} transformation model".format(self.name))

    def train(self, corpus, dictionary=None):
        """
        Train the transformation model
        on the given gensim corpus and gensim dictionary
        """

        self.logger.info(
            "Train the {} transformation model on {} topics"
            .format(self.name, self.ntopics))

        # update train argument values for current training configuration
        self.kwargs['corpus'] = corpus
        if 'id2word' in self.kwargs:
            self.kwargs['id2word'] = dictionary

        # train model
        self.timer.start_timer()
        self.model = self.TRANSFORMERS[self.name]['model'](**self.kwargs)
        self.timer.stop_timer("Model {} trained".format(self.name))

        # check changes in model
        self.check_changes()

    def check_changes(self):
        """
        Check if the number of topics changed
        between what was demanded and what was found;
        update if necessary.
        """

        # check number of topics in LSI model
        if self.name == "LSI" \
                and self.ntopics != self.model.projection.u[0].size:

            self.logger.warning(
                "Number of topics changed from {} into {}"
                .format(self.ntopics, self.model.projection.u[0].size))

            self.ntopics = self.model.projection.u[0].size

    def save(self, output):
        """
        Save the transformation model to binary file
        (to enable load ability)
        """

        self.check_model()
        utils.create_path(output)
        self.model.save(output)

    def save_shape(self, output):
        """
        Save the shape of the transformation model to json file
        (for further use in ruby code)
        """

        self.check_model()
        utils.create_path(output)

        desc = ''
        saved = False

        if self.name == 'TFIDF':
            desc = 'list with word_idf weight for each word id'

            model_array = [0.0] * len(self.model.idfs)
            for wid, weight in self.model.idfs.items():
                model_array[int(wid)] = float(weight)

            with open(output, 'w') as ostream:
                json.dump(model_array, ostream, indent=2)

            saved = True
        elif self.name == 'LSI':
            desc = "{}D array for each word id".format(self.ntopics)

            model_array = [[0.0] * self.ntopics] * self.model.num_terms
            for wid in range(self.model.num_terms):
                model_array[int(wid)] = \
                    [float(x) for x in self.model.projection.u[int(wid)]]

            with open(output, 'w') as ostream:
                for weights in model_array:
                    json.dump(weights, ostream)
                    ostream.write('\n')
            saved = True
        else:
            self.logger.warning('Unknown demand. Probably still WIP')

        if saved:
            self.logger.info(
                "Saved {}'s model shape ({}) under '{}'"
                .format(self.name, desc, output))

    def check_model(self):
        """Check if the model was initialized"""

        if self.model is None:
            raise ConfigError(
                "Failed to build the '{}' model".format(self.name))
