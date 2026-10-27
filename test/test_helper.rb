if ENV['COVERAGE']
  require 'simplecov'
  SimpleCov.start { add_filter '/test/' }
end

require 'active_merchant_spgateway'
require 'minitest/autorun'
require 'minitest/reporters'

begin
  require 'rubygems'
  require 'bundler'
  require 'json'
  Bundler.setup
rescue LoadError => e
  puts "Error loading bundler (#{e.message}): \"gem install bundler\" for bundler support."
end

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
ActiveMerchant::Billing::Base.mode = :test

# 測試一律不得連外部網路：任何 TCP 連線都直接 raise。
require 'net/http'
module NoNetworkInTests
  def connect
    raise "network access is disabled in tests (#{address}:#{port})"
  end
end
Net::HTTP.prepend(NoNetworkInTests)

# 全域設定（mattr_accessor / ActiveMerchant mode）在每個測試後還原，避免測試互相影響。
module SpgatewayGlobalState
  ACCESSORS = %i[hash_key hash_iv debug] + OffsitePayments::Integrations::Spgateway::CONFIG.map { |f| f.underscore.to_sym }

  def before_setup
    super
    @saved_mode = ActiveMerchant::Billing::Base.mode
    @saved_spgateway = ACCESSORS.to_h { |a| [a, OffsitePayments::Integrations::Spgateway.send(a)] }
  end

  def after_teardown
    ActiveMerchant::Billing::Base.mode = @saved_mode
    @saved_spgateway.each { |a, v| OffsitePayments::Integrations::Spgateway.send("#{a}=", v) }
    super
  end
end
Minitest::Test.prepend(SpgatewayGlobalState)
