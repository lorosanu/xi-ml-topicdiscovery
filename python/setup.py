# -*-coding:utf-8 -*


import os
import sys
from setuptools import setup, find_packages

lib_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'lib'))
sys.path.append(lib_path)

from xi.ml import version


with open('README', 'r') as f:
  long_description = f.read()

setup(
    name='xi.ml',
    version=version.__version__,
    author='Luiza Orosanu',
    author_email='luiza.orosanu@xilopix.com',
    description='Xilopix Machine-Learning Python project',
    long_description=long_description,

    keywords='transformation and classification',
    package_dir = {'': 'lib'},
    packages=find_packages(),

    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
    ],

    install_requires=[
        'gensim==1.0.1',
        'scikit-learn==0.18.1',
        'pyyaml==3.12',
        'matplotlib==2.0.0',
        'pylint==1.6.5',
        'pytest==3.0.6',
        'wheel==0.29.0',
        'twine==1.8.1'
    ],


    setup_requires=['pytest-runner'],
    tests_require=['pytest'],
)
