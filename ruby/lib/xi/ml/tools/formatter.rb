# encoding: utf-8



# The class meant to extract possible usefull words from different sources
class Xi::ML::Tools::Formatter

  # Static method to recover clean words from a text
  #
  # @param text [String] a given text
  # @param clean_upcase [Boolean] apply an upcase cleaner (slow & !100%reliable)
  # @return [String] the joined list of words from the clean, lowercase text
  def self.words_from_text(text, clean_upcase=false)
    return '' if text.nil? || text.empty?

    # remove all non latin characters (including digits)
    ctext = text.gsub(/[^\p{Latin}']/, ' ')

    if clean_upcase
      # clean badly formatted words (mix upcase & downcase in one word)
      # ex: JOURNEEJeudi, JavierRABIOT, journéeStade
      nwords = []

      ctext.split.each do |word|
        if word != Unicode.upcase(word)
          if word =~ /[\p{Lu}]{2}/
            word = word.gsub(/(?<=\p{Lu})(\p{Lu}+)(?=\p{Lu}|$)/)\
              {|match| Unicode.downcase(match) }
          end

          # check for camel case words (ex: JourneeJeudi)
          word = word.split(/(?=\p{Lu})/).join(' ') if word =~ /[\p{Lu}]/
        end

        nwords << word
      end

      ctext = nwords.join(' ')
    end

    # add a space after any '
    ctext.gsub!("'", "' ")

    # remove extra spaces and lowercase text
    Unicode.downcase(ctext.split.join(' '))
  end

  # Static method to recover words from an url
  #
  # @param url [String] a given url
  # @return [String] the joined list of words from the url's host and path
  def self.words_from_url(url)
    return '' if url.nil? || url.empty?

    words = ''

    begin
      uri = URI(url)
    rescue
      return ''
    end

    return '' if uri.host.nil? || uri.host.empty?

    # do not keep the top level domain name or the www.
    words << uri.host.split('.')[0..-2].tap{|a| a.delete('www') }.join(' ')

    # use only the path part of the url (ignore query, fragment and extension)
    dir = File.dirname(uri.path)
    base = File.basename(uri.path, File.extname(uri.path))
    words << File.join(dir, base).split('/').join(' ')

    # split by anything that's not a letter or a digit
    words = words.split(/[^\p{Latin}0-9]/)\
      .delete_if{|v| v.nil? || v.empty? || v =~ /^\d+$/ || v == 'index' }

    words.join(' ')
  end

  # Static method to recover words/stems from the content_analyzed field
  #
  # @param json_data [String] the 'content_analyzed' ES entry in JSON format
  # @param rtype [String] which data type to return (stems/lemmas/pos/words)
  # @return [String] the joined list of stems (when available)
  def self.words_from_nlp(json_data, rtype='stems')
    rtypes = %w(stems lemmas pos words).freeze

    raise Xi::ML::Error::ConfigError, \
      "Unknown return type '#{rtype}'. Choose frome '#{rtypes}'" \
      unless rtypes.include?(rtype)

    data = JSON.load(json_data)

    nlp = []
    token = { word: nil, stem: nil, lemma: nil, postag: nil }

    data.each do |item|
      # warn and skip the current token if not valid
      unless valid?(item)
        token = { word: nil, stem: nil, lemma: nil, postag: nil }
        next
      end

      # if pos_inc is greater than zero then a new token is being parsed
      if item['pos_inc'] > 0
        # if there is a previous token with a non-empty word then enqueue it
        nlp << token.values unless token[:word].nil?

        # instanciate a new current token
        token = { word: nil, stem: nil, lemma: nil, postag: nil }
      end

      # Set the current token field (word/stem/lemma/postag) on extracted value
      # - word =>  token: 'value'
      # - stem =>  token: 'stem#S#'
      # - lemma => token: 'lemma#L#postag'

      type = item['type']
      value = item['token']

      if type == 'lemma'
        token[:lemma] = value.split('#').first
        token[:postag] = value.split('#').last
      elsif type == 'stem'
        token[:stem] = value.split('#').first
      else
        token[:word] = value
      end
    end

    # add last entry when valid
    nlp << token.values unless token[:word].nil? && nlp[-1] == token.values

    # return requested info
    case rtype
    when 'stems'
      # return the list of stems (stem replaced by word when not available)
      return nlp.map{|x| (x[1] ? x[1] : x[0]) }.join(' ')
    when 'lemmas'
      # return the list of lemmas (lemma replaced by word when not available)
      return nlp.map{|x| (x[2] ? x[2] : x[0]) }.join(' ')
    when 'pos'
      # return the list of pos-tags
      return nlp.map{|x| (x[3] ? x[3] : '_') }.join(' ')
    when 'words'
      # return the list of words
      return nlp.map{|x| x[0] }.join(' ')
    end

    ''
  end

  # Check if an object recovered from the content_analyzed field is valid
  def self.valid?(item)
    unless item['pos_inc'] && item['type'] && item['token']
      @logger.warn("Content analyzed item should include \
        'pos_inc', 'type' and 'token' fields")
      return false
    end

    unless item['pos_inc'].is_a?(Integer)
      @logger.warn("Token pos_inc is expected to be Integer, \
        get #{item['pos_inc'].class.name.inspect}, token skipped")
      return false
    end

    unless item['token'].is_a?(String)
      @logger.warn("Token value is expected to be String, \
        get #{value.class.name.inspect}, token skipped")
      return false
    end

    expected_types = %w[word stem lemma]
    unless expected_types.include?(item['type'])
      @logger.warn("Token type is expected to be one of #{expected_types}, \
        get #{type.inspect}, token skipped")
      return false
    end

    true
  end

  private_class_method :valid?
end
