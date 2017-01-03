# encoding: utf-8



# Creates the ES query based on a list of url hosts
class Xi::ML::Extract::Query < Xi::ML::Tools::Component
  attr_reader :input, :lang, :hosts, :rules

  FILTERS = %w[host url].freeze

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
  end

  # Prepare the ES query based on the hosts / urls list
  #
  # @param filter [String] the type of filter to apply on urls list
  # @return [String] the generated query rules
  def prepare_rules(filter)
    case filter
    when 'host'
      @rules = filter_hosts()
    when 'url'
      @rules = filter_urls()
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
    rules = ''
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
        rules += cquery << ' OR '
        count_urls += 1
      end
    end

    @logger.info("#{@hosts.size} urls given => #{count_urls} hosts considered")

    # remove final OR keyword (+ whitespaces)
    rules = rules[0..-5]

    raise Xi::ML::Error::DataError, "Empty query built from the #{@input} file"\
      if rules.empty?

    # final setup
    rules = "lang:#{@lang} AND ( #{rules} )"

    # query format
    query = "{ query: { query_string: { query: \"#{rules}\" } } }"

    # return query
    query
  end

  # Keep entire url and use an ES query on 'url'
  #
  # @return [String] the generated query rules
  def filter_urls
    rules = ''

    @hosts.each do |url|
      # remove http/https/www prefix
      url = url.sub(%r{^https?\:\/\/}, '')
      url = url.sub(/^(www.)?/, '')

      next if url.empty?

      # prepare 4 urls with 4 possible prefixes (http, https, wwww)
      hurls = []
      hurls << "http://#{url}*"
      hurls << "http://www.#{url}*"
      hurls << "https://#{url}*"
      hurls << "https://www.#{url}*"

      hurls.each do |hurl|
        # escape :/ (mandatory for query_string)
        hurl.gsub!(%r{\/}, '\\/')
        hurl.gsub!(/:/, '\\:')
        hurl.gsub!(%r{\/}, '\\/')
        hurl.gsub!(/:/, '\\:')

        rules << 'url:' << hurl << ' OR '
      end
    end

    @logger.info("#{@hosts.size} urls given")

    # remove final OR keyword (+ whitespaces)
    rules = rules[0..-5]

    raise Xi::ML::Error::DataError, "Empty query built from the #{@input} file"\
      if rules.empty?

    # final setup
    rules = "lang:#{@lang} AND ( #{rules} )"

    # query format
    query = "{ query: { query_string: { query: \"#{rules}\" } } }"

    # return query
    query
  end

  def to_s
    @rules
  end

  private :read_hosts, :prepare_rules, :filter_hosts, :filter_urls

end
