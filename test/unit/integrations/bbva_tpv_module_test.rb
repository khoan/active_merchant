require File.dirname(__FILE__) + '/../../test_helper'

class BbvaTpvModuleTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations
  
  def test_notification_method
    assert_instance_of BbvaTpv::Notification, BbvaTpv.notification('name=cody')
  end
end 
