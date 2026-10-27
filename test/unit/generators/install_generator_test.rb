require 'test_helper'
require 'tmpdir'
require 'rails/generators'
require 'rails/generators/test_case'
require 'generators/spgateway/install_generator'

class SpgatewayInstallGeneratorTest < Rails::Generators::TestCase
  tests Spgateway::Generators::InstallGenerator
  destination File.expand_path('../../tmp/generator', __dir__)

  def setup
    super
    prepare_destination
  end

  def test_generates_initializer_with_blank_credentials
    run_generator

    assert_file 'config/initializers/spgateway.rb' do |content|
      assert_match(/OffsitePayments::Integrations::Spgateway\.setup do \|spgateway\|/, content)
      assert_match(/spgateway\.merchant_id = ''/, content)
      assert_match(/spgateway\.hash_key    = ''/, content)
      assert_match(/spgateway\.hash_iv     = ''/, content)
    end
  end

  def test_shows_readme_on_invoke
    output = run_generator

    assert_match(/config\/initializers\/spgateway\.rb/, output)
  end

  def test_generated_initializer_is_valid_ruby_and_configures_the_module
    run_generator
    path = File.join(destination_root, 'config/initializers/spgateway.rb')
    saved = %i[hash_key hash_iv].map { |a| OffsitePayments::Integrations::Spgateway.send(a) }

    load path

    assert_equal '', OffsitePayments::Integrations::Spgateway.hash_key
    assert_equal '', OffsitePayments::Integrations::Spgateway.hash_iv
  ensure
    OffsitePayments::Integrations::Spgateway.hash_key, OffsitePayments::Integrations::Spgateway.hash_iv = saved
  end
end
