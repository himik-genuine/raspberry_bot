require 'json'
require 'net/http'
require 'openssl'

class TelegramApi
  def initialize(api_url, token)
    @bot_url = "#{api_url}bot#{token}/"
  end

  def session(tg_method, body = '')
    telegram_send(@bot_url + tg_method, rq_type(tg_method), body.to_json)
  end

  private

  def telegram_send(url, rq_type, body)
    uri = URI(url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    klass = Object.const_get "Net::HTTP::#{rq_type}"
    request = klass.new(uri, 'Content-Type' => 'application/json')
    request.body = body
    JSON.parse(http.request(request).body)
  end

  def rq_type(tg_method)
    tg_method.match?('get') ? 'Get' : 'Post'
  end
end
