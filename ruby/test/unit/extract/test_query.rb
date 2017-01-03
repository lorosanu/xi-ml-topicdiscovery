# encoding: utf-8


require 'tempfile'
require 'minitest/autorun'

$LOAD_PATH.unshift 'lib/'
require 'xi/ml'

class QueryTest < Minitest::Unit::TestCase
  def setup
    hosts = ['http://www.lequipe.fr/', 'http://www.sports.fr/']

    @file = Tempfile.new('test_query.yaml')
    @file.write(hosts.to_yaml())
    @file.close
  end

  def test_rules_host
    @query = Xi::ML::Extract::Query.new(@file.path, 'fr', 'host')

    rules = '{ query: { query_string: { query: "lang:fr AND '\
      + '( (site:www AND site:lequipe AND site:fr) '\
      + 'OR (site:www AND site:sports AND site:fr) )" } } }'

    assert_equal rules, @query.to_s
  end

  def test_rules_url
    @query = Xi::ML::Extract::Query.new(@file.path, 'fr', 'url')

    rules = '{ query: { query_string: { query: "lang:fr AND '\
      + '( url:http\\\\:\\\\/\\\\/lequipe.fr\\\\/* OR '\
      + 'url:http\\\\:\\\\/\\\\/www.lequipe.fr\\\\/* OR '\
      + 'url:https\\\\:\\\\/\\\\/lequipe.fr\\\\/* OR '\
      + 'url:https\\\\:\\\\/\\\\/www.lequipe.fr\\\\/* OR '\
      + 'url:http\\\\:\\\\/\\\\/sports.fr\\\\/* OR '\
      + 'url:http\\\\:\\\\/\\\\/www.sports.fr\\\\/* OR '\
      + 'url:https\\\\:\\\\/\\\\/sports.fr\\\\/* OR '\
      + 'url:https\\\\:\\\\/\\\\/www.sports.fr\\\\/* )" } } }'

    assert_equal rules, @query.to_s
  end

  def teardown
    @file.unlink
  end
end
