# -*-coding:utf-8 -*


import re
import json

from gensim.models import LsiModel, LdaModel

from xi.ml.tools import utils
from xi.ml.common import Component
from xi.ml.error import ConfigError


class Topics(Component):
    """
    Class displaying the top 'n' most important words from each topic
    given the transformation model
    """

    known_models = {
        'LSI': LsiModel,
        'LDA': LdaModel
    }

    def __init__(self, model_name, model_file):
        """Load the transformation model"""

        super().__init__()

        model_name = model_name.upper()

        if model_name not in Topics.known_models:
            raise ConfigError(
                "Unknown model name '{}'. Choose from {}"
                .format(model_name, Topics.known_models))

        self.model = Topics.known_models[model_name].load(model_file)

        if self.model is None:
            raise ConfigError(
                "Did not load {} model".format(model_name))

    def save(self, output, n=50):
        """Save the top 'n' words for each topic"""

        self.logger.info("Display the top {} words for each topic".format(n))

        topics = self.model.show_topics(-1, n, log=False)
        wtopics = []
        for _, topic in topics:
            words = re.findall(r'"(.*?)"', topic)
            if words:
                wtopics.append(words)

        utils.create_path(output)
        with open(output, 'w') as ostream:
            json.dump(wtopics, ostream, ensure_ascii=False, indent=2)

        self.logger.info(
            "{} topics saved in '{}' json file'"
            .format(len(wtopics), output))

    def save_positives(self, output, n=50):
        """Save the top 'n' positive words for each topic"""

        self.logger.info(
            "Display the top {} positive words for each topic".format(n))

        topics = self.model.show_topics(-1, 10000, log=False, formatted=False)

        wtopics = []
        for _, topic in topics:
            words = []
            for word, weight in topic:
                word = str(word)
                weight = float(weight)

                if weight > 0 and len(words) < n:
                    words.append(word)

                if len(words) >= n:
                    break

            wtopics.append(words)

        with open(output, 'w') as ostream:
            json.dump(wtopics, ostream, ensure_ascii=False, indent=2)

        self.logger.info(
            "{} topics saved in '{}' json file'"
            .format(len(wtopics), output))
