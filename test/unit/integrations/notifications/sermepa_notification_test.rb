require File.dirname(__FILE__) + '/../../../test_helper'

class SermepaNotificationTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    Sermepa::Helper.credentials = {
        :terminal_id => '1',
        :commercial_id => '201920191',
        :secret_key => 'h2u282kMks01923kmqpo'
    }
    @sermepa = Sermepa::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @sermepa.complete?
    assert_equal "Completed", @sermepa.status
    assert_equal "000000000004", @sermepa.transaction_id
    assert_equal "114.00", @sermepa.gross
    assert_equal "EUR", @sermepa.currency
    assert_equal Time.parse("2009-04-02 12:45:41"), @sermepa.received_at
  end

  def test_compositions
    assert_equal Money.new(11400, 'EUR'), @sermepa.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement    
    # assert @sermepa.acknowledge
  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @sermepa.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    {
      
    } 
  end  
end
