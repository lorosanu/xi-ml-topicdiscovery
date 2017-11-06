# encoding: utf-8



# Connect to ES client and loop results of ES query
class Xi::ML::Extract::ESSearch < Xi::ML::Tools::Component
  attr_reader :client, :host, :port, :index, :type, :query, :source

  # Initialize the ES client for the ES search
  #
  # @param host [String] the hostname of the ES server
  # @param port [String] the port of the ES server
  def initialize(host, port)
    super()
    @logger.info("Create the ES client: host=#{host}, port=#{port}")
    @host = host
    @port = port
    connect()
  end

  def connect
    raise Xi::ML::Error::ConfigError, "Port #{@port} is not open" \
      unless port_open?()

    @logger.info("Port '#{port}' is open. Connecting...")
    begin
      @client = Elasticsearch::Client.new(host: "#{@host}:#{@port}", log: false)
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Can not initialize ES client on '#{@host}'-'#{@port}': #{e.message}"
    end

    connected?
  end

  # Setup the search options
  #
  # @param index [String] the ES index
  # @param type [String] the ES type
  # @param source [Array] the list of fields to recover for each document
  # @param query [String] recover documents matching this query
  def search_setup(index:'', type:'', source:[], query:nil)
    @logger.info('Setup the ES search options: ')
    @logger.info("index=#{index} type=#{type} source=#{source} query=#{query}")

    @index = index
    @type = type
    @source = source.dup
    @query = query
  end

  # Process the current query and scroll its results
  def scroll

    # Execute the query on the '@index/@type' data
    # - search_type: 'scan' => do not compute ES score; do not sort documents
    # - scroll: '1m' => how long to keep the search context alive (1 minute)
    # - size: 1000 => how many documents each scroll request returns (per shard)
    # - filter on: 'lang' == <lang>, array 'site' includes {...} (@query)
    # - _source: [ ... ], => recover only requested fields (not entire entry)

    begin
      res = @client.search(
        index: "#{@index}",
        type: "#{@type}",
        scroll: '5m',
        search_type: 'scan',
        size: 1000,
        body: "#{@query}",
        _source: @source,
      )
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Exception encountered when executing query: #{e.message}"
    end

    # scroll the ES results
    @logger.info('Scroll the results ...')
    begin
      while (res = @client.scroll(scroll: '5m', scroll_id: res['_scroll_id']))\
        && !res['hits']['hits'].empty?

        res['hits']['hits'].each do |doc|
          yield doc
        end
      end
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "Exception encountered when scrolling results #{e.message}"
    end
  end


  # Test open port (optional)
  def port_open?
    begin
      Timeout.timeout(1) do
        begin
          s = TCPSocket.new(@host, @port)
          s.close
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          return false
        end
      end
    rescue Timeout::Error
      return false
    end

    false
  end

  # Test the ES connexion: abort in case of errors
  def connected?
    begin
      @client.cluster.health
    rescue => e
      raise Xi::ML::Error::CaughtException, \
        "ES client not connected: #{e.message}"
    end
    true
  end

  private :port_open?, :connect
end
