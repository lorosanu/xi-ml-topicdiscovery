# -*-coding:utf-8 -*


import json

from gensim.corpora import Dictionary
from xi.ml.tools import utils

# Module: load gensim dictionary from file

def load(input_file=None):
    utils.check_file_readable(input_file)
    return Dictionary.load(input_file)

def load_and_save_as_json(input_file, output_file):
    cdict = Dictionary.load(input_file)

    rdict = {}
    for wid in sorted(cdict.keys()):
        rdict[cdict[wid]] = wid

    utils.create_path(output_file)
    with open(output_file, 'w') as ostream:
        json.dump(rdict, ostream, indent=2, sort_keys=True, ensure_ascii=False)
