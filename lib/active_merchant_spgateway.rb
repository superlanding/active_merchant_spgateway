require 'action_view'
require 'active_merchant_spgateway/version'
require 'active_merchant'
require 'money'
require 'offsite_payments'
require 'active_support/core_ext/string'
require 'uri'

module OffsitePayments
  module Integrations
    autoload :Spgateway, 'offsite_payments/integrations/spgateway'
  end
end

ActionView::Base.send(:include, OffsitePayments::ActionViewHelper)
