require File.dirname(__FILE__) + '/../../../test_helper'

class SermepaHelperTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations
  
  def setup
    Sermepa::Helper.credentials = {
        :terminal_id => '1',
        :commercial_id => '201920191',
        :secret_key => 'h2u282kMks01923kmqpo'
    }
    @helper = Sermepa::Helper.new(29292929, 'cody@example.com', :amount => 1235, :currency => 'EUR')
    @helper.description = "Store Purchase"
  end

  def test_credentials_accessible
    assert_instance_of Hash, @helper.credentials
  end

  def test_credentials_overwritable
    @helper = Sermepa::Helper.new(29292929, 'cody@example.com', :amount => 1235, :currency => 'EUR', 
                                 :credentials => {:terminal_id => 12})
    assert_field 'Ds_Merchant_Terminal', '12'
  end

  def test_basic_helper_fields
    assert_field 'Ds_Merchant_MerchantCode', '201920191'
    assert_field 'Ds_Merchant_Amount', '12.35'
    assert_field 'Ds_Merchant_Order', '29292929'
    assert_field 'Ds_Merchant_Product_Description', 'Store Purchase'
    assert_field 'Ds_Merchant_Currency', '978'
    assert_field 'Ds_Merchant_TransactionType', '0'
  end
  
  def test_unknown_mapping
    assert_nothing_raised do
      @helper.company_address :address => '500 Dwemthy Fox Road'
    end
  end
  
  def test_padding_on_order_id
    @helper.order = 101
    assert_field 'Ds_Merchant_Order', "0000101"
  end

  def test_no_padding_on_valid_order_id
    @helper.order = 1010
    assert_field 'Ds_Merchant_Order', "1010"
  end

  def test_error_raised_on_invalid_order_id
    assert_raise RuntimeError do
      @helper.order = "A0000000ABC"
    end
  end

  def test_basic_signing_request
    assert sig = @helper.send(:sign_request)
    assert_equal "c8392b7874e2994c74fa8bea3e2dff38f3913c46", sig
  end

  def test_build_xml_confirmation_request
    # This also tests signing the request for differnet transactions
    assert_equal @helper.send(:build_xml_confirmation_request), <<EOF
<datosentrada>
  <ds_version>0.1</ds_version>
  <ds_merchant_currency>978</ds_merchant_currency>
  <ds_merchant_merchanturl></ds_merchant_merchanturl>
  <ds_merchant_transactiontype>2</ds_merchant_transactiontype>
  <ds_merchant_merchantdata>Store Purchase</ds_merchant_merchantdata>
  <ds_merchant_terminal>1</ds_merchant_terminal>
  <ds_merchant_merchantcode>201920191</ds_merchant_merchantcode>
  <ds_merchant_order>29292929</ds_merchant_order>
  <ds_merchant_merchantsignature>dec4048a3aefefd22798347ee1c1f19011fd47f6</ds_merchant_merchantsignature>
</datosentrada>
EOF
  end

end
