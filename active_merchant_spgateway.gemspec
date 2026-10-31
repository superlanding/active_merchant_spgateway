# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_merchant_spgateway/version'

Gem::Specification.new do |spec|
  spec.name          = "active_merchant_spgateway"
  spec.version       = ActiveMerchantSpgateway::VERSION
  spec.authors       = ["Eddie Li"]
  spec.email         = ["eddie@super-landing.com"]

  spec.summary       = %q{ActiveMerchant x spgateway (智付通)}
  spec.description   = %q{This gem integrate Rails with spgateway (智付通).}
  spec.homepage      = "https://github.com/superlanding/active_merchant_spgateway"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.0"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activemerchant', '~> 1.50'
  spec.add_dependency 'money'
  spec.add_dependency 'offsite_payments', '>= 2', '< 4'

  spec.add_dependency 'actionview', '>= 7.0', '< 8.2'
  spec.add_dependency 'activesupport', '>= 7.0', '< 8.2'

  spec.add_development_dependency 'bundler', '>= 2.0'
  spec.add_development_dependency 'rake', '>= 13'
  spec.add_development_dependency 'minitest', '~> 5.0'

end
