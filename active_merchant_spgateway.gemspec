# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_merchant_spgateway/version'

Gem::Specification.new do |spec|
  spec.name          = "active_merchant_spgateway"
  spec.version       = ActiveMerchantSpgateway::VERSION
  spec.authors       = ["Gary"]
  spec.email         = ["me@adz.cool"]

  spec.summary       = %q{spgateway (智付通) gem}
  spec.description   = %q{This gem integrate Rails with spgateway (智付通).}
  spec.homepage      = "https://github.com/imgarylai/active_merchant_spgateway"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'activemerchant', '~> 1.50'
  spec.add_dependency 'offsite_payments', '~> 2'

  spec.add_development_dependency 'bundler', '~> 1.10'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rails', '>= 3.2.6', '< 5'

end
