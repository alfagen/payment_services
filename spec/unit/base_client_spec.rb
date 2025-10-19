# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

# Mock the base client class for testing
class TestBaseClient
  TIMEOUT = 30

  def http_request(url:, method:, body: nil, headers: nil)
    uri = URI.parse(url)
    https = http(uri)
    request = build_request(uri: uri, method: method, body: body, headers: headers)
    https.request(request)
  end

  def build_request(uri:, method:, body: nil, headers: nil)
    request = if method == :POST
                Net::HTTP::Post.new(uri.request_uri, headers)
              elsif method == :GET
                Net::HTTP::Get.new(uri.request_uri, headers)
              elsif method == :PATCH
                Net::HTTP::Patch.new(uri.request_uri, headers)
              else
                raise "Запрос #{method} не поддерживается!"
              end
    request.body = body
    request
  end

  def http(uri)
    Net::HTTP.start(uri.host, uri.port,
                    use_ssl: true,
                    verify_mode: OpenSSL::SSL::VERIFY_NONE,
                    open_timeout: TIMEOUT,
                    read_timeout: TIMEOUT)
  end

  def safely_parse(response)
    res = JSON.parse(response.body)
    res
  rescue JSON::ParserError, TypeError => err
    response.body
  end
end

RSpec.describe TestBaseClient do
  let(:client) { described_class.new }

  describe '#build_request' do
    let(:uri) { URI.parse('https://example.com/api') }

    context 'when method is POST' do
      it 'creates Net::HTTP::Post request' do
        request = client.build_request(uri: uri, method: :POST, body: 'test data')

        expect(request).to be_a(Net::HTTP::Post)
        expect(request.body).to eq('test data')
      end
    end

    context 'when method is GET' do
      it 'creates Net::HTTP::Get request' do
        request = client.build_request(uri: uri, method: :GET)

        expect(request).to be_a(Net::HTTP::Get)
      end
    end

    context 'when method is PATCH' do
      it 'creates Net::HTTP::Patch request' do
        request = client.build_request(uri: uri, method: :PATCH, body: 'patch data')

        expect(request).to be_a(Net::HTTP::Patch)
        expect(request.body).to eq('patch data')
      end
    end

    context 'when method is unsupported' do
      it 'raises error' do
        expect {
          client.build_request(uri: uri, method: :DELETE)
        }.to raise_error('Запрос DELETE не поддерживается!')
      end
    end
  end

  describe '#safely_parse' do
    let(:response) { double('Response') }

    context 'when response body is valid JSON' do
      before do
        allow(response).to receive(:body).and_return('{"status": "success", "data": [1, 2, 3]}')
      end

      it 'parses JSON and returns hash' do
        result = client.safely_parse(response)

        expect(result).to eq({ 'status' => 'success', 'data' => [1, 2, 3] })
      end
    end

    context 'when response body is invalid JSON' do
      before do
        allow(response).to receive(:body).and_return('invalid json')
      end

      it 'returns raw body' do
        result = client.safely_parse(response)

        expect(result).to eq('invalid json')
      end
    end

    context 'when response body is nil' do
      before do
        allow(response).to receive(:body).and_return(nil)
      end

      it 'returns nil body' do
        result = client.safely_parse(response)

        expect(result).to be_nil
      end
    end
  end
end