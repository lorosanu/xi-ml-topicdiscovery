# -*-coding:utf-8 -*


import json

from gensim.corpora import TextCorpus, Dictionary

from xi.ml.common import Component
from xi.ml.error import ConfigError


class LoadCorpora(Component, TextCorpus):
    """
    Load corpus:
    input is an array with a list of json files
    """

    def __init__(self, input_files=None):
        """Redefine the gensim's TextCorpus init method"""

        super().__init__()

        self.input = input_files
        self.dictionary = Dictionary(prune_at=5000000)
        self.metadata = False
        if input_files is not None:
            self.dictionary.add_documents(self.get_texts(), prune_at=5000000)
        else:
            self.logger.warning(
                "No input document stream provided; assuming "
                "dictionary will be initialized some other way.")

    def get_texts(self):
        """
        Iterate through documents:
        yield each token on each document
        """

        if not isinstance(self.input, list):
            raise ConfigError('Input argument is not a List')

        for filename in self.input:                  # each file
            with open(filename, 'r') as stream:
                for line in stream:                  # each line
                    doc = json.loads(line)
                    yield doc['content'].split()     # split on each word

    def __iter__(self):
        """
        Iterate through documents:
        yield the bow representation of each document
        """

        if not isinstance(self.input, list):
            raise ConfigError('Input argument is not a List')

        for filename in self.input:                  # each file
            with open(filename, 'r') as stream:
                for line in stream:                  # each line
                    doc = json.loads(line)
                    yield self.dictionary.doc2bow(doc['content'].split())

    def save(self):
        """Override abstract method"""
        return

    def save_corpus(self, fname, corpus, id2word=None, metadata=False):
        """Override abstract method"""
        return
