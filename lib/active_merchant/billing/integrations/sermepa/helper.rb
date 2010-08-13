module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Sermepa
        # Sermepa/Servired Spanish Virtual POS Gateway
        #
        # Support for the Spanish payment gateway provided by Sermepa, part of Servired,
        # one of the main providers in Spain to Banks and Cajas.
        #
        # Requires the :terminal_id, :commercial_id, and :secret_key to be set in the credentials
        # before the helper can be used. Credentials may be overwriten when instantiating the helper
        # if required or instead of the global variable.
        # 
        class Helper < ActiveMerchant::Billing::Integrations::Helper
          include PostsData

          class << self
            # Credentials should be set as a hash containing the fields:
            #  :terminal_id, :commercial_id, :secret_key
            attr_accessor :credentials
          end

          mapping :account,     'Ds_Merchant_MerchantCode'

          mapping :currency,    'Ds_Merchant_Currency'
          mapping :amount,      'Ds_Merchant_Amount'
       
          mapping :order,       'Ds_Merchant_Order'
          mapping :description, 'Ds_Merchant_Product_Description'
          mapping :client,      'Ds_Merchant_Titular'

          mapping :notify_url,  'Ds_Merchant_MerchantURL'
          mapping :success_url, 'Ds_Merchant_UrlOK'
          mapping :failure_url, 'Ds_Merchant_UrlKO'

          mapping :language,    'Ds_Merchant_ConsumerLanguage'

          mapping :transaction, 'Ds_Merchant_TransactionType'

          #### Special Request Specific Fields ####
          mapping :signature,   'Ds_Merchant_MerchantSignature'
          mapping :terminal,    'Ds_Merchant_Terminal'
          ########

          # ammount should always be provided in cents!
          def initialize(order, account, options = {})
            self.credentials = options.delete(:credentials) if options[:credentials]

            # Replace account with commercial_id
            super(order, credentials[:commercial_id], options)

            add_field mappings[:transaction], '0' # Default Transaction Type
            add_field mappings[:terminal], credentials[:terminal_id]
          end

          # Allow credentials to be overwritten if needed
          def credentials
            @credentials || self.class.credentials
          end
          def credentials=(creds)
            @credentials = (self.class.credentials || {}).dup.merge(creds)
          end

          def amount=(money)
            cents = money.respond_to?(:cents) ? money.cents : money
            if money.is_a?(String) || cents.to_i <= 0
              raise ArgumentError, 'money amount must be either a Money object or a positive integer in cents.'
            end
            add_field mappings[:amount], cents
          end

          def order=(order_id)
            order_id = order_id.to_s
            if order_id !~ /^[0-9]{4}/ && order_id.length <= 8
              order_id = ('0' * 4) + order_id
            end
            regexp = /^[0-9]{4}[0-9a-zA-Z]{0,8}$/
            raise "Invalid order number format! First 4 digits must be numbers" if order_id !~ regexp
            add_field mappings[:order], order_id
          end

          def currency=( value )
            add_field mappings[:currency], Sermepa.currency_code(value) 
          end

          def language=(lang)
            add_field mappings[:language], Sermepa.language_code(lang)
          end

          def transaction=(type)
            add_field mappings[:transaction], (Sermepa.supported_transactions.assoc(type) || [])[1]
          end

          def form_fields
            add_field mappings[:signature], sign_request
            @fields
          end


          # Send a manual request for the notification object.
          # This is used to confirm a purchase if one was not sent by the gateway.
          # Returns the raw data ready to be sent to a new Notification instance.
          def request_notification
            body = build_xml_confirmation_request

            headers = { }
            headers['Content-Length'] = body.size.to_s
            headers['User-Agent'] = "Active Merchant -- http://activemerchant.org"
            headers['Content-Type'] = 'application/x-www-form-urlencoded'
  
            # Return the raw response data
            ssl_post(Sermepa.operations_url, body, headers)
          end

          protected

          def build_xml_confirmation_request
            self.transaction = :confirmation
            xml = Builder::XmlMarkup.new :indent => 2
            xml.datosentrada do
              xml.ds_version 0.1
              xml.ds_merchant_currency @fields['Ds_Merchant_Currency']
              xml.ds_merchant_merchanturl @fields['Ds_Merchant_MerchantURL']
              xml.ds_merchant_transactiontype @fields['Ds_Merchant_TransactionType']
              xml.ds_merchant_merchantdata @fields['Ds_Merchant_Product_Description']
              xml.ds_merchant_terminal credentials[:terminal_id]
              xml.ds_merchant_merchantcode credentials[:commercial_id]
              xml.ds_merchant_order @fields['Ds_Merchant_Order']
              xml.ds_merchant_merchantsignature sign_request
            end
            xml.target!
          end


          # Generate a signature authenticating the current request.
          # Values included in the signature are determined by the the type of 
          # transaction.
          def sign_request(strength = :normal)
            str = (@fields['Ds_Merchant_Amount'].to_f * 100).to_i.to_s +
                  @fields['Ds_Merchant_Order'].to_s +
                  @fields['Ds_Merchant_MerchantCode'].to_s +
                  @fields['Ds_Merchant_Currency'].to_s

            case Sermepa.transaction_from_code(@fields['Ds_Merchant_TransactionType'])
            when :recurring_transaction
              str += @fields['Ds_Merchant_SumTotal']

            # Add transaction type for the following requests performed only using XML
            when :confirmation, :automatic_return, :successive_transaction,
                 :confirm_authentication, :cancel_preauthorization, :preauthorization,
                 :deferred_authorization, :confirm_deferred_authorization, :cancel_deferred_authorization,
                 :initial_recurring_authorization, :successive_recurring_authorization
              str += @fields['Ds_Merchant_TransactionType']
              strength = :normal # Force the strength!
            end

            if strength == :extended
              str += @fields['Ds_Merchant_TransactionType'].to_s +
                     @fields['Ds_Merchant_MerchantURL'].to_s
            end

            str += credentials[:secret_key]
              
            Digest::SHA1.hexdigest( str )
          end

        end
      end
    end
  end
end
