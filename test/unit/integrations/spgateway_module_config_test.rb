# encoding: utf-8
require 'test_helper'

class SpgatewayModuleConfigTest < Minitest::Test
  include OffsitePayments::Integrations

  def test_service_url_in_production_mode
    ActiveMerchant::Billing::Base.mode = :production

    assert_equal 'https://core.newebpay.com/MPG/mpg_gateway', Spgateway.service_url
  end

  def test_service_url_in_development_and_test_mode_uses_the_sandbox
    %i[development test].each do |mode|
      ActiveMerchant::Billing::Base.mode = mode

      assert_equal 'https://ccore.newebpay.com/MPG/mpg_gateway', Spgateway.service_url
    end
  end

  def test_service_url_raises_for_invalid_mode
    ActiveMerchant::Billing::Base.mode = :staging

    error = assert_raises(StandardError) { Spgateway.service_url }
    assert_match(/invalid/, error.message)
  end

  def test_setup_yields_the_module_and_stores_credentials
    Spgateway.setup do |config|
      assert_same Spgateway, config
      config.hash_key = 'fake-key'
      config.hash_iv  = 'fake-iv'
    end

    assert_equal 'fake-key', Spgateway.hash_key
    assert_equal 'fake-iv', Spgateway.hash_iv
  end

  def test_config_accessors_exist_for_every_config_field
    Spgateway::CONFIG.each do |field|
      name = field.underscore
      assert_respond_to Spgateway, name
      assert_respond_to Spgateway, "#{name}="
    end
  end

  def test_notification_builds_from_a_raw_post_body
    notification = Spgateway.notification('Status=SUCCESS&Amt=30&MerchantOrderNo=ORDER0001')

    assert_instance_of Spgateway::Notification, notification
    assert_equal 'SUCCESS', notification.status
    assert_equal 'ORDER0001', notification.merchant_order_no
  end

  def test_constants
    assert_equal '1.2', Spgateway::VERSION
    assert_equal 'String', Spgateway::RESPOND_TYPE
    assert_equal %w(Amt MerchantID MerchantOrderNo TimeStamp Version), Spgateway::CHECK_VALUE_FIELDS
    assert_equal %w(Amt MerchantID MerchantOrderNo TradeNo), Spgateway::CHECK_CODE_FIELDS
  end

  def test_gem_version_is_defined
    assert_match(/\A\d+\.\d+\.\d+/, ActiveMerchantSpgateway::VERSION)
  end
end
