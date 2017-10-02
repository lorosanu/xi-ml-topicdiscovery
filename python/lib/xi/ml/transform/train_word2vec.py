# -*-coding:utf-8 -*


import json
import gensim.models

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import ConfigError

def reformat_wv(words_vector):
    """Change format of words vector"""

    new_wv = {}
    for index, word in enumerate(words_vector.vocab.keys()):
        new_wv[word] = [float(x) for x in words_vector.syn0[index]]

    return new_wv

def read_dictionary(dict_file):
    """Read the word - word_id dictionary"""

    utils.check_file_readable(dict_file)

    word_dictionary = {}
    with open(dict_file, 'r') as stream:
        for line in stream:
            tokens = line.split()
            if len(tokens) == 3:
                word_id = int(tokens[0])
                word = str(tokens[1])
                word_dictionary[word_id] = word

    return word_dictionary

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

class TrainWord2Vec(Component):
    """Class training and saving the word2vec models"""

    TRANSFORMERS = {
        'cbow': {'size':100, 'sg':0, 'min_count':1, 'workers':4},
        'skipgram': {'size':100, 'sg':1, 'min_count':1, 'workers':4}
    }

    def __init__(self, model_name, **kwargs):
        """Initialize the transformation model"""

        super().__init__()

        if model_name.lower() not in self.TRANSFORMERS:
            raise ConfigError(
                "Unknown model name '{}'. Choose from {}"
                .format(model_name, self.TRANSFORMERS.keys()))

        self.model = None
        self.name = model_name.lower()

        # define the model's training configuration
        # update default arguments when new provided
        self.kwargs = dict(self.TRANSFORMERS[self.name])
        self.kwargs.update(kwargs)

        self.vsize = self.kwargs['size']

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
        self.model = gensim.models.Word2Vec(data, **self.kwargs)
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

        # recover words vector from model
        # reformat it for a more practical use: dictionary word:word_weights
        words_vector = reformat_wv(self.model.wv)

        self.logger.info(
            "Save {} shape: {}-weigths list for each word"
            .format(self.name, self.vsize))

        utils.create_path(output)

        if dict_file is not None:
            # remove unknown words when requested
            words_vector = self.filter_words(words_vector, dict_file)
            with open(output, 'w') as ostream:
                for value in words_vector:
                    json.dump(value, ostream)
                    ostream.write('\n')
        else:
            # keep all words present in the model
            with open(output, 'w') as ostream:
                for key, value in words_vector.items():
                    json.dump({key: list(value)}, ostream, ensure_ascii=False)
                    ostream.write('\n')

        self.logger.info(
            "Saved {} transformation's model shape under '{}'"
            .format(self.name, output))

    def filter_words(self, words_vector, dict_file):
        """Keep only words present in the dictionary"""

        wdict = read_dictionary(dict_file)

        emptyw = 0
        max_id = max(wdict.keys()) + 1

        new_wv = []
        for word_id in range(max_id):
            if word_id in wdict and wdict[word_id] in words_vector:
                new_wv.append(list(words_vector[wdict[word_id]]))
            else:
                new_wv.append([0.0] * self.vsize)
                emptyw += 1

        self.logger.info("Found {} missing word transformations".format(emptyw))

        return new_wv

    def check_model(self):
        """Check if the model was initialized"""

        if self.model is None:
            raise ConfigError(
                "Failed to build the '{}' model".format(self.name))
