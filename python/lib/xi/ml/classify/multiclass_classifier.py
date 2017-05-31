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
                shape['n_classes'] = len(self.model.classes_)
                shape['n_features'] = len(self.model.coef_[0])
                shape['classes'] = list(self.model.classes_)
                shape['coefs'] = list(self.model.coef_)
                shape['intercept'] = list(self.model.intercept_)
                shape['intercept'] = [float(x) for x in shape['intercept']]
                shape['coefs'] = \
                    [[float(x) for x in coeffs] for coeffs in shape['coefs']]
            elif self.name == 'MLPClassifier':
                shape = {}
                shape['name'] = self.name
                shape['classifier_type'] = 'multiclass'
                shape['n_classes'] = len(self.model.classes_)
                shape['n_features'] = len(self.model.coefs_[0])
                shape['classes'] = list(self.model.classes_)
                shape['hidden_activation'] = self.model.activation
                shape['output_activation'] = self.model.out_activation_

                # coefficients & intercepts of hidden layers
                hl_coeffs = self.model.coefs_[:-1]
                hl_intercepts = self.model.intercepts_[:-1]

                if len(hl_coeffs) != len(hl_intercepts):
                    raise ConfigError(
                        "Coefficients & intercepts not equally sized {}/{}"
                        .format(len(hl_coeffs), len(hl_intercepts)))

                transposed_hidden_layers = []
                for coeffs, intercepts in zip(hl_coeffs, hl_intercepts):
                    # transpose coeffs (ex: 300 x 100 => 100 x 300)
                    transposed = coeffs.T
                    transposed = [
                        [float(x) for x in coeffs]
                        for coeffs in transposed
                    ]

                    # add intercepts (ex: => new shape 100 x 301)
                    if len(transposed) != len(intercepts):
                        raise ConfigError(
                            "Coefficients & intercepts not equally sized {}/{}"
                            .format(len(transposed), len(intercepts)))

                    for trans_row, intercept in zip(transposed, intercepts):
                        trans_row.append(intercept)

                    # store all hidden coefficients and intercepts in one list
                    transposed_hidden_layers.append(transposed)

                shape['hidden_layers'] = list(transposed_hidden_layers)

                # coefficients & intercepts of output layer
                output_coefs = self.model.coefs_[-1]
                output_intercepts = self.model.intercepts_[-1]

                transposed_output_coefs = output_coefs.T
                transposed_output_coefs = [
                    [float(x) for x in coeffs]
                    for coeffs in transposed_output_coefs
                ]

                if len(transposed_output_coefs) != len(output_intercepts):
                    raise ConfigError(
                        "Coefficients & intercepts not equally sized {}/{}"
                        .format(
                            len(transposed_output_coefs),
                            len(output_intercepts)))

                for trans_row, intercept in zip(
                        transposed_output_coefs,
                        output_intercepts):
                    trans_row.append(intercept)

                shape['output_layer'] = list(transposed_output_coefs)
            else:
                self.logger.warning(
                    "Unknown shape for {} classifier (WIP)".format(self.name))
        except:
            raise CaughtException(
                "Exception encountered when recovering "
                "the {} classifier model's shape"
                .format(self.name))

        return shape
