# -*-coding:utf-8 -*


import xi.ml.classify

from xi.ml.common import Component
from xi.ml.error import ConfigError, CaughtException


class MultilabelClassifier(Component):
    """
    Class used for training and saving dt/rf/nn/mlp/...
    multi-label classification models
    """

    def __init__(self, classif_name, categories, **kwargs):
        """
        Initialize the classifier
        with its name and its list of known categories
        """

        super().__init__()

        self.name = classif_name
        self.trained = False
        self.categories = list(categories)

        classifiers = xi.ml.classify.TrainClassifier.CLASSIFIERS['multilabel']

        try:
            self.model = classifiers['models'][classif_name](**kwargs)
        except:
            raise CaughtException(
                "Exception when initializing the {} multilabel classifier ({})"
                .format(self.name, kwargs))

        self.logger.info("Initialized a {} classifier".format(classif_name))

    def train(self, features, labels, train_type='offline'):
        """Train the current classifier"""

        self.trained = False

        if train_type != 'offline':
            self.logger.error('Can only train offline a multilabel classifier')
            return

        self.logger.info("Train using {} documents".format(len(features)))

        # change labels format for multilabel training
        labels = self._binarize_labels(labels)

        try:
            self.model.fit(features, labels)
        except:
            raise CaughtException(
                "Exception when {} training the {} multilabel classifier"
                .format(train_type, self.name))
        else:
            self.trained = True

        # reset category binary labels to real category names
        self.model.classes_ = self.categories

    def _binarize_labels(self, labels):
        """Convert labels into binary format"""

        if not isinstance(labels, list):
            return []

        # transform each label into an array of labels,
        # if it's not already the case
        if len(labels) > 0 and not isinstance(labels[0], list):
            labels = [[label] for label in labels]

        # transform labels into a fixed-length array of binary indicators
        # ex: ['sport'] => [0, 1, 0] (for classes=[society, sport, unk])
        bin_labels = []

        for ref_labels in labels:
            new_labels = [1 if x in ref_labels else 0 for x in self.categories]
            bin_labels.append(new_labels)

        return bin_labels

    def shape(self):
        """The dictionary shape of the model"""

        shape = {}

        try:
            if self.name == 'MLPClassifier':
                shape = {}
                shape['name'] = self.name
                shape['classifier_type'] = 'multilabel'
                shape['classes'] = list(self.model.classes_)
                shape['n_classes'] = len(self.model.classes_)
                shape['n_features'] = len(self.model.coefs_[0])
                shape['hidden_activation'] = self.model.activation
                shape['output_activation'] = self.model.out_activation_

                # coefficients & intercepts of hidden layers
                hl_coeffs = self.model.coefs_[:-1]
                hl_intercepts = self.model.intercepts_[:-1]

                if len(hl_coeffs) != len(hl_intercepts):
                    raise ConfigError(
                        "Hidden coefficients&intercepts not equally sized {}/{}"
                        .format(len(hl_coeffs), len(hl_intercepts)))

                hcoeffs = []
                for layer in hl_coeffs:
                    hcoeffs.append([[float(x) for x in cx] for cx in layer])
                shape['hidden_coeffs'] = hcoeffs

                shape['hidden_intercepts'] = \
                    [[float(x) for x in ix] for ix in hl_intercepts]

                # coefficients & intercepts of output layer
                ocoeffs = self.model.coefs_[-1]
                ocoeffs = [[float(x) for x in ox] for ox in ocoeffs]
                ointercepts = self.model.intercepts_[-1]

                if len(ocoeffs[0]) != len(ointercepts):
                    raise ConfigError(
                        "Output coefficients&intercepts not equally sized {}/{}"
                        .format(len(ocoeffs[0]), len(ointercepts)))

                shape['output_coeffs'] = ocoeffs
                shape['output_intercepts'] = list(ointercepts)
            else:
                self.logger.warning(
                    "Unknown shape for {} classifier (WIP)".format(self.name))
        except:
            raise CaughtException(
                "Exception encountered when recovering "
                "the {} classifier model's shape"
                .format(self.name))

        return shape
