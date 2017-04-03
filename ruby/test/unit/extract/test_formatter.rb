# encoding: utf-8


require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class FormatterTest < Minitest::Unit::TestCase
  def setup
    @json_data = <<-EOS
      [
      { "start_offset":0, "end_offset":5, "pos_inc":1,
        "type":"word", "token":"Crème" },
      { "start_offset":0, "end_offset":5, "pos_inc":0,
        "type":"stem", "token":"crem#S#" },
      { "start_offset":0, "end_offset":5, "pos_inc":0,
        "type":"lemma", "token":"crème#L#NC" },
      { "start_offset":6, "end_offset":13, "pos_inc":1,
        "type":"word", "token":"dessert" },
      { "start_offset":6, "end_offset":13, "pos_inc":0,
        "type":"stem", "token":"dessert#S#" },
      { "start_offset":6, "end_offset":13, "pos_inc":0,
        "type":"lemma", "token":"desservir#L#V" },
      { "start_offset":14, "end_offset":22, "pos_inc":1,
        "type":"word", "token":"chocolat" },
      { "start_offset":14, "end_offset":22, "pos_inc":0,
        "type":"stem", "token":"chocolat#S#" },
      { "start_offset":14, "end_offset":22, "pos_inc":0,
        "type":"lemma", "token":"chocolat#L#NC" },
      { "start_offset":25, "end_offset":32, "pos_inc":2,
        "type":"word", "token":"vanille" },
      { "start_offset":25, "end_offset":32, "pos_inc":0,
        "type":"stem", "token":"vanill#S#" },
      { "start_offset":37, "end_offset":41, "pos_inc":2,
        "type":"word", "token":"noix" },
      { "start_offset":37, "end_offset":41, "pos_inc":0,
        "type":"stem", "token":"noix#S#" },
      { "start_offset":37, "end_offset":41, "pos_inc":0,
        "type":"lemma", "token":"noix#L#NC" },
      { "start_offset":45, "end_offset":50, "pos_inc":2,
        "type":"word", "token":"cajou" },
      { "start_offset":45, "end_offset":50, "pos_inc":0,
        "type":"stem", "token":"cajou#S#" },
      { "start_offset":45, "end_offset":50, "pos_inc":0,
        "type":"lemma", "token":"cajou#L#NC" },
      { "start_offset":51, "end_offset":59, "pos_inc":1,
        "type":"word", "token":"grillées" },
      { "start_offset":51, "end_offset":59, "pos_inc":0,
        "type":"stem", "token":"grill#S#" },
      { "start_offset":51, "end_offset":59, "pos_inc":0,
        "type":"lemma", "token":"grillé#L#ADJ" },
      { "start_offset":61, "end_offset":67, "pos_inc":2,
        "type":"word", "token":"brésil" },
      { "start_offset":61, "end_offset":67, "pos_inc":0,
        "type":"stem", "token":"brésil#S#" },
      { "start_offset":61, "end_offset":67, "pos_inc":0,
        "type":"lemma", "token":"brésil#L#NC" },
      { "start_offset":73, "end_offset":83, "pos_inc":3,
        "type":"word", "token":"Streetfood" },
      { "start_offset":73, "end_offset":83, "pos_inc":0,
        "type":"stem", "token":"streetfood#S#" },
      { "start_offset":87, "end_offset":94, "pos_inc":2,
        "type":"word", "token":"cuisine" },
      { "start_offset":87, "end_offset":94, "pos_inc":0,
        "type":"stem", "token":"cuisin#S#" },
      { "start_offset":87, "end_offset":94, "pos_inc":0,
        "type":"lemma", "token":"cuisine#L#NC" },
      { "start_offset":98, "end_offset":103, "pos_inc":2,
        "type":"word", "token":"monde" },
      { "start_offset":98, "end_offset":103, "pos_inc":0,
        "type":"stem", "token":"mond#S#" },
      { "start_offset":98, "end_offset":103, "pos_inc":0,
        "type":"lemma", "token":"monde#L#NC" }
      ]
      EOS
  end

  def test_text_correct
    text = 'LAURENT BALLUC-RITTENER, malgré votre indisponibilité pour '\
      'blessure, vous restez proche de vos coéquipiers. Comment se '\
      'portent-ils après la défaite face à Montauban (41-15) ? '\
      "Justement, qu'est-ce qui a manqué à l'équipe dans ce match? "\
      'L.B-R: La combativité. Nous devons très vite retrouver cet état '\
      "d'esprit. Le groupe vit bien, le club est agréable, la ville est "\
      'agréable. Tout est fait pour que nous travaillions dans de bonnes '\
      'conditions. A nous de nous reprendre. Mais il est vrai '\
      "qu'il nous a manqué beaucoup de choses lors de la première journée. "\
      'Nous avons fait 20 à 25 minutes de qualité, mais par la suite, on a '\
      'relancé cette équipe qui a rapidement pris le dessus sur nous. Bref, '\
      "trop d'approximations et un manque flagrant d'efficacité nous ont "\
      'fait défaut. Comment abordez-vous la venue de Biarritz ? '\
      'Sur le plan personnel, comment se présente votre blessure? L.B-R: '\
      "C'est une blessure qui dure mais elle est en cours de guérison. "\
      'Je me suis rendu à Lyon cette semaine et je vais devoir y retourner '\
      'dans les jours qui suivent pour procéder à des infiltrations. '\
      'Je pense que je vais en avoir encore pour une quinzaine de jours avant '\
      'de reprendre. On verra bien. Source photo: Alain PERNIA (Midi Libre)'

    words = 'laurent balluc rittener malgré votre indisponibilité pour '\
      'blessure vous restez proche de vos coéquipiers comment se portent ils '\
      "après la défaite face à montauban justement qu' est ce qui a manqué "\
      "à l' équipe dans ce match l b r la combativité nous devons très vite "\
      "retrouver cet état d' esprit le groupe vit bien le club est agréable "\
      'la ville est agréable tout est fait pour que nous travaillions dans '\
      'de bonnes conditions a nous de nous reprendre mais il est vrai '\
      "qu' il nous a manqué beaucoup de choses lors de la première journée "\
      'nous avons fait à minutes de qualité mais par la suite on a relancé '\
      'cette équipe qui a rapidement pris le dessus sur nous bref trop '\
      "d' approximations et un manque flagrant d' efficacité nous ont fait "\
      'défaut comment abordez vous la venue de biarritz sur le plan personnel '\
      "comment se présente votre blessure l b r c' est une blessure qui dure "\
      'mais elle est en cours de guérison je me suis rendu à lyon cette '\
      'semaine et je vais devoir y retourner dans les jours qui suivent pour '\
      'procéder à des infiltrations je pense que je vais en avoir encore pour '\
      'une quinzaine de jours avant de reprendre on verra bien '\
      'source photo alain pernia midi libre'

    assert_equal words, Xi::ML::Tools::Formatter.words_from_text(text)
  end

  def test_text_incorrect
    text = 'Groupe :AURIER SergeCAVANI EdinsonDAVID LUIZDI MARIA '\
      'AngelIBRAHIMOVIC ZlatanKURZAWA LayvinLAVEZZI '\
      'EzequielLUCASMARQUINHOSMATUIDI BlaiseMAXWELLPASTORE JavierRABIOT '\
      'AdrienSIRIGU SALVATOREStambouli BenjaminTHIAGO MOTTATHIAGO SILVATRAPP '\
      'KevinVERRATTI Marco. Absents :AUGUSTIN Jean-Kévin (choix)DOUCHEZ '\
      'Nicolas (choix)KIMPEMBE Presnel (choix)ONGENDA Hervin (choix)VAN DER '\
      'WIEL Gregory (contusion de la hanche gauche). FC NANTES - PARIS '\
      'SAINT-GERMAINLigue 1 - 8e journéeStade de la Beaujoire-Louis '\
      'FonteneauSamedi 26 septembre 2015 - 17h30Match retransmis en direct '\
      'sur Canal+'

    words = 'groupe aurier serge cavani edinson david luizdi maria angel '\
      'ibrahimovic zlatan kurzawa layvin lavezzi ezequiel '\
      'lucasmarquinhosmatuidi blaise maxwellpastore javier rabiot adrien '\
      'sirigu salvatore stambouli benjamin thiago mottathiago silvatrapp '\
      'kevin verratti marco absents augustin jean kévin choix douchez nicolas '\
      'choix kimpembe presnel choix ongenda hervin choix van der wiel '\
      'gregory contusion de la hanche gauche fc nantes paris saint germain '\
      'ligue e journée stade de la beaujoire louis fonteneau samedi septembre '\
      'h match retransmis en direct sur canal'

    assert_equal words, Xi::ML::Tools::Formatter.words_from_text(text)
  end

  def test_url_with_extension
    url = 'http://www.lesechos.fr/industrie-services/pharmacie-sante/'\
      '0211194158494-malgre-sa-dangerosite-10000-femmes-enceintes-ont-pris'\
      '-de-la-depakine-2019703.php'

    words = 'lesechos industrie services pharmacie sante '\
      'malgre sa dangerosite femmes enceintes ont pris de la depakine'

    assert_equal words, Xi::ML::Tools::Formatter.words_from_url(url)
  end

  def test_url_without_extension
    url = 'http://www.ledauphine.com/sante/2016/02/03/'\
      'de-grands-progres-therapeutiques'

    words = 'ledauphine sante de grands progres therapeutiques'

    assert_equal words, Xi::ML::Tools::Formatter.words_from_url(url)
  end

  def test_url_with_query
    url = 'http://www.ledauphine.com/education/resultats-examens-2016?'\
      'departmentCode=4&city=Saint-Andr%C3%A9-les-Alpes&firstLetter=P&page=1'

    words = 'ledauphine education resultats examens'

    assert_equal words, Xi::ML::Tools::Formatter.words_from_url(url)
  end

  def test_nlp_stems
    stems = 'crem dessert chocolat vanill noix cajou grill brésil '\
      'streetfood cuisin mond'

    assert_equal stems, \
      Xi::ML::Tools::Formatter.words_from_nlp(@json_data, 'stems')
  end

  def test_nlp_lemmas
    lemmas = 'crème desservir chocolat vanille noix cajou grillé brésil '\
      'Streetfood cuisine monde'

    assert_equal lemmas, \
      Xi::ML::Tools::Formatter.words_from_nlp(@json_data, 'lemmas')
  end

  def test_nlp_postags
    pos_tags = 'NC V NC _ NC NC ADJ NC _ NC NC'

    assert_equal pos_tags, \
      Xi::ML::Tools::Formatter.words_from_nlp(@json_data, 'pos')
  end

  def test_nlp_words
    words = 'Crème dessert chocolat vanille noix cajou grillées brésil '\
      'Streetfood cuisine monde'

    assert_equal words, \
      Xi::ML::Tools::Formatter.words_from_nlp(@json_data, 'words')
  end
end
