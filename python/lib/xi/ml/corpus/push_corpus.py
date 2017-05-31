# -*-coding:utf-8 -*


import json

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import ConfigError


class PushCorpus(Component):
    """
    PushCorpus:
    store one document at a time into output file
    """

    def __init__(self, output_file):
        """Initialize with the input filename"""

        super().__init__()

        if not isinstance(output_file, str):
            raise ConfigError(
                "Given parameter {} is not a String".format(output_file))

        self.logger.info('Initialized empty corpus')
        self.logger.info("Save new corpus in {} file".format(output_file))

        utils.create_path(output_file)

        self.ofstream = open(output_file, 'w')
        self.size = 0

    def add(self, doc):
        """Store a new document to file"""

        self.ofstream.write(json.dumps(doc, ensure_ascii=False) + '\n')
        self.size += 1

    def close_stream(self):
        """Close the file stream"""

        self.ofstream.close()
