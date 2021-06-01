# frozen_string_literal: true

require 'nokogiri'
require 'csv'

class PaymentServices::PerfectMoney
  class Client
    include AutoLogger
    TIMEOUT = 10
    API_URL = 'https://perfectmoney.is/acct'

    def initialize(account_id:, pass_phrase:, account:)
      @account_id = account_id
      @pass_phrase = pass_phrase
      @account = account
    end

    def create_payout(destination_account:, amount:, payment_id:)
      safely_parse(
        http_request(
          url: API_URL + '/confirm.asp?',
          method: :GET,
          body: {
            AccountID: account_id,
            PassPhrase: pass_phrase,
            Payer_Account: account,
            Payee_Account: destination_account,
            Amount: amount,
            PAYMENT_ID: payment_id
          }
        ),
        mode: :html
      )
    end

    def find_transaction(payment_batch_number:)
      safely_parse(
        http_request(
          url: API_URL + '/historycsv.asp?',
          method: :GET,
          body: {
            batchfilter: payment_batch_number,
            AccountID: account_id,
            PassPhrase: pass_phrase,
            startmonth: now_utc.month, 
            startday: now_utc.day,
            startyear: now_utc.year,
            endmonth: now_utc.month,
            endday: now_utc.day,
            endyear: now_utc.year
          }
        ),
        mode: :csv
      )
    end

    private

    attr_reader :account_id, :pass_phrase, :account

    def http_request(url:, method:, body: nil)
      uri = URI.parse(url + body.to_query)
      https = http(uri)
      request = build_request(uri: uri, method: method, body: body)
      logger.info "Request type: #{method} to #{uri} with payload #{request.body}"
      https.request(request)
    end

    def build_request(uri:, method:, body: nil)
      request = if method == :POST
                  Net::HTTP::Post.new(uri.request_uri)
                elsif method == :GET
                  Net::HTTP::Get.new(uri.request_uri)
                else
                  raise "Запрос #{method} не поддерживается!"
                end
      request.body = URI.encode_www_form((body.present? ? body : {}))
      request
    end

    def http(uri)
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: true,
                      verify_mode: OpenSSL::SSL::VERIFY_NONE,
                      open_timeout: TIMEOUT,
                      read_timeout: TIMEOUT)
    end

    def safely_parse(response, mode:)
      body = response.body
      logger.info "Response: #{body}"

      if mode == :html
        html_to_hash(body)
      elsif mode == :csv
        csv_to_hash(body)
      end
    rescue => err
      logger.warn "Request failed #{response.class} #{response}"
      Bugsnag.notify err do |report|
        report.add_tab(:response, response_class: response.class, response_body: response)
      end
      response
    end

    def html_to_hash(response)
      h = {}
      html = Nokogiri::HTML(response)

      html.xpath('//input[@type="hidden"]').each do |input|
        h[input.attributes['name'].value] = input.attributes['value'].value
      end

      h
    end

    def csv_to_hash(response)
      CSV.parse(response, headers: :first_row).map(&:to_h).first
    end

    def now_utc
      @now_utc ||= Time.now.utc
    end
  end
end
