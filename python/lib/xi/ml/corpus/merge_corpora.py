# -*-coding:utf-8 -*


import json

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import ConfigError

def count_file_lines(filename):
    """Return the number of documents in the input file"""

    ndocs = 0
    with open(filename, 'r') as stream:
        ndocs = sum(1 for line in stream)
    return ndocs

def loop_doc(filename):
    """
    Yield one document at a time from the given file.
    Return only the 'features' and 'category' fields.
    """

    with open(filename, 'r') as stream:
        for line in stream:
            doc = json.loads(line)
            yield (doc['features'], doc['category'])

class MergeCorpora(Component):
    """
    Merge documents corpora;
    input is an array of data filenames: one file for each category (sport, ...)
    => return a data subset containing 'chunk_size' documents from each file.
    (used for sklearn document classification training)
    """

    # List of instance variables:
    # - ndocs: array with the number of documents in each input file
    # - generators: array with generators looping through each input file
    # - stop_index: the index of the last line read from each file

    def __init__(self, input_files):
        """Initialize with the list of filenames"""

        super().__init__()

        if not isinstance(input_files, list):
            raise ConfigError('Given parameter is not a List')
        else:
            for filename in input_files:
                utils.check_file_readable(filename)

        # count the number of documents in each file
        self.ndocs = [count_file_lines(fn) for fn in input_files]
        self.logger.info("Available data for training: {}".format(self.ndocs))

        # create one generator for each input file
        # => return one document at a time from each input file
        self.generators = [loop_doc(filename) for filename in input_files]

        # where we stopped reading from files
        self.stop_index = 0

    def load_data(self, chunk_size=-1):
        """
        Return 'chunk_size' documents from each input file
        """

        # check available remaining data
        min_ndocs = min(self.ndocs)
        left_ndocs = min_ndocs - self.stop_index

        # check if no data left or no data wanted
        if left_ndocs <= 0 or chunk_size == 0:
            return [], []

        # check if we need to load entire remaining data
        if chunk_size == -1 or chunk_size > left_ndocs:
            chunk_size = left_ndocs

        # load data
        requested_features = []
        requested_labels = []

        for _ in range(chunk_size):
            for generator in self.generators:
                features, label = next(generator)
                requested_features.append(features)
                requested_labels.append(label)

            self.stop_index += 1

        return requested_features, requested_labels
