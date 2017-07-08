class HttpCache
  # This class is used by the other gems, like Redis and Typhoes for requisitions and such. We didn't touch it.
  def initialize
    @redis = Redis.new url: ENV["REDISTOGO_URL"] || "redis://redis.local/0"
  end

  def get(request)
    response_body = @redis.get url_id(request.base_url)
    if response_body
      Typhoeus::Response.new(return_code: :ok, code: 200, body: from_gzip(response_body))
    else
      nil
    end
  end

  def set(request, response)
    gziped = to_gzip(response.body)
    if gziped.size <= 660000
      fifteen_minutes = 15*60
      @redis.setex url_id(request.base_url), fifteen_minutes, gziped
    end
  rescue Exception => e
    # probably because of redis memory limit
    puts "Couldn't cache #{request.base_url}"
  end

  def url_id(url)
    uri = URI.parse url
    uri.query = uri.query.gsub(/client_id=[^=]*&client_secret=[^=]*/, "")
    uri.path + "?" + uri.query
  end

  def to_gzip(content)
    Base64.encode64(content)
  end

  def from_gzip(content)
    Base64.decode64(content)
  end
end
