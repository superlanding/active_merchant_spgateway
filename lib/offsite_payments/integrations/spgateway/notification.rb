# encoding: utf-8
require 'digest'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Spgateway
      class Notification < OffsitePayments::Notification
        PARAMS_FIELDS = %w(
          Status Message MerchantID Amt TradeNo MerchantOrderNo PaymentType RespondType CheckCode PayTime IP
          EscrowBank TokenUseStatus RespondCode Auth Card6No Card4No Inst InstFirst InstEach ECI PayBankCode
          PayerAccount5Code CodeNo BankCode Barcode_1 Barcode_2 Barcode_3 ExpireDate CheckCode TokenValue TokenLife
        )

        PARAMS_FIELDS.each do |field|
          define_method field.underscore do
            @params[field]
          end
        end

        def hash_key=(key)
          @hash_key = key
        end

        def hash_iv=(iv)
          @hash_iv = iv
        end

        def hash_key
          @hash_key || OffsitePayments::Integrations::Spgateway.hash_key
        end

        def hash_iv
          @hash_iv || OffsitePayments::Integrations::Spgateway.hash_iv
        end

        def success?
          status == 'SUCCESS'
        end

        # TODO 使用查詢功能實作 acknowledge
        # Spgateway 沒有遠端驗證功能，
        # 而以 checksum_ok? 代替
        def acknowledge
          checksum_ok?
        end

        def complete?
          %w(SUCCESS CUSTOM).include? status
        end

        def checksum_ok?
          raw_data = URI.encode_www_form OffsitePayments::Integrations::Spgateway::CHECK_CODE_FIELDS.sort.map { |field|
            [field, @params[field]]
          }

          hash_raw_data = "HashIV=#{hash_iv}&#{raw_data}&HashKey=#{hash_key}"
          Digest::SHA256.hexdigest(hash_raw_data).upcase == check_code
        end

        # 是否為約定信用卡授權首次交易
        def credit_card_agreement_first_trade?
          token_use_status == "1"
        end

        # 是否為信用卡授權 token 交易
        def credit_card_agreement_token_trade?
          token_use_status.blank? && token_life.present?
        end
      end
    end
  end
end
