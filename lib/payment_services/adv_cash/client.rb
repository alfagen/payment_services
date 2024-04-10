# frozen_string_literal: true

require 'savon'

class PaymentServices::AdvCash
  class Client
    include AutoLogger
    TIMEOUT = 10
    SOAP_URL = 'https://account.volet.com/wsm/apiWebService?wsdl'

    def initialize(api_name:, authentication_token:, account_email:)
      @api_name = api_name
      @authentication_token = authentication_token
      @account_email = account_email
    end

    def create_payout(params:)
      safely_parse soap_request(
        url: SOAP_URL,
        operation: :send_money,
        body: {
          arg0: authentication_params,
          arg1: params
        }
      )
    end

    def find_transaction(id:)
      safely_parse soap_request(
        url: SOAP_URL,
        operation: :find_transaction,
        body: {
          arg0: authentication_params,
          arg1: id
        }
      )
    end

    private

    attr_reader :api_name, :authentication_token, :account_email

    def encrypted_token
      sign_string = "#{authentication_token}:#{Time.now.utc.strftime('%Y%m%d:%H')}"

      Digest::SHA256.hexdigest(sign_string).upcase
    end

    def soap_request(url:, operation:, body:)
      logger.info "Request operation: #{operation} to #{url} with payload #{body}"

      Savon.client(wsdl: url, open_timeout: TIMEOUT, read_timeout: TIMEOUT).call(operation, message: body)
    end

    def safely_parse(response)
      res = response.body
      logger.info "Response: #{res}"
      res
    rescue Savon::SOAPFault => err
      logger.warn "Request failed #{response.class} #{response.body}"
      Bugsnag.notify err do |report|
        report.add_tab(:response, response_class: response.class, response_body: response.body)
      end
      response.body
    end

    def authentication_params
      {
        apiName: api_name,
        authenticationToken: encrypted_token,
        accountEmail: account_email
      }
    end
  end
end
