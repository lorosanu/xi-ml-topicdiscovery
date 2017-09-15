#!/usr/bin/env python3
# -*-coding:utf-8 -*


import os
import sys

lib_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'lib'))
sys.path.append(lib_path)

from xi.ml import version

master_doc = 'index'
html_theme = 'sphinx_rtd_theme'

extensions = ['sphinx.ext.autodoc', 'sphinx.ext.viewcode']
source_parsers = {'.md': 'recommonmark.parser.CommonMarkParser'}
source_suffix = ['.rst', '.md']

project = 'xi.ml'
release = version.__version__
version = version.__version__
author = 'Luiza Orosanu'
