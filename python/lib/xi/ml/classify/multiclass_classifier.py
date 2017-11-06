# -*-coding:utf-8 -*


import xi.ml.classify

from xi.ml.common import Component
from xi.ml.error import ConfigError, CaughtException


class MulticlassClassifier(Component):
    """
    Class used for training and saving lr/mlp/dt/...
    multi-class classification models
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

        classifiers = xi.ml.classify.TrainClassifier.CLASSIFIERS['multiclass']

        try:
            self.model = classifiers['models'][classif_name](**kwargs)
        except:
            raise CaughtException(
                "Exception when initializing the {} multiclass classifier ({})"
                .format(self.name, kwargs))

        self.logger.info(
            "Initialized a {} classifier ({})".format(classif_name, kwargs))

    def train(self, features, labels, train_type):
        """Train the classifier on the given data"""

        self.trained = False
        self.logger.info("Train using {} documents".format(len(features)))


        try:
            if train_type == "offline":
                self.model.fit(features, labels)
            else:
                self.model.partial_fit(
                    features, labels, classes=self.categories)
        except:
            raise CaughtException(
                "Exception when {} training the {} multiclass classifier"
                .format(train_type, self.name))
        else:
            self.trained = True

    def shape(self):
        """The dictionary shape of the model"""

        shape = {}

        try:
            if self.name == 'LogisticRegression':
                shape = {}
                shape['name'] = 'LogisticRegression'
                shape['classes'] = list(self.model.classes_)
                shape['n_classes'] = len(self.model.classes_)
                shape['n_features'] = len(self.model.coef_[0])
                shape['coeffs'] = \
                    [[float(x) for x in coefs] for coefs in self.model.coef_]
                shape['intercept'] = [float(x) for x in self.model.intercept_]
            elif self.name == 'MLPClassifier':
                shape = {}
                shape['name'] = self.name
                shape['classifier_type'] = 'multiclass'
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
