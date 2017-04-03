# encoding: utf-8



# Creates the ES query based on a list of url hosts
class Xi::ML::Extract::Query < Xi::ML::Tools::Component
  attr_reader :input, :lang, :hosts, :rules

  FILTERS = %w[host url-qs url-prefix url-regexp].freeze
  FORMATS = %w[query_string query_filtered].freeze

  # Initialize the query: create the rules
  #   based on the list of hosts extracted from the input file
  #
  # @param input [String] the name of the input file
  # @param lang [String] the document's language
  # @param filter [String] the type of filter to apply on urls list
  # @return [String] the generated query rules
  def initialize(input, lang, filter)
    super()

    raise Xi::ML::Error::ConfigError, \
      "Unknown argument '#{filter}'. Choose from #{FILTERS}" \
      unless FILTERS.include?(filter)

    @input = input
    @lang = lang

    read_hosts()
    prepare_rules(filter)
  end

  # Read the list of hosts from the input file
  def read_hosts
    Xi::ML::Tools::Utils.check_file_readable!(@input)
    begin
      @hosts = YAML.load(File.read(@input))

      raise Xi::ML::Error::ConfigError, \
        "Empty list in YAML file '#{@input}'" \
        if @hosts.empty?

      raise Xi::ML::Error::ConfigError, \
        "YAML object stored in '#{@input}' is not an ARRAY" \
        unless @hosts.is_a?(Array)

    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Bad format of YAML file '#{@input}' : #{e.message}"
    end

    @logger.info("#{@hosts.size} urls given")
  end

  # Prepare the ES query based on the hosts / urls list
  #
  # @param filter [String] the type of filter to apply on urls list
  # @return [String] the generated query rules
  def prepare_rules(filter)
    case filter
    when 'host'
      @rules = filter_hosts()
    when 'url-qs'
      @rules = filter_urls_qs()
    when 'url-prefix'
      @rules = filter_urls_prefix()
    when 'url-regexp'
      @rules = filter_urls_regexp()
    end

    @rules
  end

  # Keep only the host of each url and use an ES query on 'site'
  # Note: a host can be formated as
  #  * String: "lequipe", "lequipe.fr", "www.lequipe.fr", ...
  #  * URL: "http://www.lequipe.fr"
  #
  # @return [String] the generated query rules
  def filter_hosts
    rules = []
    count_urls = 0

    @hosts.each do |item|
      # get the host (check if simple String or URL)
      if URI(item).host.nil?
        host = item
      else
        host = URI(item).host
      end

      # recover all parts of the url's host; Ex: lequipe, fr
      site = host.split('.')

      if site.empty?
        @logger.warn("No parts found for the '#{host}' host")
      else
        # create the ES query for the curent host; Ex: site:lequipe AND site:fr
        site.map! {|part| "site:#{part}" }
        cquery = '(' << site.join(' AND ') << ')'

        # group up all queries with an "OR" clause
        rules << cquery
        count_urls += 1
      end
    end

    @logger.info("#{count_urls} hosts considered")

    raise Xi::ML::Error::DataError, "Empty query built from the #{@input} file"\
      if rules.empty?

    # match one rule at a time: OR query
    rules = rules.join(' OR ')

    # return formatted query
    format_query('query_string', rules)
  end

  # Keep entire url and use an ES query on 'url'
  #
  # @return [String] the generated query rules
  def filter_urls_qs
    rules = []

    @hosts.each do |url|
      # remove http/https/www prefix
      url = url.sub(%r{^https?\:\/\/}, '')
      url = url.sub(/^(www.)?/, '')

      next if url.empty?

      # escape :/ (mandatory for query_string)
      url.gsub!(%r{\/}, '\\\\\/')
      url.gsub!(/:/, '\\\\\:')

      # prepare 4 urls with 4 possible prefixes (http, https, wwww)
      hurls = []
      hurls << "http\\\\:\\\\/\\\\/#{url}*"
      hurls << "http\\\\:\\\\/\\\\/www.#{url}*"
      hurls << "https\\\\:\\\\/\\\\/#{url}*"
      hurls << "https\\\\:\\\\/\\\\/www.#{url}*"

      hurls.each do |hurl|
        rules << "url:#{hurl}"
      end
    end

    raise Xi::ML::Error::DataError, "Empty query built from the #{@input} file"\
      if rules.empty?

    # match one rule at a time: OR query
    rules = rules.join(' OR ')

    # return formatted query
    format_query('query_string', rules)
  end

  def filter_urls_prefix
    rules = []

    @hosts.each do |url|
      # remove http/https/www prefix
      url = url.sub(%r{^https?\:\/\/}, '')
      url = url.sub(/^(www.)?/, '')

      next if url.empty?

      # prepare 4 urls with 4 possible prefixes (http, https, wwww)
      hurls = []
      hurls << "\"http://#{url}\""
      hurls << "\"http://www.#{url}\""
      hurls << "\"https://#{url}\""
      hurls << "\"https://www.#{url}\""

      hurls.each do |hurl|
        rules << "{prefix: { url:#{hurl} } }"
      end
    end

    raise Xi::ML::Error::DataError, "Empty query built from the #{@input} file"\
      if rules.empty?

    # add ', ' between rules
    rules = rules.join(', ')

    # return formatted query
    format_query('query_filtered', rules)
  end

  def filter_urls_regexp
    rules = []

    @hosts.each do |url|
      # remove http/https/www prefix
      url = url.sub(%r{^https?\:\/\/}, '')
      url = url.sub(/^(www.)?/, '')

      next if url.empty?

      rules << "{regexp: { url:\"(https?://(www.)?)?#{url}.*\"} }"
    end

    raise Xi::ML::Error::DataError, "Empty query built from the #{@input} file"\
      if rules.empty?

    # add ', ' between rules
    rules = rules.join(', ')

    # return formatted query
    format_query('query_filtered', rules)
  end

  def format_query(type, rules)
    query = ''

    case type
    when 'query_string'
      query = <<-EOS
      {
        query: {
          query_string: {
            query: \"lang:#{@lang} AND ( #{rules} )\"
          }
        }
      }
      EOS
    when 'query_filtered'
      query = <<-EOS
      {
        query: {
          filtered: {
            query: { bool: { should: [ #{rules} ] } },
            filter: { term: { lang: \"#{@lang}\" } }
          }
        }
      }
      EOS
    else
      @logger.error(
        "Unknown query format option '#{type}'. Choose from #{FORMATS}")
    end

    query.strip.gsub(/\s+/, ' ')
  end

  def to_s
    @rules
  end

  private :read_hosts, :prepare_rules, \
    :filter_hosts, :filter_urls_qs, :filter_urls_prefix, :filter_urls_regexp, \
    :format_query
end
