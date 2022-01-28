module Bitpay

  module RestConnector

    def get(path:, token: nil, public: false, query_filter: nil)
      if token
        token_prefix = path.include?('?') ? '&token=' : '?token='
        path += token_prefix + token
      end

      path += query_filter unless query_filter.nil?

      request = Net::HTTP::Get.new(path)
      unless public
        request['X-Signature'] = Bitpay::RubyKeyutils.sign(@uri.to_s + path, @priv_key)
        request['X-Identity'] = @pub_key
      end

      process_request(request)
    end

    def post(path:, token: nil, params:)
      request = Net::HTTP::Post.new(path)
      params[:token] = token if token
      params[:guid] = SecureRandom.uuid
      params[:id] = @client_id
      request.body = params.to_json

      if token
        request['X-Signature'] = Bitpay::RubyKeyutils.sign(
          @uri.to_s + path + request.body, @priv_key
        )
        request['X-Identity'] = @pub_key
      end

      process_request(request)
    end

    private

    # Processes HTTP Request and returns parsed response
    # Otherwise throws error
    #
    def process_request(request)
      request['User-Agent'] = @user_agent
      request['Content-Type'] = 'application/json'
      request['X-Accept-Version'] = '2.0.0'
      request['X-BitPay-Plugin-Info'] = 'Rubylib' + Bitpay::Client::VERSION

      begin
        response = @https.request(request)
      rescue => error
        raise ResponseError, "#{error.message}"
      end

      if response.kind_of? Net::HTTPSuccess
        JSON.parse(response.body)
      elsif JSON.parse(response.body)["error"]
        raise(ResponseError, "#{response.code}: #{JSON.parse(response.body)['error']}")
      else
        raise ResponseError, "#{response.code}: #{JSON.parse(response.body)}"
      end

    end

  end

end
