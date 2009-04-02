require File.dirname(__FILE__) + '/../../../test_helper'

class BbvaTpvNotificationTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    BbvaTpv::Helper.credentials = {
        :terminal_id => '999999',
        :comercial_id => 'B8291502600001',
        :secret_key => 'eH2dJ9gk',
        :secret_key_data => '5D;7F;0A;27;09;0D;25;5D;04;01;0B;00;06;01;00;70;06;1C;19;19'
    }
    @bbva_tpv = BbvaTpv::Notification.new(http_raw_data)
  end

  def test_accessors
    assert @bbva_tpv.complete?
    assert_equal "Completed", @bbva_tpv.status
    assert_equal "000000000004", @bbva_tpv.transaction_id
    assert_equal "114.00", @bbva_tpv.gross
    assert_equal "EUR", @bbva_tpv.currency
    assert_equal Time.parse("2009-04-02 12:45:41"), @bbva_tpv.received_at
  end

  def test_compositions
    assert_equal Money.new(11400, 'EUR'), @bbva_tpv.amount
  end

  # Replace with real successful acknowledgement code
  def test_acknowledgement    
    assert @bbva_tpv.acknowledge
  end

  def test_send_acknowledgement
  end

  def test_respond_to_acknowledge
    assert @bbva_tpv.respond_to?(:acknowledge)
  end

  private
  def http_raw_data
    {
      :id => "4", 
      :peticion => "<tpv><respago><idterminal>999999</idterminal><idcomercio>B8291502600001</idcomercio><nombrecomercio>TEST COMPANY EXAMPLE S.L.</nombrecomercio><idtransaccion>000000000004</idtransaccion><moneda>978</moneda><importe>114.00</importe><fechahora>02-04-2009 12:45:41</fechahora><estado>2</estado><coderror>0000</coderror><codautorizacion>000065</codautorizacion><firma>A67C4051643D3A5ADF1396A324541BB1A19E4884</firma></respago></tpv>"
    } 
  end  
end
