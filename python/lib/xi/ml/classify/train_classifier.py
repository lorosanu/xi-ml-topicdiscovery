# -*-coding:utf-8 -*


import os
import json
import pickle

import sklearn.tree
import sklearn.neighbors
import sklearn.linear_model
import sklearn.naive_bayes
import sklearn.svm
import sklearn.neural_network

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.error import ConfigError
from xi.ml.corpus import MergeCorpora

import xi.ml.classify

class TrainClassifier(Component):
    """
    Class used for training and saving multiclass / multilabel
    classification models
    """

    CLASSIFIERS = {
        'multiclass': {
            'models': {
                'DecisionTreeClassifier': sklearn.tree.DecisionTreeClassifier,
                'LogisticRegression': sklearn.linear_model.LogisticRegression,
                'SGDClassifier': sklearn.linear_model.SGDClassifier,
                'Perceptron': sklearn.linear_model.Perceptron,
                'GaussianNB': sklearn.naive_bayes.GaussianNB,
                'MultinomialNB': sklearn.naive_bayes.MultinomialNB,
                'BernoulliNB': sklearn.naive_bayes.BernoulliNB,
                'SVC': sklearn.svm.SVC,
                'NuSVC': sklearn.svm.NuSVC,
                'LinearSVC': sklearn.svm.LinearSVC,
                'MLPClassifier': sklearn.neural_network.MLPClassifier
            },
            'training': ['offline', 'online']
        },
        'multilabel': {
            'models': {
                'DecisionTreeClassifier': sklearn.tree.DecisionTreeClassifier,
                'NearestNeighbors': sklearn.neighbors.NearestNeighbors,
                'MLPClassifier': sklearn.neural_network.MLPClassifier
            },
            'training': ['offline']
        }
    }

    def __init__(self, classif_name, classif_type, categories, **kwargs):
        """
        Initialize the classifier
        with its name, its type and its list of known categories
        """

        super().__init__()

        if classif_type not in self.CLASSIFIERS:
            raise ConfigError(
                "Unknown classification type '{}'. Choose from {}"
                .format(classif_type, self.CLASSIFIERS.keys()))

        if classif_name not in self.CLASSIFIERS[classif_type]['models']:
            raise ConfigError(
                "Can not train a '{}-{}' model. Choose from {}"
                .format(
                    classif_name,
                    classif_type,
                    self.CLASSIFIERS[classif_type]['models']))

        self.name = classif_name
        self.type = classif_type
        self.categories = list(categories)

        if classif_type == 'multiclass':
            self.classifier = xi.ml.classify.MulticlassClassifier(
                classif_name, categories, **kwargs)
        else:
            self.classifier = xi.ml.classify.MultilabelClassifier(
                classif_name, categories, **kwargs)

        self.logger.info("Initialized a '{}-{}' classifier".format(
            classif_name, classif_type))

    def train(self, train_type, input_files, chunk_size=-1):
        """Train the current classifier"""

        # check if training is possible
        if not self._checkups(train_type, input_files):
            return

        # init data corpus
        self.logger.info('Load data for training')
        corpora = MergeCorpora(input_files)

        # get number of available & wanted documents
        class_size = self._get_numbers(
            len(input_files), corpora.ndocs, chunk_size)

        if class_size == 0:
            return

        # update the total number of documents
        chunk_size = class_size * len(input_files)

        # train the model
        self.logger.info(
            "{} training the {}-{} classifier on {} documents"
            .format(train_type, self.name, self.type, chunk_size))

        finished = False
        total_ndocs = 0

        self.timer.start_timer()
        while not finished:
            features, labels = corpora.load_data(class_size)

            if features:
                self._train_on_chunk(train_type, features, labels)
                total_ndocs += len(features)

            if train_type == 'offline' or not features:
                finished = True

        self.timer.stop_timer(
            "Trained {} the {}-{} model on {} total documents"
            .format(train_type, self.name, self.type, total_ndocs))

    def _train_on_chunk(self, train_type, features, labels):
        """Train the classifier on the given data"""

        self.classifier.train(features, labels, train_type)

    def _get_numbers(self, nfiles, ndocs, csize=-1):
        """Get the number of available & wanted documents"""

        # number of documents to use for each class
        class_size = 0

        if csize == -1 or csize == 'max':
            # in case we want to use all possible data
            # use equal sized corpora => keep the minimum number of documents
            class_size = min(ndocs)
        else:
            # equal number of documents extracted from each file
            class_size = csize // nfiles

            # check valid number of documents in input files
            n_invalid = len(
                [ndoc for ndoc in ndocs if ndoc < class_size])

            if n_invalid > 0:
                self.logger.warning(
                    "Not enough documents in input files {}. "
                    "Requested {} documents per file"
                    .format(ndocs, class_size))
                return 0

        return class_size

    def save(self, output):
        """Save model to binary file"""

        if not self.classifier.trained:
            return

        utils.create_path(output)

        with open(output, 'wb') as ocstream:
            serializer = pickle.Pickler(ocstream)
            serializer.dump(self.classifier.model)

        self.logger.info(
            "Saved the {}-{}'s model under the '{}' file"
            .format(self.name, self.type, output))

    def save_shape(self, output):
        """Save model shape to json file"""

        if not self.classifier.trained:
            return

        model_shape = self.classifier.shape()

        if model_shape:
            utils.create_path(output)

            with open(output, 'w') as osstream:
                osstream.write(json.dumps(model_shape, indent=2))

            self.logger.info(
                "Saved the {}'s model shape under the '{}' file"
                .format(self.name, output))

    def _checkups(self, train_type, files):
        """Checkups on training configuration and on input files"""

        # train checkups
        if train_type not in self.CLASSIFIERS[self.type]['training']:
            self.logger.error(
                "Unknown training type '{}'. Choose from {}"
                .format(train_type, self.CLASSIFIERS[self.type]['training']))
            return False

        if train_type == 'offline':
            if not (
                    hasattr(self.classifier.model, 'fit') and
                    callable(self.classifier.model.fit)):

                self.logger.warning(
                    "{} can not be trained offline".format(self.name))
                return False
        elif train_type == 'online':
            if not (
                    hasattr(self.classifier.model, 'partial_fit') and
                    callable(self.classifier.model.partial_fit)):

                self.logger.warning(
                    "{} can not be trained online".format(self.name))
                return False

        # input_checkups
        check = True

        if isinstance(files, list):
            for filename in files:
                if not os.path.exists(filename):
                    check = False
                    self.logger.error("File {} not found".format(filename))
        else:
            check = False
            self.logger.error(
                'Parameter for training classifier is not a List')

        return check
