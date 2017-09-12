# -*-coding:utf-8 -*


import os
import sys
from setuptools import setup, find_packages

lib_path = os.path.abspath(os.path.join(os.path.dirname(__file__), 'lib'))
sys.path.append(lib_path)

from xi.ml import version
from xi.ml.error import ConfigError

def get_requirements(source):
    if not os.path.exists(source):
        raise ConfigError("Requirements file {} is missing".format(source))

    with open(source, 'r') as f:
        return [req.strip() for req in f]

setup(
    name='xi.ml',
    version=version.__version__,
    author='Luiza Orosanu',
    author_email='luiza.orosanu@xilopix.com',
    description='Xilopix Machine-Learning Python project',
    keywords='transformation and classification',
    package_dir = {'': 'lib'},
    packages=find_packages(where='lib'),
    scripts=[
        'bin/xi-ml-processdemands',
        'bin/xi-ml-trainword2vec',
        'bin/xi-ml-colorclassifier',
        'bin/xi-ml-plotdrawer',
    ],

    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Programming Language :: Python :: 3',
        'Programming Language :: Python :: 3.4',
    ],

    install_requires=get_requirements('requirements_dev.txt'),
    setup_requires=get_requirements('requirements_runtime.txt'),

)
