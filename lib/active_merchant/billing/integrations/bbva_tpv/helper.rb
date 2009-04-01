require 'net/http'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module BbvaTpv
        # BBVA TPV Gateway
        #
        # Support for the Spanish bank BBVA, and their virtual point of sale system.
        # The BBVA TPV gateway requests the user's credit card details separetly,
        # as such authorize and capture are not supported, and only purchase can be used.
        #
        # The service does not provide a testing mode, as such all testing must be 
        # performed in the service's "Integración" mode (set using the provider's web interface.)
        #
        # This helper requires the credentials to be set before transactions can be peformed.
        # The credentials :transaction_id (idterminal), and
        # :comercial_id (idcomercio) are provided in the BBVA TPV support pages. The :secret_key
        # and :secret_key_data are specials that need to be generated inside the BBVA site
        # under the "Descargar Palabra Secreta" section. Basically, the secret key is a value
        # you generate and the key data is the contents of the file that BBVA return.
        # 
        # The credentials are used to create and the security signature and should be kept secure.
        #
        class Helper < ActiveMerchant::Billing::Integrations::Helper
          class << self
            # Credentials should be set as a hash containing the fields:
            #  :terminal_id, :comercial_id, :secret_key, :secret_key_data
            attr_accessor :credentials

            def secret_word
              xor_key = self.credentials[:secret_key] + self.credentials[:comercial_id][0,9] + '***'
              result = ""
              self.credentials[:secret_key_data].split(';').each_with_index do |part,i|
                bin = xor_key[i]
                bin = bin.ord if bin.respond_to?(:ord) # For ruby 1.9!
                xor = part.hex ^ bin
                result += xor.chr
              end
              result
            end

          end

          mapping :account, :account

          mapping :currency, :moneda
          mapping :amount, :importe
       
          # The order number must be numeric!
          mapping :order, 'idtransaccion'

          mapping :notify_url, 'urlcomercio'
          mapping :return_url, 'urlredir'
          mapping :description, 'localizador'

          mapping :billing_address, :country  => 'pais'

          # ammount should always be provided in cents!
          def initialize(order, account, options = {})
            super(order, account, options)
            add_field(:language, 'ES')
          end

          def form_fields
            { :peticion => build_xml_sale_request }
          end


          # Convert the currency to the correct ISO Money Code.
          # Only EUR currently supported!
          def currency=( value )
            code = case value
                   when 'EUR'
                     '978'
                   else
                     '978'
                   end
            add_field mappings[:currency], code 
          end

          def amount=(money)
            cents = money.respond_to?(:cents) ? money.cents : money
            if money.is_a?(String) or cents.to_i <= 0
              raise ArgumentError, 'money amount must be either a Money object or a positive integer in cents.'
            end
            add_field mappings[:amount], sprintf("%.2f", cents.to_f/100)
          end

          def order=(order_id)
            add_field mappings[:order], sprintf("%012d", order_id.to_i)
          end

          # Send a manual request for the notification object.
          # This is used to confirm a purchase if one was not sent by the gateway.
          def request_notification
            uri = URI.parse(BbvaTpv.notification_confirmation_url)
            uri.merge!("?peticion="+build_xml_confirmation_request)

            request = Net::HTTP::Get.new(uri.path)

            # request['Content-Length'] = "0"
            request['User-Agent'] = "Active Merchant -- http://home.leetsoft.com/am"
            request['Content-Type'] = "application/x-www-form-urlencoded" 

            http = Net::HTTP.new(uri.host, uri.port)
            http.verify_mode    = OpenSSL::SSL::VERIFY_NONE unless @ssl_strict
            http.use_ssl        = true

            response = http.request(request)
            # Should'nt fail unless something very wrong
            return nil unless response.is_a? Net::HTTPSuccess

            Notification.new( response.body )
          end


          protected

          def build_xml_sale_request
            xml = Builder::XmlMarkup.new :indent => 2
            creds = BbvaTpv::Helper.credentials
            xml.tpv do
              xml.oppago do
                xml.idterminal creds[:terminal_id]
                xml.idcomercio creds[:comercial_id]
                xml.idtransaccion @fields['idtransaccion']
                xml.moneda @fields['moneda'] # ISO Money Code
                xml.importe @fields['importe']
                xml.urlcomercio @fields['urlcomercio']
                # xml.idioma @fields[:idioma] || 'es'
                # xml.pais @fields[:pais] || 'ES' # Not needed
                xml.urlredir @fields['urlredir']
                xml.localizador @fields['localizador']
                xml.firma sign_request
              end
            end
            xml.target!
          end

          def build_xml_confirmation_request
            xml = Builder::XmlMarkup.new :indent => 2
            creds = BbvaTpv::Helper.credentials
            xml.tpv do
              xml.oppago do
                xml.idterminal creds[:terminal_id]
                xml.idcomercio creds[:comercial_id]
                xml.idtransaccion @fields['idtransaccion']
                xml.moneda @fields['moneda'] # ISO Money Code
                xml.importe @fields['importe']
                xml.firma sign_request
              end
            end
            xml.target!
          end

          def sign_request
            creds = BbvaTpv::Helper.credentials
            str = 
              creds[:terminal_id].to_s +
              creds[:comercial_id].to_s +
              @fields['idtransaccion'] +
              (@fields['importe'].to_f * 100).to_i.to_s + 
              @fields['moneda'] +
              (@fields['localizador'] || '') +
              BbvaTpv::Helper.secret_word
            Digest::SHA1.hexdigest( str )
          end

        end
      end
    end
  end
end
