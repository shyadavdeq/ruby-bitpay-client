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

  end

end
