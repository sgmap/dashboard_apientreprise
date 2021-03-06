class API::Elasticsearch::Driver

  QUERY='controller:\"/api/v1/*\" controller:\"/api/v2/*\" -controller:\"/api/v1/ping\"'

  def self.count_last_requests_in_interval(interval, timestamp_begin, timestamp_end)
    url = base_url + '/elasticsearch/_msearch?timeout=0&ignore_unavailable=true'
    date = Time.now.strftime("%Y.%m.%d")
    query = '{"index":["logstash-' + date + '"],"search_type":"count","ignore_unavailable":true}
{"query":{"filtered":{"query":{"query_string":{"query":"' + QUERY + '","analyze_wildcard":true}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"gte":' + timestamp_begin.to_s + ',"lte":' + timestamp_end.to_s + ',"format":"epoch_millis"}}}],"must_not":[]}}}},"size":0,"aggs":{"2":{"date_histogram":{"field":"@timestamp","interval":"' + interval + '","time_zone":"Europe/Berlin","min_doc_count":0,"extended_bounds":{"min":' + timestamp_begin.to_s + ',"max":' + timestamp_end.to_i.to_s + '}}}}}
'
    JSON.parse(call(url, query))
  end

  def self.count_last_requests(timestamp_begin, timestamp_end)
    url = base_url + '/elasticsearch/_msearch?timeout=0&ignore_unavailable=true'
    date = Time.now.strftime("%Y.%m.%d")
    query = '{"index":["logstash-' + date + '"],"search_type":"count","ignore_unavailable":true}
{"size":0,"aggs":{},"query":{"filtered":{"query":{"query_string":{"analyze_wildcard":true,"query":"' + QUERY + '"}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"gte":' + timestamp_begin.to_s + ',"lte":' + timestamp_end.to_s + ',"format":"epoch_millis"}}}],"must_not":[]}}}},"highlight":{"pre_tags":["@kibana-highlighted-field@"],"post_tags":["@/kibana-highlighted-field@"],"fields":{"*":{}},"require_field_match":false,"fragment_size":2147483647}}
'
    JSON.parse(call(url, query))
  end

  def self.count_last_30_days_requests
    url = base_url + '/elasticsearch/_msearch?timeout=0&ignore_unavailable=true'
    now = DateTime.now
    date_end = now.strftime('%Q').to_i
    date_begin = (now - 30.days).strftime('%Q').to_i

    today = Date.today
    indexes = (today - 30 .. today).inject([]) { |init, date| init.push(date.strftime("logstash-%Y.%m.%d")) }

    query = '{"index":' + indexes.to_s + ',"search_type":"count","ignore_unavailable":true}
{"size":0,"aggs":{},"query":{"filtered":{"query":{"query_string":{"analyze_wildcard":true,"query":"' + QUERY + '"}},"filter":{"bool":{"must":[{"range":{"@timestamp":{"gte":' + date_begin.to_s + ',"lte":' + date_end.to_s + ',"format":"epoch_millis"}}}],"must_not":[]}}}},"highlight":{"pre_tags":["@kibana-highlighted-field@"],"post_tags":["@/kibana-highlighted-field@"],"fields":{"*":{}},"require_field_match":false,"fragment_size":2147483647}}
'

    JSON.parse(call(url, query))
  end

  private

  def self.call(url, params = {})
    verify_ssl_mode = OpenSSL::SSL::VERIFY_NONE

    RestClient::Resource.new(
        url,
        verify_ssl: verify_ssl_mode,
        :headers => {"kbn-version" => "4.4.1"}
    ).post params, :content_type => 'application/json'
  end


  def self.base_url
    "https://#{Kibana[:login]}:#{Kibana[:password]}@kibana.apientreprise.fr:443"
  end
end
