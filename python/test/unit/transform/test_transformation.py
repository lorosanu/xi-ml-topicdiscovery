# -*-coding:utf-8 -*


import os
import unittest

from xi.ml.tools import utils
from xi.ml.corpus import dictionary
from xi.ml.transform import LoadTransformer


class TransformationTest(unittest.TestCase):
    """Test case for the transformer lib"""

    def setUp(self):
        """Initialize test models"""

        cfolder = os.path.dirname(__file__)

        dict_file = os.path.join(cfolder, 'example_dictionary.bin')
        tfidf_file = os.path.join(cfolder, 'example_model_tfidf.bin')
        lsi_file = os.path.join(cfolder, 'example_model_lsi.bin')

        utils.check_file_readable(dict_file)
        utils.check_file_readable(tfidf_file)
        utils.check_file_readable(lsi_file)

        self.dictionary = dictionary.load(dict_file)
        self.tfidf_model = LoadTransformer('TFIDF', tfidf_file).model
        self.transformer = LoadTransformer('LSI', lsi_file)

        self.doc = 'le paris saint germain a tenté de faire venir fernando  '\
            "torres au tout début de l' été selon des informations révélées "\
            "par marca ce dimanche alors en fin de contrat avec l' atlético "\
            "de madrid l' attaquant espagnol a dîné en compagnie de ses "\
            "agents et d' olivier létang le directeur sportif adjoint "\
            "parisien dans un restaurant madrilène à quelques jours de la "\
            "finale de la ligue des champions perdue face au real madrid t "\
            "a b à laurent blanc alors l' entraîneur du psg avait validé "\
            "son profil et comptait bien lui accorder un temps de jeu "\
            "conséquent sauf qu' entre temps torres a prolongé son contrat "\
            'avec son club de cœur et que blanc a été viré '\
            "de son poste d' entraîneur"

    def test_lsi_features(self):
        """Test the LSI transformation"""

        real_features = [-0.392947441976, -0.0860057804864, 0.177659584063,
            0.134263879729, -0.046663802191, -0.022944186181, -0.0352064516564,
            0.0452438403012, 0.141021514104, 0.0436126534136, 0.135414260816,
            -0.0113758572241, -0.0724095713519, 0.166140582018,
            -0.146570821102, -0.0776151580912, 0.0625623118397,
            0.0105655432961, 0.0764128503051, 0.0567918514646, 0.0410128227992,
            -0.133493574245, 0.150485007776, 0.119226513447, -0.119602951301,
            0.0810962403179, -0.0552491665872, -0.0209310325433,
            0.125719294401, -0.0736743670507, 0.0308100885624, -0.12812811179,
            0.100356114581, 0.0110890322877, -0.111931982475, 0.0878582460384,
            0.0202320523004, -0.0214310274014, -0.170446518721,
            0.0265353565164, -0.00899727945292, 0.0180612761582,
            0.120444792653, -0.0672264936296, -0.0391411437935,
            -0.089996394803, -0.128636579285, -0.136217712289, -0.104541100326,
            0.129125196925, -0.0159992767854, 0.0373687576229,
            -0.0610263136022, -0.0776967375218, 0.0491917033087,
            0.171953316294, 0.02594892892, -0.0605009937376, 0.238026124778,
            -0.0552141523594, 0.0512174857648, -0.0884323506509,
            -0.112357769922, 0.0366834644992, -0.0753960297245,
            -0.0685856739786, -0.00144226328505, 0.0416023149016,
            -0.0726489092799, 0.0553956224146, -0.111075505511, 0.156784345481,
            -0.213237157326, 0.0479286369213, 0.0164050481735,
            -0.0141642938351, 0.0373982551388, -0.0587022666871,
            0.00761550897572, 0.0921402934428, -0.0521749855225,
            -0.0786775700586, 0.0281356650698, 0.0118747076537,
            0.100321754976, -0.0678724902905, -0.000512972038484,
            -0.0555146524962, -0.083917597783, 0.0234147813899,
            -0.0837503312819, 0.119831384727, 0.242022264274, -0.09238370976,
            -0.0150643470387, 0.00778878948819, -0.127646680589,
            0.0320047049563, 0.0325686660778, -0.0594764702745]

        features = self.transformer.transform_doc(
            self.dictionary, self.tfidf_model, self.doc)

        features = [round(float(x), 7) for x in features]
        real_features = [round(float(x), 7) for x in real_features]

        self.assertListEqual(real_features, features)
