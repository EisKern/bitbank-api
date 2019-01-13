require 'net/https'
require 'uri'
require 'json'
require 'logger'

require 'openssl'
require 'active_support'
require 'active_support/core_ext'

class BitbankAPI
    Public_API_End_Point = "https://public.bitbank.cc"
    Private_API_End_Point = "https://api.bitbank.cc"    #fail to authenticate without /v1

    def initialize(key = nil, secret = nil, coin1, coin2)
        @key = key
        @secret = secret
        @pair = coin1 + "_" + coin2
        #@log = log
    end

    public

    #public API
    def ticker
        #@log.info('[API Public] Request Ticker')
        uri = URI.parse("#{Public_API_End_Point}/#{@pair}/ticker")
        response = https_request(uri)
        error_check('Public', 'Requesting Ticker', response)
    end

    def depth
        #@log.info('[API Public] Request Depth')
        uri = URI.parse("#{Public_API_End_Point}/#{@pair}/depth")
        response = https_request(uri)
        error_check('Public', 'Requesting Depth', response)
    end

    def transactions(date = nil)
        #@log.info("[API Public] Request Transactions #{date}")
        path = "#{Public_API_End_Point}/#{@pair}/transactions"
        path = path + "/#{date}" unless date.nil?
        uri = URI.parse(path)
        response = https_request(uri)
        error_check('Public', 'Requesting Transactions', response)
    end

    def candlestick(term, date)
        #@log.info("[API Public] Request Candlestick (term:#{term}, date:#{date})")
        uri = URI.parse("#{Public_API_End_Point}/#{@pair}/candlestick/#{term}/#{date}")
        response = https_request(uri)
        error_check('Public', 'Requesting Candlestick', response)
    end

    #private get API
    def read_assets
        #@log.info("[API Private] Request Assets")
        path = "/v1/user/assets"
        response = request_get(path)
        error_check('Private', 'Requesting Assets', response)
    end

    def read_status
        #@log.info("[API Private] Request Status of Exchanges")
        path = "/v1/spot/status"
        response = request_get(path)
        error_check('Private', 'Requesting Assets', response)
    end

    def read_order(id, allow_log = true)
        #@log.info("[API Private] Request Order Info (id:#{id})") if allow_log
        path = "/v1/user/spot/order"
        parms = {
            "pair": @pair,
            "order_id": id
        }.compact
        response = request_get(path, parms)
        error_check('Private', 'Requesting Order Info', response, allow_log)
    end

    #private post API
    def create_order(price = 20.0, amount = 1.0, side, type)
        #@log.info("[API Private] Create Order (pair:#{@pair}, price:#{price}, amount:#{amount}, side:#{side})")
        path = "/v1/user/spot/order"
        body = {
            pair: @pair,
            amount: amount,
            price: price,
            side: side,
            type: type
        }.to_json
        response = request_post(path, body)
        error_check('Private', 'Creating Order', response)
    end

    def cancel_order(order_id)
        #@log.info("[API Private] Cancel Order (id:#{order_id})")
        path = "/v1/user/spot/cancel_order"
        body = {
            pair: @pair,
            order_id: order_id
        }.to_json
        response = request_post(path, body)
        error_check('Private', 'Canceling Order', response)
    end

    def pair
        return @pair
    end

    private

    def https_request(uri, request = nil)
        https = https_setting(uri)
        response = https.start {
            if request.nil?
                https.get(uri.request_uri)
            else
                https.request(request)
            end
        }

        if response.code == '200'
            return JSON.parse(response.body)
        else
            return 301
        end
    end

    def request_get(path, query = {})
        nonce = Time.now.to_i.to_s
        uri = URI.parse(Private_API_End_Point + path)
        signature = get_get_signature(nonce, path, query)

        headers = {
            "Content-Type" => "application/json",
            "ACCESS-KEY" => @key,
            "ACCESS-NONCE" => nonce,
            "ACCESS-SIGNATURE" => signature
        }

        uri.query = query.to_query
        request = Net::HTTP::Get.new(uri.request_uri, initheader = headers)
        https_request(uri, request)
    end

    def request_post(path, body)
        nonce = Time.now.to_i.to_s
        uri = URI.parse(Private_API_End_Point + path)
        signature = get_post_signature(nonce, body)

        headers = {
            "Content-Type" => "application/json",
            "ACCESS-Key" => @key,
            "ACCESS-NONCE" => nonce,
            "ACCESS-SIGNATURE" => signature,
            "ACCEPT" => "application/json"
        }

        request = Net::HTTP::Post.new(uri.request_uri, initheader = headers)
        request.body = body
        https_request(uri, request)
    end

    def https_setting(uri)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        https.verify_mode = OpenSSL::SSL::VERIFY_PEER
        https.ca_file = "./tools/cacert.pem"
        return https
    end

    def get_get_signature(nonce, path, query = {})
        query_string = query.present? ? '?' + query.to_query : ''
        message = nonce + path + query_string
        signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @secret, message)
    end

    def get_post_signature(nonce, body = "")
        message = nonce + body
        signature = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new("sha256"), @secret, message)
    end

    def error_check(type, process, response, allow_log = true)
        if response == 301
            #@log.error("[API #{type}] 301: https Connection Error => #{process} failed")
            return 301
        elsif response["success"] == 0
            #@log.warn("[API #{type}] 302: Bitbank API Error (#{response["data"]["code"]}) => #{process} Failed")
            return response["data"]["code"]
        end
        #@log.info("[API #{type}] Succeeded in #{process}") if allow_log
        return response
    end
end
