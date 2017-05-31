# -*-coding:utf-8 -*


import json

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import ConfigError


class StreamCorpus(Component):
    """
    StreamCorpus:
    loop through documents without loading data into memory
    """

    def __init__(self, input_file):
        """Initialize with the input filename"""

        super().__init__()

        if not isinstance(input_file, str):
            raise ConfigError(
                "Given parameter {} is not String".format(input_file))

        utils.check_file_readable(input_file)
        self.filename = input_file

    def __iter__(self):
        """Yield one document at a time"""

        with open(self.filename, 'r') as stream:
            for line in stream:
                doc = json.loads(line)
                yield doc
