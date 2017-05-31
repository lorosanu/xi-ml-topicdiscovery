# -*-coding:utf-8 -*


from gensim.corpora import MmCorpus
from xi.ml.tools import utils


# Module: save and load corpora in binary format using the gensim MmCorpus lib

def load(input_file):
    """Load a gensim MmCorpus from binary file"""

    utils.check_file_readable(input_file)
    return MmCorpus(input_file)

def save(output, corpus, progress_cnt=1000):
    """Save a gensim MmCorpus to binary file"""

    utils.create_path(output)
    MmCorpus.serialize(output, corpus, progress_cnt=progress_cnt)
