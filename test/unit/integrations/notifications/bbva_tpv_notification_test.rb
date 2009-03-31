require File.dirname(__FILE__) + '/../../../test_helper'

class BbvaTpvNotificationTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    @bbva_tpv = BbvaTpv::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @bbva_tpv.complete?
    assert_equal "", @bbva_tpv.status
    assert_equal "", @bbva_tpv.transaction_id
    assert_equal "", @bbva_tpv.item_id
    assert_equal "", @bbva_tpv.gross
    assert_equal "", @bbva_tpv.currency
    assert_equal "", @bbva_tpv.received_at
    assert @bbva_tpv.test?
  end

  def test_compositions
    assert_equal Money.new(3166, 'USD'), @bbva_tpv.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement    

  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @bbva_tpv.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    ""
  end  
end
