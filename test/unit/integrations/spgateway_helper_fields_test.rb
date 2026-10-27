# encoding: utf-8
require 'test_helper'

# Helper 的欄位對應、設定值與 CheckValue（SHA256）計算。
# 預期的 CheckValue 都是以另一套實作（Python hashlib + urllib quote_plus）獨立算出，
# 不是用被測的程式碼產生；金鑰皆為假資料。
class SpgatewayHelperFieldsTest < Minitest::Test
  include OffsitePayments::Integrations

  HASH_KEY = 'K' * 32
  HASH_IV  = 'I' * 16

  # Python 獨立計算：
  #   sha256("HashKey=KKK..&Amt=200&MerchantID=M123&MerchantOrderNo=ORDER0001&TimeStamp=1403243286&Version=1.2&HashIV=III..").upper()
  ORDER0001_CHECK_VALUE = 'D6ABEC841A572C7892E433BC8842C2285285CB2B51C2AA08BAF86874109FB281'

  def setup
    Spgateway.hash_key = HASH_KEY
    Spgateway.hash_iv  = HASH_IV
  end

  def build_helper(order_no)
    helper = Spgateway::Helper.new('ORD1', 'M123', amount: 200)
    helper.merchant_order_no order_no
    helper.time_stamp Time.at(1403243286)
    helper
  end

  def test_initialize_sets_account_amount_version_and_respond_type
    helper = Spgateway::Helper.new('ORD1', 'M123', amount: 200)

    assert_equal 'M123', helper.fields['MerchantID']
    assert_equal '200', helper.fields['Amt']
    assert_equal '1.2', helper.fields['Version']
    assert_equal 'String', helper.fields['RespondType']
  end

  def test_mapped_setters_write_gateway_field_names
    helper = Spgateway::Helper.new('ORD1', 'M123')
    helper.item_desc '商品一'
    helper.email 'buyer@example.test'
    helper.login_type 0
    helper.return_url 'https://example.test/return'
    helper.credit 1
    helper.creditagreement 1
    helper.token_term 'user-1'

    assert_equal '商品一', helper.fields['ItemDesc']
    assert_equal 'buyer@example.test', helper.fields['Email']
    assert_equal '0', helper.fields['LoginType']
    assert_equal 'https://example.test/return', helper.fields['ReturnURL']
    assert_equal '1', helper.fields['CREDIT']
    assert_equal '1', helper.fields['CREDITAGREEMENT']
    assert_equal 'user-1', helper.fields['TokenTerm']
  end

  def test_global_config_values_become_helper_fields
    Spgateway.notify_url = 'https://example.test/notify'
    Spgateway.lang_type  = 'en'
    helper = Spgateway::Helper.new('ORD1', 'M123')

    assert_equal 'https://example.test/notify', helper.fields['NotifyURL']
    assert_equal 'en', helper.fields['LangType']
  end

  def test_unset_global_config_values_are_not_added
    Spgateway.trade_limit = nil
    helper = Spgateway::Helper.new('ORD1', 'M123')

    refute helper.fields.key?('TradeLimit')
  end

  def test_time_stamp_is_unix_seconds
    helper = Spgateway::Helper.new('ORD1', 'M123')
    helper.time_stamp Time.at(1403243286)

    assert_equal '1403243286', helper.fields['TimeStamp']
  end

  def test_encrypted_data_matches_independently_computed_sha256
    helper = build_helper('ORDER0001')
    helper.encrypted_data

    assert_equal ORDER0001_CHECK_VALUE, helper.fields['CheckValue']
  end

  def test_encrypted_data_url_encodes_special_characters
    helper = build_helper('A B&C')
    helper.encrypted_data

    # MerchantOrderNo=A+B%26C
    assert_equal '34FF1F516E6B9A37653B103AE1C03FCB49703EC2419120B5328055378A9D4F0F', helper.fields['CheckValue']
  end

  def test_encrypted_data_is_uppercase_64_hex
    helper = build_helper('ORDER0001')
    helper.encrypted_data

    assert_match(/\A[0-9A-F]{64}\z/, helper.fields['CheckValue'])
  end

  def test_encrypted_data_changes_when_any_checked_field_changes
    base = build_helper('ORDER0001').tap(&:encrypted_data).fields['CheckValue']

    other_order = build_helper('ORDER0002').tap(&:encrypted_data).fields['CheckValue']
    other_amount = build_helper('ORDER0001').tap { |h| h.amount 201 }.tap(&:encrypted_data).fields['CheckValue']

    refute_equal base, other_order
    refute_equal base, other_amount
  end

  def test_encrypted_data_ignores_unchecked_fields
    base = build_helper('ORDER0001').tap(&:encrypted_data).fields['CheckValue']
    with_desc = build_helper('ORDER0001').tap { |h| h.item_desc '另一個商品' }.tap(&:encrypted_data).fields['CheckValue']

    assert_equal base, with_desc
  end

  def test_per_helper_hash_key_and_iv_override_global_config
    helper = build_helper('ORDER0001')
    helper.hash_key 'x' * 32
    helper.hash_iv 'y' * 16

    assert_equal 'x' * 32, helper.merchant_hash_key
    assert_equal 'y' * 16, helper.merchant_hash_iv
    helper.encrypted_data
    refute_equal ORDER0001_CHECK_VALUE, helper.fields['CheckValue']
  end

  def test_merchant_hash_key_and_iv_default_to_global_config
    helper = Spgateway::Helper.new('ORD1', 'M123')

    assert_equal HASH_KEY, helper.merchant_hash_key
    assert_equal HASH_IV, helper.merchant_hash_iv
  end
end
