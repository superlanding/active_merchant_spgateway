# encoding: utf-8
require 'test_helper'
require 'nokogiri'

# 透過 payment_service_for（ActionView）產生導向智付通的表單，
# 驗證表單 action 與隱藏欄位（含 CheckValue），完全不連外部網路。
class SpgatewayViewHelperTest < Minitest::Test
  include OffsitePayments::Integrations

  def setup
    Spgateway.hash_key = 'K' * 32
    Spgateway.hash_iv  = 'I' * 16
    ActiveMerchant::Billing::Base.mode = :test
  end

  def render_form(&block)
    view = ActionView::Base.empty
    view.output_buffer ||= ActionView::OutputBuffer.new # Rails 7.0 的 empty view 沒有預設 buffer
    view.payment_service_for('ORD1', 'M123', service: :spgateway, amount: 200, html: { id: 'spgateway-form' }, &block)
    Nokogiri::HTML.fragment(view.output_buffer.to_s)
  end

  def hidden(doc, name)
    doc.at_css("input[name='#{name}']")&.[]('value')
  end

  def test_form_posts_to_sandbox_url_with_hidden_fields_and_check_value
    doc = render_form do |service|
      service.merchant_order_no 'ORDER0001'
      service.time_stamp Time.at(1403243286)
      service.item_desc '商品一'
      service.encrypted_data
    end

    form = doc.at_css('form#spgateway-form')
    assert_equal 'https://ccore.newebpay.com/MPG/mpg_gateway', form['action']
    assert_equal 'post', form['method']
    assert_equal 'M123', hidden(doc, 'MerchantID')
    assert_equal '200', hidden(doc, 'Amt')
    assert_equal 'ORDER0001', hidden(doc, 'MerchantOrderNo')
    assert_equal '商品一', hidden(doc, 'ItemDesc')
    assert_equal '1.2', hidden(doc, 'Version')
    assert_equal 'D6ABEC841A572C7892E433BC8842C2285285CB2B51C2AA08BAF86874109FB281', hidden(doc, 'CheckValue')
  end

  def test_form_posts_to_production_url_in_production_mode
    ActiveMerchant::Billing::Base.mode = :production
    doc = render_form { |service| service.merchant_order_no 'ORDER0001' }

    assert_equal 'https://core.newebpay.com/MPG/mpg_gateway', doc.at_css('form')['action']
  end

  def test_form_without_encrypted_data_has_no_check_value
    doc = render_form { |service| service.merchant_order_no 'ORDER0001' }

    assert_nil hidden(doc, 'CheckValue')
  end

  def test_missing_block_raises_argument_error
    view = ActionView::Base.empty

    assert_raises(ArgumentError) { view.payment_service_for('ORD1', 'M123', service: :spgateway) }
  end
end
