# frozen_string_literal: true

# Copyright (c) 2018 FINFEX https://github.com/finfex


module PaymentServices
  class QIWI
    class Client
      include Virtus.model strict: true
      include AutoLogger

      Error = Class.new StandardError
      InternalError = Class.new Error

      class ServerError < Error
        # {"serviceName":"payment-history","errorCode":"auth.forbidden",
        # "userMessage":"Access denied","dateTime":"2018-08-21T12:13:34.514+03:00","traceId":"dfe5e6296491abfb"}
        def initialize(result)
          @result = OpenStruct.new(result)
        end

        def message
          "#{@result.errorCode}: #{@result.userMessage}"
        end

        def to_s
          message
        end
      end

      class OperationError < Error
        # {"code"=>"QWPRC-1021", "message"=>"Ограничение на исходящие платежи"}
        def initialize(result)
          @result = OpenStruct.new(result)
        end

        def message
          "#{@result.code}: #{@result.message}"
        end

        def to_s
          message
        end
      end

      ROWS = 10 # max 50
      URL_LAST_PAYMENTS = 'https://edge.qiwi.com/payment-history/v2/persons/:phone/payments'
      URL_CREATE_PAYOUT = 'https://edge.qiwi.com/sinap/api/v2/terms/99/payments'

      DEFAULT_CURRENCY = '643'

      attribute :phone, String
      attribute :token, String

      def payments
        list = parse_response get_payments
        logger.info "Payments has #{list['data'].count} records"
        list
      end

      def create_payout(id:, amount:, destination_account:)
        parse_response submit_payout(id: id, amount: amount, destination_account: destination_account)
      end

      private

      def timeout
        @timeout ||= PaymentServices.configuration.qiwi_timeout
      end

      def submit_payout(id:, amount:, destination_account:)
        uri = URI.parse URL_CREATE_PAYOUT
        logger.info "Create payment #{uri}"
        request = Net::HTTP::Post.new(uri, headers)
        request.body = {
          id: id.to_s,
          sum: { amount: amount, currency: DEFAULT_CURRENCY },
          paymentMethod: { type: 'Account', accountId: DEFAULT_CURRENCY },
          fields: { account: destination_account }
        }.to_json
        logger.info "request body #{request.body}"
        build_http(uri).request(request)
      end

      def get_payments
        uri = URI.parse(URL_LAST_PAYMENTS.gsub(':phone', phone))
        uri.query = "rows=#{ROWS}"
        logger.info "Get last payments #{uri}"
        response = build_http(uri).request Net::HTTP::Get.new uri, headers
        logger.info "Response code: #{response.code}"

        response
      end

      def build_http(uri)
        Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: true,
          verify_mode: OpenSSL::SSL::VERIFY_NONE,
          open_timeout: timeout,
          read_timeout: timeout
        )
      end

      def headers
        {
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
          'Authorization' => "Bearer #{token}"
        }
      end

      def parse_response(response)
        if /json/.match?(response.content_type)
          logger.debug "response is json: #{response.body}"
          result = MultiJson.load response.body

          if result['errorCode'].present?
            logger.error "Catch server error: #{result}"
            raise ServerError, result
          end

          unless response.code == '200'
            logger.error "Catch operation error: #{result}"
            raise OperationError, result
          end

          # Пример удачного ответа
          # {"id"=>"13", "terms"=>"99", "fields"=>{"account"=>"+79050274414"},
          # "sum"=>{"amount"=>30, "currency"=>"643"}, "transaction"=>{"id"=>"13774661349",
          # "state"=>{"code"=>"Accepted"}}, "source"=>"account_643"}
          result
        elsif response.code.to_s == '500'
          logger.error "#{phone}: Response code is 500, body: #{response.body}"
          raise InternalError, phone

        else
          logger.error "#{phone}: Unknown reponse content_type. code: #{response.code}"
          logger.error "#{phone}: Unknown reponse content_type. content_type: '#{response.content_type}'"
          logger.error "#{phone}: Unknown reponse content_type. body: #{response.body.to_s.force_encoding('utf-8')}"
          raise InternalError,
                "#{phone}: Unknown response: code=#{response.code}, \
              content_type='#{response.content_type}', \
              body: #{response.body.to_s.force_encoding('utf-8')}"
        end
      end
    end
  end
end
