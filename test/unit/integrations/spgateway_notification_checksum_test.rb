# encoding: utf-8
require 'test_helper'
require 'uri'

# Notification 的 CheckCode 驗證、狀態判斷與約定信用卡判斷。
# 預期的 CheckCode 皆以 Python hashlib 獨立計算；金鑰皆為假資料。
class SpgatewayNotificationChecksumTest < Minitest::Test
  include OffsitePayments::Integrations

  HASH_KEY = 'K' * 32
  HASH_IV  = 'I' * 16

  # sha256("HashIV=III..&Amt=30&MerchantID=MS0000001&MerchantOrderNo=ORDER0001&TradeNo=20260101000001&HashKey=KKK..").upper()
  VALID_CHECK_CODE = '6AC021B3F3056C6FA21074B963EEF189B3C5EA7EBAA943746720144B2DB926CC'

  def setup
    Spgateway.hash_key = HASH_KEY
    Spgateway.hash_iv  = HASH_IV
  end

  def build(overrides = {})
    params = {
      'Status' => 'SUCCESS', 'Message' => '付款成功', 'MerchantID' => 'MS0000001',
      'Amt' => '30', 'TradeNo' => '20260101000001', 'MerchantOrderNo' => 'ORDER0001',
      'RespondType' => 'String', 'CheckCode' => VALID_CHECK_CODE, 'PaymentType' => 'CREDIT',
      'PayTime' => '2026-01-01 09:00:00'
    }.merge(overrides)
    params.delete_if { |_, v| v.nil? }
    Spgateway::Notification.new(URI.encode_www_form(params))
  end

  def test_checksum_ok_with_independently_computed_check_code
    assert build.checksum_ok?
  end

  def test_acknowledge_delegates_to_checksum_ok
    assert build.acknowledge
    refute build('Amt' => '31').acknowledge
  end

  def test_checksum_fails_when_amount_is_tampered
    refute build('Amt' => '1').checksum_ok?
  end

  def test_checksum_fails_when_order_no_is_tampered
    refute build('MerchantOrderNo' => 'ORDER0002').checksum_ok?
  end

  def test_checksum_fails_when_trade_no_or_merchant_id_is_tampered
    refute build('TradeNo' => '20260101000002').checksum_ok?
    refute build('MerchantID' => 'MS0000002').checksum_ok?
  end

  def test_checksum_ignores_fields_not_covered_by_check_code
    assert build('Message' => 'anything else', 'PayTime' => '1999-01-01 00:00:00').checksum_ok?
  end

  def test_checksum_fails_with_wrong_hash_key_or_iv
    refute build.tap { |n| n.hash_key = 'x' * 32 }.checksum_ok?
    refute build.tap { |n| n.hash_iv = 'y' * 16 }.checksum_ok?
  end

  def test_instance_hash_key_and_iv_override_global_config
    Spgateway.hash_key = 'wrong'
    Spgateway.hash_iv  = 'wrong'
    notification = build
    notification.hash_key = HASH_KEY
    notification.hash_iv  = HASH_IV

    assert notification.checksum_ok?
  end

  def test_checksum_fails_without_check_code
    refute build('CheckCode' => nil).checksum_ok?
  end

  def test_checksum_fails_without_covered_fields_instead_of_raising
    refute build('Amt' => nil).checksum_ok?
    refute build('TradeNo' => nil, 'MerchantID' => nil).checksum_ok?
  end

  def test_checksum_is_case_sensitive_on_check_code
    refute build('CheckCode' => VALID_CHECK_CODE.downcase).checksum_ok?
  end

  def test_checksum_url_encodes_special_characters
    # MerchantOrderNo=ORDER+0001（空白在 www-form 編碼為 +），金鑰與 IV 也是另一組假資料
    notification = build('MerchantOrderNo' => 'ORDER 0001',
                         'CheckCode' => '9EE3B568724422CDB002D235246640CEFF155DC97D55D1208FD1B7A08BFB8BE9')
    notification.hash_key = 'otherK' * 5 + 'ab'
    notification.hash_iv  = 'otherI' * 2 + 'ab'

    assert notification.checksum_ok?
  end

  def test_params_are_parsed_and_decoded
    notification = build

    assert_equal '付款成功', notification.message
    assert_equal 'MS0000001', notification.merchant_id
    assert_equal '30', notification.amt
    assert_equal '20260101000001', notification.trade_no
    assert_equal 'ORDER0001', notification.merchant_order_no
    assert_equal 'CREDIT', notification.payment_type
    assert_equal '2026-01-01 09:00:00', notification.pay_time
    assert_equal VALID_CHECK_CODE, notification.check_code
  end

  def test_success_and_complete_for_success_status
    notification = build('Status' => 'SUCCESS')

    assert notification.success?
    assert notification.complete?
  end

  def test_complete_but_not_success_for_custom_status
    notification = build('Status' => 'CUSTOM')

    refute notification.success?
    assert notification.complete?
  end

  def test_neither_success_nor_complete_for_failure_status
    notification = build('Status' => 'MPG03009')

    refute notification.success?
    refute notification.complete?
  end

  def test_credit_card_agreement_first_trade
    notification = build('TokenUseStatus' => '1')

    assert notification.credit_card_agreement_first_trade?
    refute notification.credit_card_agreement_token_trade?
  end

  def test_credit_card_agreement_token_trade
    notification = build('TokenLife' => '2030-12', 'TokenValue' => 'tok_fake')

    refute notification.credit_card_agreement_first_trade?
    assert notification.credit_card_agreement_token_trade?
  end

  def test_plain_trade_is_not_credit_card_agreement
    notification = build

    refute notification.credit_card_agreement_first_trade?
    refute notification.credit_card_agreement_token_trade?
  end

  def test_token_use_status_other_than_one_is_neither_first_nor_token_trade
    notification = build('TokenUseStatus' => '2', 'TokenLife' => '2030-12')

    refute notification.credit_card_agreement_first_trade?
    refute notification.credit_card_agreement_token_trade?
  end
end
