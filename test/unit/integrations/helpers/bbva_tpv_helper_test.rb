require File.dirname(__FILE__) + '/../../../test_helper'

class BbvaTpvHelperTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations
  
  def setup
    BbvaTpv::Helper.credentials = {
        :terminal_id => '999999',
        :comercial_id => 'B8291502600001',
        :secret_key => 'eH2dJ9gk',
        :secret_key_data => '5D;7F;0A;27;09;0D;25;5D;04;01;0B;00;06;01;00;70;06;1C;19;19'
    }
    @helper = BbvaTpv::Helper.new(1, 'cody@example.com', :amount => 100, :currency => 'EUR')
    @helper.description = "Store Purchase"
  end
 
  def test_basic_helper_fields
    assert_field 'account', 'cody@example.com'
    assert_field 'importe', '1.00'
    assert_field 'idtransaccion', '000000000001'
    assert_field 'localizador', 'Store Purchase'
    assert_field 'moneda', '978'
  end
  
  def test_address_mapping
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => '',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7EE',
                            :country  => 'ES'
   
    assert_field 'pais', 'ES'
  end
  
  def test_unknown_address_mapping
    @helper.billing_address :farm => 'CA'
    assert_equal 6, @helper.fields.size
  end

  def test_unknown_mapping
    assert_nothing_raised do
      @helper.company_address :address => '500 Dwemthy Fox Road'
    end
  end
  
  def test_setting_invalid_address_field
    fields = @helper.fields.dup
    @helper.billing_address :street => 'My Street'
    assert_equal fields, @helper.fields
  end

  def test_padding_on_order_id
    @helper.order = 101
    assert_field 'idtransaccion', "000000000101"
  end

  def test_desobfustication_of_secret_key
    assert key = BbvaTpv::Helper.desobfusticate_secret_key
    assert_equal "878CC4B6F999740B0633", key   # Key tested with BBVA code!
  end

  def test_request_signing
    assert sig = @helper.send(:sign_request)
    assert_equal "1af08eed948c16d5150ad2d8937323a5218a523e", sig

  end

end
