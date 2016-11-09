# encoding: utf-8
require 'digest'

module OffsitePayments #:nodoc:
  module Integrations #:nodoc:
    module Spgateway
      class Helper < OffsitePayments::Helper
        FIELDS = %w(
          MerchantID LangType MerchantOrderNo Amt ItemDesc TradeLimit
          ExpireDate ReturnURL NotifyURL CustomerURL ClientBackURL Email
          EmailModify LoginType OrderComment CREDIT CreditRed InstFlag UNIONPAY
          WEBATM VACC CVS BARCODE CUSTOM TokenTerm CREDITAGREEMENT TokenLife
        )

        FIELDS.each do |field|
          mapping field.underscore.to_sym, field
        end
        mapping :account, 'MerchantID' # AM common
        mapping :amount, 'Amt' # AM common

        # 廠商編號(由 allpay 提供)
        # type: Varchar(10)
        # presense: true
        # example: 2000132
        # description:
        # mapping :merchant_id, 'MerchantID'
        # mapping :account, 'MerchantID' # AM common

        def initialize(order, account, options = {})
          super
          add_field 'Version', OffsitePayments::Integrations::Spgateway::VERSION
          add_field 'RespondType', OffsitePayments::Integrations::Spgateway::RESPOND_TYPE
          OffsitePayments::Integrations::Spgateway::CONFIG.each do |field|
            add_field field, OffsitePayments::Integrations::Spgateway.send(field.underscore.to_sym)
          end
        end

        def hash_key(key)
          @key = key
        end

        def hash_iv(iv)
          @iv = iv
        end

        def merchant_hash_key
          @key || OffsitePayments::Integrations::Spgateway.hash_key
        end

        def merchant_hash_iv
          @iv || OffsitePayments::Integrations::Spgateway.hash_iv
        end

        def time_stamp(date)
          add_field 'TimeStamp', date.to_time.to_i
        end

        def encrypted_data
          raw_data = URI.encode_www_form OffsitePayments::Integrations::Spgateway::CHECK_VALUE_FIELDS.sort.map { |field|
            [field, @fields[field]]
          }

          hash_raw_data = "HashKey=#{merchant_hash_key}&#{raw_data}&HashIV=#{merchant_hash_iv}"
          add_field 'CheckValue', Digest::SHA256.hexdigest(hash_raw_data).upcase
        end
      end
    end
  end
end
