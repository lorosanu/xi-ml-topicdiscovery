# -*-coding:utf-8 -*


from gensim.corpora import Dictionary
from xi.ml.tools import utils


# Module: load gensim dictionary from file

def load(input_file=None):
    utils.check_file_readable(input_file)
    return Dictionary.load(input_file)
