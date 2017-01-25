# -*-coding:utf-8 -*


import json

from xi.ml.common import Component
from xi.ml.tools import utils
from xi.ml.corpus import StreamCorpus


class PredictionStatistics(Component):
    """Class displaying and storing the statistics of given prediction"""

    def __init__(self, data_files, categories):
        """Load classified data files and list of categories"""

        super().__init__()

        for filename in data_files:
            utils.check_file_readable(filename)

        self.stats = {}
        self.data_files = list(data_files)
        self.categories = list(categories)

    def compute_stats(self):
        """Compute the accuracy, precision and recall statistics"""

        self.stats = {}

        gc, gt = 0, 0
        n_correct, n_total = {}, {}

        # init stats dictionary
        # - number of total documents in class 'category'
        # - number of correctly classified documents in class 'category'
        for category in self.categories:
            n_total[category] = 0
            n_correct[category] = 0

        # count correct predictions in given data files
        valid_format = False

        for input_file in self.data_files:
            sc = StreamCorpus(input_file)

            for doc in sc:
                if 'category' in doc and 'season' in doc:
                    valid_format = True

                    real_categories = doc['category']
                    predicted_categories = doc['season']

                    # convert real_category to list
                    if isinstance(real_categories, str):
                        real_categories = [real_categories]

                    # convert predicted_category to list
                    if isinstance(predicted_categories, str):
                        predicted_categories = [predicted_categories]

                    for real_category in real_categories:
                        n_total[real_category] += 1
                        if real_category in predicted_categories:
                            n_correct[real_category] += 1


        if not valid_format:
            self.logger.warning(
                "Input data has no fields 'category' or 'season'")
            return

        # print stats by class
        for category in self.categories:
            total = n_total[category]
            correct = n_correct[category]
            avg_accuracy = self.div(correct, total)

            self.logger.info(
                "Correctly classified documents of class='{}': "
                "{} / {} = {:.2%}"
                .format(category, correct, total, avg_accuracy))

            # global counts
            gc += correct
            gt += total

        # global accuracy
        global_accuracy = self.div(gc, gt)

        # print global stats
        self.logger.info(
            "Correctly classified documents: {} / {} = {:.2%}"
            .format(gc, gt, global_accuracy))

        # recall & precision stats for each class
        # true-positive, false-negative, false-positive, true-negative ratios
        recall, precision = {}, {}
        tp, fn, fp, tn = {}, {}, {}, {}

        for i, category in enumerate(self.categories):
            tp[category] = n_correct[category]
            fn[category] = n_total[category] - n_correct[category]

            tn[category] = 0
            fp[category] = 0
            for j, category_j in enumerate(self.categories):
                if j != i:
                    tn[category] += n_correct[category_j]
                    fp[category] += (
                        n_total[category_j] -
                        n_correct[category_j])

            precision[category] = self.div(
                tp[category], tp[category] + fp[category])

            recall[category] = self.div(
                tp[category], tp[category] + fn[category])

        # print the confusion matrix for each class
        for category in self.categories:
            table = "=" * 40 + "\n"
            table += "Class={}\n".format(category)
            table += "=" * 40 + "\n"
            table += "      | declare H1 |  declare H0 |\n"

            table += "is H1 | {:>10} | {:>11} |\n"\
                .format(tp[category], fn[category])

            table += "is H0 | {:>10} | {:>11} |\n".format(
                fp[category], tn[category])

            table += "-" * 40 + "\n"

            table += "Precision = {:.2%}\n".format(
                precision[category])

            table += "Recall    = {:.2%}\n".format(
                recall[category])

            self.logger.info(
                "Confusion matix, precision and recall stats "
                "for the '{}' class:\n{}".format(category, table))

        # store stats
        self.stats['global-accuracy'] = "{:.2%}".format(global_accuracy)
        for category in self.categories:
            self.stats[category] = {}
            self.stats[category]['precision'] = "{:.2%}".format(
                precision[category])
            self.stats[category]['recall'] = "{:.2%}".format(
                recall[category])

    def store_stats(self, output):
        """Store statistics on predictions"""

        self.logger.info(
            "Save statistics on predictions to '{}'"
            .format(output))

        with open(output, 'w') as ostream:
            ostream.write(json.dumps(self.stats, indent=2))

    def div(self, x, y):
        """Own div method to account for zero division error"""

        if y != 0:
            return x / y
        else:
            self.logger.warning('Zero division error')
            return 0
