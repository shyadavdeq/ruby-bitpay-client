# frozen_string_literal: true

RSpec.describe Bitpay::RubyClient do

  let(:bitpay_client) { Bitpay::RubyClient }

  let(:pem) { ENV['PEM'] }

  let(:bitpay_client_with_pem) {
    bitpay_client.new(
      api_uri: ENV['TEST_API_URI'], pem: ENV['PEM'], insecure: true
    )
  }

  it "has a version number" do

    expect(Bitpay::Client::VERSION).not_to be nil

  end

  describe '#initialize' do

    it 'should create a new client object' do

      expect(bitpay_client.new(api_uri: ENV['TEST_API_URI'], pem: pem)).to be_truthy

    end

    describe 'when the pem key is passed to initialize the client' do

      it 'should initialize the client object associated with the pem key' do

        expect(bitpay_client_with_pem.client_id).to eq(ENV['CLIENT_ID'])

      end

    end

    describe 'when the pem key is not passed to initialize client' do

      before { @client = bitpay_client.new(api_uri: ENV['TEST_API_URI']) }

      it 'should create a new client object' do

        expect(@client.client_id).to_not eq(ENV['CLIENT_ID'])

      end

      it 'should generate a new pem to create client object' do

        expect(@client.pem).to_not eq(ENV['PEM'])

      end

    end

  end

  describe '#pair_client' do

    before { @token_response = bitpay_client_with_pem.pair_client() }

    it 'should return the pairing code to initiate client side authentication' do
      expect(@token_response['data'][0].has_key?('pairingCode')).to be_truthy
    end

    it 'should contain the token for the client with pairing code' do
      expect(@token_response['data'][0].has_key?('token')).to be_truthy
    end

  end

  describe '#pair_pos_client' do

    # Pre-requisite generate a pairing code from the Bitpay account.
    it 'should perform the server side authentication with a valid pairing code' do
      expect(bitpay_client_with_pem.pair_pos_client('sGRsvNP')).to be_truthy
    end

    it 'should raise a error if the pairing code format is not valid' do
      expect { bitpay_client_with_pem.pair_pos_client('eBeP7t@') }
        .to raise_error(Bitpay::ArgumentError, 'Pairing code is invalid')
    end

    it 'should raise a error if the pairing code is illegal'

  end

  describe '#create_invoice' do

    describe 'validates the price format ' do

      it 'should raise error if the price is not a number' do
        expect { bitpay_client_with_pem.create_invoice(price: 'One hundred', currency: 'USD') }
          .to raise_error(
            Bitpay::ArgumentError, 'Illegal Argument: Price must be formatted as a float'
          )
      end

      it 'should raise error if the price is not formatted in float' do

        expect { bitpay_client_with_pem.create_invoice(price: '1,000', currency: 'USD') }
          .to raise_error(
            Bitpay::ArgumentError, 'Illegal Argument: Price must be formatted as a float'
          )

      end

      it 'should not raise error if the price is in float' do

        expect { bitpay_client_with_pem.create_invoice(price: 50.00, currency: 'USD') }
          .not_to raise_error(
            Bitpay::ArgumentError, 'Illegal Argument: Price must be formatted as a float'
          )

      end

      it 'should not raise error if the price is formatted in float' do

        expect { bitpay_client_with_pem.create_invoice(price: '50.00', currency: 'USD') }
          .not_to raise_error(
            Bitpay::ArgumentError, 'Illegal Argument: Price must be formatted as a float'
          )

      end


      it 'should raise error if the price has more scalar value' do

        expect { bitpay_client_with_pem.create_invoice(price: '50.000015', currency: 'USD') }
          .to raise_error(
            Bitpay::ArgumentError, 'Illegal Argument: Price must be formatted as a float'
          )

      end

      it 'should not raise error if the currency is Bitcoin and price has more scalar value' do

        expect { bitpay_client_with_pem.create_invoice(price: '50.000015', currency: 'BTC') }
          .not_to raise_error(
            Bitpay::ArgumentError, 'Illegal Argument: Price must be formatted as a float'
          )

      end

    end

    describe 'validates the currency format ' do

      it 'should raise error if the currency character is not as ISO certified' do

        expect { bitpay_client_with_pem.create_invoice(price: '50.00', currency: 'USD$') }
          .to raise_error(
            Bitpay::ArgumentError, 'Illegal Argument: Currency is invalid'
          )

      end

      it 'should not raise error if the currency character is as per ISO certified' do

        expect { bitpay_client_with_pem.create_invoice(price: '50.00', currency: 'USD') }
          .not_to raise_error(
            Bitpay::ArgumentError, 'Illegal Argument: Currency is invalid'
          )

      end

    end

    it 'create an invoices for the bitpay account' do
      expect(bitpay_client_with_pem.create_invoice(price: '50.00', currency: 'USD'))
        .to be_truthy
    end

  end

end
