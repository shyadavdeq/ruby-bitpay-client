# frozen_string_literal: true

libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)
puts $LOAD_PATH

require 'dotenv/load'
require 'bitpay/ruby_client'
require 'bitpay/client_version'

module Bitpay

  module Client

    class << self

      def cert_file_path
        File.join File.dirname(__FILE__), 'bitpay','cacert.pem'
      end

      # User agent reported to API
      def user_agent
        'BitPay_Ruby_Client_v' + VERSION
      end

    end

    class Bitpay::Error < StandardError; end

    class Bitpay::ArgumentError < ArgumentError; end

  end

end

