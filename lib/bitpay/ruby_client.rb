# https://stackoverflow.com/a/12334707
# Remove for local setup
$LOAD_PATH.unshift '/home/deq/projects/sh_bitpay/ruby-bitpay-keyutils/lib'
require 'bitpay_keyutils'

require 'net/http'
require 'json'
require 'bitpay/rest_connector'

module Bitpay

  class RubyClient

    include Bitpay::RestConnector

    # Create a Bitpay client with a pem file.
    #
    # * It uses the ruby-bitpay-keyutils to generate the required keys.
    # @note 'api_uri' should be passed in test environment, if not passed defaults to production.
    #
    # @return [Object<Bitpay::RubyClient>]
    def initialize(options={})
      @pem = options[:pem] || Bitpay::RubyKeyutils.generate_pem
      @key = Bitpay::RubyKeyutils.create_key(@pem)
      @priv_key = Bitpay::RubyKeyutils.get_private_key(@key)
      @pub_key = Bitpay::RubyKeyutils.get_public_key(@key)
      @client_id = Bitpay::RubyKeyutils.generate_sin_from_pem(@pem)
      @uri = URI.parse options[:api_uri] || ENV['API_URI']
      @user_agent = options[:user_agent] || Bitpay::Client.user_agent
      @tokens = options[:tokens] || {}

      @https = Net::HTTP.new(@uri.host, @uri.port)
      @https.use_ssl = true
      @https.open_timeout = 10
      @https.read_timeout = 10

      # @todo Add the certificates
      @https.ca_file = Bitpay::Client.cert_file_path

      # Option to disable certificate validation in extraordinary circumstance.
      @https.verify_mode = if options[:insecure] == true
        OpenSSL::SSL::VERIFY_NONE
      else
        OpenSSL::SSL::VERIFY_PEER
      end

      # Option to enable http request debugging
      @https.set_debug_output($stdout) if options[:debug] == true
    end

    # Returns the unique Client ID for the client object.
    #
    # @return [String]
    def client_id
      @client_id
    end

    # Returns the unique Client ID for the client object.
    #
    # @return [String]
    def pem
      @pem
    end

    # Authenticate with Bitpay to set a valid token(created from a key) with account to get access
    # from the client side or the server side.
    #
    # @params params [Hash]
    #
    # @see BitPay authentication in 'https://github.com/bitpay/ruby-bitpay-client' README.md
    def pair_client(params = {})
      post(path: '/tokens', params: params)
    end

    # Authenticate with Bitpay from server side, with pairing code generated from account.
    #
    # @params pairing_code [String]
    def pair_pos_client(pairing_code)
      pair_client(pairingCode: pairing_code) if pairing_code_valid?(pairing_code)
    end

    # Updates the Client object with the authenticated tokens fetched from server.
    #
    # @return [void]
    def refresh_tokens
      response = get(path: '/tokens')
      client_token = {}
      @tokens = response['data'].inject({}) { |data, value| data.merge(value) }
    end

    # Creates the Invoice.
    def create_invoice(price:, currency:, facade: 'pos', params: {})
      if price_format_valid?(price, currency) && currency_valid?(currency)
        params.merge!({ price: price, currency: currency })
        token = get_token(facade)
        invoice = post(path: '/invoices', token: token, params: params)
        invoice['data']
      end
    end

    # Fetches the invoice with a facade version using the Token and given invoiceID.
    #
    # @params id [String] Invoice ID
    # @params facade [String] Facade name to fetch the version invoice
    # @params params [Hash] Filter keywords which we need to filter the invoices
    #   * dateStart
    #   * dateEnd
    #   * status
    #   * orderId
    #   * limit
    #   * offset
    def get_invoice(id:, facade: 'pos', params: {})
      token = get_token(facade)
      invoice = get(path: "/invoices/#{id}", token: token, query_filter: query_filter(params))
      invoice["data"]
    end

    # Fetches the invoice with a public version on given invoiceID.
    #
    # @param id [String] Invoice ID
    def get_public_invoice(id:)
      invoice = get(path: "/invoices/#{id}", public: true)
      invoice["data"]
    end

    private

    # Verifies the Pairing Code is valid or not.
    #
    # @params pairing_code [String]
    #
    # @return [Boolean, Bitpay::ArgumentError]
    #
    # @todo - Provision to verify if the pairing code is valid with Bitpay server if generated
    # from account.
    def pairing_code_valid?(pairing_code)
      regex = /^[[:alnum:]]{7}$/
      return true unless regex.match(pairing_code).nil?

      raise ArgumentError, 'Pairing code is invalid'
    end

    # Verifies the invoice price is in required format.
    #
    # * If it is invalid, raises Bitpay::ArgumentError.
    def price_format_valid?(price, currency)
      float_regex = /^[[:digit:]]+(\.[[:digit:]]{2})?$/
      return true if price.is_a?(Numeric) ||
        !float_regex.match(price).nil? ||
        (currency == 'BTC' && btc_price_format_valid?(price))

      raise ArgumentError, 'Illegal Argument: Price must be formatted as a float'
    end

    # Verifies the regex for a BTC currency invoice price.
    def btc_price_format_valid?(price)
      regex = /^[[:digit:]]+(\.[[:digit:]]{1,6})?$/

      !regex.match(price).nil?
    end

    # Verifies the invoice currency is valid or not.
    #
    # * If it is invalid, raises Bitpay::ArgumentError.
    def currency_valid?(currency)
      regex = /^[[:upper:]]{3}$/
      return true if !regex.match(currency).nil?

      raise ArgumentError, 'Illegal Argument: Currency is invalid'
    end

    # Returns the token for the given facade of the Bitpay client.
    #
    # @return [String]
    def get_token(facade)
      refresh_tokens[facade] || raise(ResponseError, "Not authorized for facade: #{facade}")
    end

    # Returns the query string to filter the invoice records.
    #
    # @param (see #get_invoice)
    def query_filter(params)
      return if params.empty?

      query = ''
      params.each do |key, value|
        query += "&#{key}=#{value}"
      end
      query
    end

  end

end
