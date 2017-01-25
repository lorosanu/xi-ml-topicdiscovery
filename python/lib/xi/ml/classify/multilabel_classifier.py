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
                shape['n_classes'] = len(self.model.classes_)
                shape['n_features'] = len(self.model.coefs_[0])
                shape['classes'] = list(self.categories)
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
