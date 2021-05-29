# frozen_string_literal: true

require 'savon'

class PaymentServices::AdvCash
  class Client
    include AutoLogger
    TIMEOUT = 10
    SOAP_URL = 'https://wallet.advcash.com/wsm/merchantWebService?wsdl'

    def initialize(apiName:, authenticationToken:, accountEmail:)
      @apiName = apiName
      @authenticationToken = authenticationToken
      @accountEmail = accountEmail
    end

    def create_payout(params:)
      safely_parse soap_request(
        url: SOAP_URL,
        operation: :send_money,
        body: {
          arg0: {
            apiName: apiName,
            authenticationToken: authenticationToken,
            accountEmail: accountEmail
          },
          arg1: params
        }
      )
    end

    def find_transaction(id:)
      safely_parse soap_request(
        url: SOAP_URL,
        operation: :find_transaction,
        body: {
          arg0: {
            apiName: apiName,
            authenticationToken: authenticationToken,
            accountEmail: accountEmail
          },
          arg1: id
        }
      )
    end

    private

    attr_reader :apiName, :authenticationToken, :accountEmail

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
  end
end
