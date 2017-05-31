# -*-coding:utf-8 -*


import os
from xi.ml.tools import utils


class PathGenerator:
    """Class generating the paths for local files/folders"""

    def __init__(self, res, classes, subsets, preproc, trans, classif):
        """Initialize all the necessary paths for data files and models"""

        self.res = res
        self.classes = tuple(classes)
        self.subsets = tuple(subsets)
        self.preproc = tuple(preproc)
        self.trans = tuple(trans)
        self.classif = tuple(classif)

        self.paths = {
            'data': self._generate_data_files(),
            'models': {
                'trans': self._generate_transmodels_folders(),
                'trans_topics': self._generate_transtopics_files(),
                'classif': self._generate_classifmodels_folders()
            },
            'dictionary': self._generate_dict_files(),
            'stats': self._generate_stats_folders()
        }

    def __str__(self):
        """Display the object's content"""
        return str(self.paths)

    def preprocessed_file(self, category, subset, ptype):
        """
        Return the preprocessed data files
        for given category, subset and preprocessing.
        File should already exist.
        """

        filename = self.paths['data'][category]['preprocessed'][ptype][subset]
        utils.check_file_readable(filename)
        return filename

    def transformed_file(self, category, subset, ttype, ptype):
        """
        Return the transformed data file
        for given category, subset, transformation and preprocessing.
        """

        ctrans = "{}_{}".format(ttype, ptype)
        filename = self.paths['data'][category]['transformed'][ctrans][subset]

        utils.create_path(filename)
        return filename

    def classified_file(
            self, category, subset,
            cname, ctype, traintype, csize, ttype, ptype):

        """
        Return the classified data file
        for given category, subset, classifier, training type, data size,
        transformation and preprocessing.
        """

        if csize == -1:
            csize = 'max'

        ctrans = "{}_{}".format(ttype, ptype)
        classif = "{}_{}_{}_{}".format(cname, ctype, traintype, str(csize))
        folder = self.paths['data'][category]['classified'][ctrans]
        filename = os.path.join(
            folder, classif, "{}_{}.json".format(category, subset))

        utils.create_path(filename)
        return filename

    def stats_file(self, cname, ctype, traintype, csize, ttype, ptype):
        """
        Return the stats file
        for given classifier, training type, data size,
        transformation and preprocessing.
        """

        if csize == -1:
            csize = 'max'

        ctrans = "{}_{}".format(ttype, ptype)
        classif = "{}_{}".format(cname, ctype)
        folder = self.paths['stats'][classif][ctrans]

        classif_file = "{}_{}.json".format(traintype, str(csize))
        filename = os.path.join(folder, classif_file)

        utils.create_path(filename)
        return filename

    def preprocessed_files(self, ptype, subset):
        """
        Return the list of preprocessed 'subset' data files for each category.
        Files should already exist.
        """

        files = []

        for category in self.classes:
            filename = self.preprocessed_file(category, subset, ptype)
            files.append(filename)

        if not files:
            exit("Empty list of preprocessed files")

        return files

    def transformed_files(self, ttype, ptype, subset):
        """
        Return the list of transformed 'subset' data files for each category.
        Files should already exist.
        """

        files = []

        for category in self.classes:
            filename = self.transformed_file(category, subset, ttype, ptype)

            utils.check_file_readable(filename)
            files.append(filename)

        if not files:
            exit("Empty list of transformed files")

        return files

    def classified_files(
            self, cname, ctype, traintype, csize, ttype, ptype, subset):

        """
        Return the list of classified 'subset' data files for each category.
        Files should already exist.
        """

        files = []

        for category in self.classes:
            filename = self.classified_file(
                category, subset, cname, ctype, traintype, csize, ttype, ptype)

            utils.check_file_readable(filename)
            files.append(filename)

        if not files:
            exit("Empty list of classified files")

        return files

    def dictionary(self, ptype):
        """
        Return the dictionary's filename given the preprocessing type.
        File should be created later on.
        """

        utils.create_path(self.paths['dictionary'][ptype])
        return self.paths['dictionary'][ptype]

    def transformation_model(self, model, ttype, ptype):
        """
        Return the model's filename given the transformation and preprocessing.
        File should be created later on.
        """

        ctrans = "{}_{}".format(ttype, ptype)
        folder = self.paths['models']['trans'][ctrans]
        filename = "model_{}.bin".format(model)

        utils.create_folder(folder)
        return os.path.join(folder, filename)

    def transformation_topics(self, ttype, ptype):
        """
        Return the model topics filename
        given the transformation and preprocessing.
        File should be created later on.
        """

        ctrans = "{}_{}".format(ttype, ptype)
        topics_file = self.paths['models']['trans_topics'][ctrans]

        utils.create_path(topics_file)
        return topics_file

    def classification_model(self, ttype, ptype, cname, ctype, train, csize):
        """
        Return the model's filename given the transformation and preprocessing.
        File should be created later on.
        """

        if csize == -1:
            csize = 'max'

        ctrans = "{}_{}".format(ttype, ptype)
        cclassif = "{}_{}".format(cname, ctype)
        folder = self.paths['models']['classif'][cclassif][ctrans]
        filename = "{}_{}.bin".format(train, str(csize))

        utils.create_path(folder)
        return os.path.join(folder, filename)

    def _generate_data_files(self):
        """
        Generate all the data paths for each category, subset, preproc, trans, ...
        """

        files = {}

        # inits
        for category in self.classes:
            files[category] = {}
            files[category]['divided'] = {}
            files[category]['preprocessed'] = {}
            files[category]['transformed'] = {}
            files[category]['classified'] = {}

            # extracted data
            folder = os.path.join(self.res, 'data', category, 'extracted')
            file = "{}.json".format(category)

            utils.create_folder(folder)
            files[category]['extracted'] = os.path.join(folder, file)

            # divided data
            folder = os.path.join(self.res, 'data', category, 'divided')
            utils.create_folder(folder)

            for subset in self.subsets:
                file = "{}_{}.json".format(category, subset)
                files[category]['divided'][subset] = os.path.join(folder, file)

            # preprocessed data
            for preprocess in self.preproc:
                folder = os.path.join(
                    self.res, 'data', category, 'preprocessed', preprocess)
                utils.create_folder(folder)

                files[category]['preprocessed'][preprocess] = {}
                for subset in self.subsets:
                    file = "{}_{}.json".format(category, subset)
                    files[category]['preprocessed'][preprocess][subset] = \
                        os.path.join(folder, file)

            # transformed data
            for transformation in self.trans:
                for preprocess in self.preproc:
                    ctrans = "{}_{}".format(transformation, preprocess)

                    folder = os.path.join(
                        self.res, 'data', category, 'transformed', ctrans)
                    utils.create_folder(folder)

                    files[category]['transformed'][ctrans] = {}
                    for subset in self.subsets:
                        file = "{}_{}.json".format(category, subset)
                        files[category]['transformed'][ctrans][subset] = \
                            os.path.join(folder, file)

            # classified data
            for transformation in self.trans:
                for preprocess in self.preproc:
                    ctrans = "{}_{}".format(transformation, preprocess)

                    folder = os.path.join(
                        self.res, 'data', category, 'p_classified', ctrans)
                    utils.create_folder(folder)
                    files[category]['classified'][ctrans] = folder

        return files

    def _generate_dict_files(self):
        """
        Generate all the dictionaries paths for each preprocessing type
        """

        files = {}

        folder = os.path.join(self.res, 'dictionary')
        utils.create_folder(folder)

        for preprocess in self.preproc:
            file = "dictionary_{}.bin".format(preprocess)
            files[preprocess] = os.path.join(folder, file)

        return files

    def _generate_transmodels_folders(self):
        """
        Generate the transformation models paths for each preproc/trans type
        """

        folders = {}

        for transformation in self.trans:
            for preprocess in self.preproc:
                ctrans = "{}_{}".format(transformation, preprocess)

                folder = os.path.join(
                    self.res, 'models', 'transformations', ctrans)

                utils.create_folder(folder)
                folders[ctrans] = folder

        return folders

    def _generate_transtopics_files(self):
        """
        Generate the transformation topics paths for each preproc/trans type
        """

        files = {}

        # recover topics only for LSI/LDA models
        trans = set(self.trans).intersection(set(['LSI', 'LDA']))

        for transformation in trans:
            for preprocess in self.preproc:
                ctrans = "{}_{}".format(transformation, preprocess)
                file = "topics_top50words_{}.json".format(ctrans)

                folder = os.path.join(
                    self.res, 'models', 'transformations_topics')
                utils.create_folder(folder)

                files[ctrans] = os.path.join(folder, file)

        return files

    def _generate_classifmodels_folders(self):
        """
        Generate all the classification models paths for each preproc/trans type
        """

        folders = {}

        for cname in self.classif:
            for ctype in ['multiclass', 'multilabel']:
                classifier = "{}_{}".format(cname, ctype)

                folder = os.path.join(
                    self.res, 'models', 'classification', classifier)

                folders[classifier] = {}
                for transformation in self.trans:
                    for preprocess in self.preproc:
                        ctrans = "{}_{}".format(transformation, preprocess)
                        folders[classifier][ctrans] = os.path.join(
                            folder, ctrans)
                        utils.create_folder(folders[classifier][ctrans])

        return folders

    def _generate_stats_folders(self):
        """
        Generate the statistic files paths for each preproc/trans/classif type
        """

        folders = {}

        for cname in self.classif:
            for ctype in ['multiclass', 'multilabel']:
                classifier = "{}_{}".format(cname, ctype)

                folder = os.path.join(
                    self.res, 'stats', 'classification', classifier)

                folders[classifier] = {}
                for transformation in self.trans:
                    for preprocess in self.preproc:
                        ctrans = "{}_{}".format(transformation, preprocess)
                        folders[classifier][ctrans] = os.path.join(
                            folder, ctrans)
                        utils.create_folder(folders[classifier][ctrans])

        return folders
