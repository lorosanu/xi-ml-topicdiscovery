# -*-coding:utf-8 -*


import itertools
import pylab

import sklearn.metrics

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.corpus import StreamCorpus

def percentage(x):
    """Convert decimal to percentage. Return a string"""
    return "{:.2f}".format(x * 100)

class EvalMetrics(Component):
    """
    Class using the sklearn metrics lib to evaluate a classifier's performance
    """

    def __init__(self, data_files, categories):
        """Load classified data files and list of categories"""

        super().__init__()

        for filename in data_files:
            utils.check_file_readable(filename)

        self.logger.info("Evaluate predictions on {} files".format(data_files))

        self.data_files = list(data_files)
        self.categories = list(categories)

    def confusion_matrix(self):
        """
        Compute the global confusion-matrix on given predicted documents
        using the sklearn metrics.
        """

        self.logger.info('Compute global confusion matrix')

        true_labels = []
        pred_labels = []

        for input_file in self.data_files:
            sc = StreamCorpus(input_file)

            for doc in sc:
                if 'category' in doc and 'season' in doc:

                    # convert real categories to list
                    real_categories = doc['category']
                    if isinstance(real_categories, str):
                        real_categories = [real_categories]

                    # convert predicted categories to list
                    pred_categories = doc['season']
                    if isinstance(pred_categories, str):
                        pred_categories = [pred_categories]

                    # save correct predictions
                    for real_cat in real_categories:
                        if real_cat in pred_categories:
                            true_labels.append(real_cat)
                            pred_labels.append(real_cat)

                            # delete the correct label
                            # from real labels and predicted labels
                            real_categories.remove(real_cat)
                            pred_categories.remove(real_cat)

                    # save wrong predictions
                    # combine all possible real-predicted categories
                    if real_categories and pred_categories:
                        params = {
                            'real': real_categories,
                            'predicted': pred_categories
                        }

                        for combination in itertools.product(*params.values()):
                            dict_comb = dict(zip(params.keys(), combination))

                            real_cat = dict_comb['real']
                            pred_cat = dict_comb['predicted']

                            true_labels.append(real_cat)
                            pred_labels.append(pred_cat)

        cm = sklearn.metrics.confusion_matrix(
            true_labels, pred_labels, labels=self.categories)

        self.logger.info(
            "Confusion-matrix on {} classes:\n{}".format(self.categories, cm))

        return cm

    def store_stats(self, roc_file, plot_file):
        """
        Compute the sklearn metrics on given predicted documents,
        with respect to each categoty tag.
        Plot the ROC curve (FP/TP) on each category tag.
        """

        # length of longest category name
        nmax = max(len(cat) for cat in self.categories)

        # stats header inside generated plots
        header = "{} {:>6} {:>6} {:>6} {:>6}".format(
            ' ' * nmax, 'P', 'R', 'Acc', 'AUC')

        utils.create_path(roc_file)
        utils.create_path(plot_file)

        roc = {}
        _, fig = pylab.subplots()

        for index, category in enumerate(self.categories):
            true_labels = []
            pred_labels = []
            pred_probas = []

            for input_file in self.data_files:
                sc = StreamCorpus(input_file)

                for doc in sc:
                    if 'category' in doc and 'season' in doc \
                        and 'season_prob' in doc:

                        # convert real categories to list
                        real_categories = doc['category']
                        if isinstance(real_categories, str):
                            real_categories = [real_categories]

                        # convert predicted categories to list
                        pred_categories = doc['season']
                        if isinstance(pred_categories, str):
                            pred_categories = [pred_categories]

                        # check if 'category'
                        # present in the list of real categories
                        real_cat = 1 if category in real_categories else 0

                        # check if 'category'
                        # present in the list of predicted categories
                        pred_cat = 1 if category in pred_categories else 0

                        pred_proba = doc['season_prob'][category]

                        true_labels.append(real_cat)
                        pred_labels.append(pred_cat)
                        pred_probas.append(pred_proba)

            prec = sklearn.metrics.precision_score(true_labels, pred_labels)
            recall = sklearn.metrics.recall_score(true_labels, pred_labels)
            acc = sklearn.metrics.accuracy_score(true_labels, pred_labels)

            cm = sklearn.metrics.confusion_matrix(true_labels, pred_labels)
            rep = sklearn.metrics.classification_report(
                true_labels, pred_labels)
            auc = sklearn.metrics.roc_auc_score(true_labels, pred_probas)

            prec = percentage(prec)
            recall = percentage(recall)
            acc = percentage(acc)
            auc = percentage(auc)

            self.logger.info("Category:  {}".format(category))
            self.logger.info("Precision: {}%".format(prec))
            self.logger.info("Recall:    {}%".format(recall))
            self.logger.info("Accuracy:  {}%".format(acc))
            self.logger.info("AUC:       {}%".format(auc))
            self.logger.info("Confusion-matrix:\n{}".format(cm))
            self.logger.info("Report:\n{}".format(rep))

            fpr, tpr, thr = sklearn.metrics.roc_curve(
                true_labels, pred_probas, 1)

            # convert numpy array into array
            fpr = [float(x) for x in fpr]
            tpr = [float(x) for x in tpr]

            # store roc values
            roc[category] = [
                [threshold, fpr[tindex], tpr[tindex]]
                for tindex, threshold in enumerate(thr)]

            # plot current ROC curve
            fig.plot(fpr, tpr, label=category)

            # annotate current precision, recall, accuracy and AUC scores
            cdisplay = category.rjust(nmax)
            fig.annotate(header, (0.4, 0.67), size=9, family='monospace')
            fig.annotate(
                "{}  {}  {}  {}  {}".format(cdisplay, prec, recall, acc, auc),
                (0.4, 0.6 - 0.07 * index), size=9, family='monospace')

        fig.legend(labels=self.categories)

        pylab.title('Classifier performance (ROC curve)')
        pylab.xlabel('False positive rate')
        pylab.ylabel('True positive rate')

        pylab.savefig(plot_file)
        pylab.close()
        self.logger.info("Plot saved under {} file".format(plot_file))

        # save ROC values to file
        with open(roc_file, 'w') as of:
            for category in roc:
                of.write(category + '\n')
                for entry in roc[category]:
                    of.write(' '.join(str(x) for x in entry) + '\n')

        self.logger.info("ROC values saved under {} file".format(roc_file))
