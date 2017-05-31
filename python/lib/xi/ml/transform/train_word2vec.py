# -*-coding:utf-8 -*


import json
import gensim.models

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import ConfigError

class WordCorpus:
    """Iterate over sentences"""

    def __init__(self, input_files):
        self.files = list(input_files)

        for filename in self.files:
            utils.check_file_readable(filename)

    def __iter__(self):
        """Load tokens from documents stored in json copora"""

        for filename in self.files:                   # each file
            with open(filename, 'r') as stream:
                for line in stream:                   # each line
                    doc = json.loads(line)
                    yield doc['content'].split()

def reformat_wv(words_vector):
    """Change format of words vector"""

    new_wv = {}
    for index, word in enumerate(words_vector.vocab.keys()):
        new_wv[word] = [float(x) for x in words_vector.syn0[index]]

    return new_wv

def filter_words(words_vector, dict_file):
    """Keep only words present in the dictionary"""

    utils.check_file_readable(dict_file)

    words_dictionary = {}
    with open(dict_file, 'r') as stream:
        for line in stream:
            tokens = line.split()
            wordid = int(tokens[0])
            word = str(tokens[1])
            words_dictionary[word] = wordid

    new_wv = {}
    for word, vector in words_vector.items():
        if word in words_dictionary:
            new_wv[words_dictionary[word]] = list(vector)

    return new_wv

class TrainWord2Vec(Component):
    """Class training and saving the word2vec models"""

    OPTIONS = {
        'cbow': {'size':100, 'sg':0, 'min_count':1, 'workers':4},
        'skipgram': {'size':100, 'sg':1, 'min_count':1, 'workers':4}
    }

    def __init__(self, model_name):
        """Initialize the transformation model"""

        super().__init__()

        if model_name.lower() not in self.OPTIONS:
            raise ConfigError(
                "Unknown model name '{}'. Choose from {}"
                .format(model_name, self.OPTIONS.keys()))

        self.model = None
        self.name = model_name.lower()
        self.vsize = self.OPTIONS[self.name]['size']

        self.logger.info(
            "Initialize the {} transformation model".format(self.name))

    def train(self, input_files):
        """Train the transformation model on the given text documents"""

        self.logger.info(
            "Train the {} model on a vector size of {}"
            .format(self.name, self.vsize))

        # load data: split documents into tokens (=> iterable object)
        data = WordCorpus(input_files)

        self.timer.start_timer()
        self.model = gensim.models.Word2Vec(data, **self.OPTIONS[self.name])
        self.timer.stop_timer("Model {} trained".format(self.name))

    def load(self, bin_file):
        self.model = gensim.models.Word2Vec.load(bin_file)

    def save(self, output):
        """
        Save the transformation model to binary file
        (to enable load ability)
        """

        self.check_model()
        utils.create_path(output)
        self.model.save(output)

    def save_shape(self, output, dict_file=None):
        """
        Save the shape of the transformation model to json file
        (for further use in ruby code)
        """

        self.check_model()
        utils.create_path(output)

        # recover words vector from model
        words_vector = self.model.wv

        # reformat it for a more practical use: dictionary word:word_weights
        words_vector = reformat_wv(words_vector)

        # remove unknown words when requested
        if dict_file is not None:
            words_vector = filter_words(words_vector, dict_file)

        self.logger.info(
            "Save {} shape: {}-weigths list for each word"
            .format(self.name, self.vsize))

        with open(output, 'w') as ostream:
            for key, value in words_vector.items():
                ostream.write(json.dumps(
                    {key: list(value)}, ensure_ascii=False) + '\n')

        self.logger.info(
            "Saved {} transformation's model shape under '{}'"
            .format(self.name, output))

    def check_model(self):
        """Check if the model was initialized"""

        if self.model is None:
            raise ConfigError(
                "Failed to build the '{}' model".format(self.name))
