require 'test_helper'

class SpgatewayModuleTest < Minitest::Test
  include OffsitePayments::Integrations

  def test_notification_method
    assert_instance_of Spgateway::Notification, Spgateway.notification('name=cody')
  end
end
