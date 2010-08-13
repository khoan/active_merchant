require 'nokogiri'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Sermepa
        class Notification < ActiveMerchant::Billing::Integrations::Notification
          include PostsData

          def complete?
            status == 'Compelted'
          end 

          def transaction_id
            params['ds_order']
          end

          # When was this payment received by the client. 
          def received_at
            Time.now # Not provided!
          end

          # the money amount we received in X.2 decimal.
          def gross
            params['ds_amount'].sub(/,/, '.').to_f
          end

          # Was this a test transaction?
          def test?
            false
          end

          def currency
            Sermepa.currency_from_code( params['ds_currency'] ) 
          end

          # Status of transaction. List of possible values:
          # <tt>Completed</tt>
          # <tt>Failed</tt>
          # <tt>Pending</tt>
          def status
            case error_code.to_i
            when 0..99
              'Completed'
            when 900
              'Pending'
            else
              'Failed'
            end
          end

          def error_code
            params['ds_response']
          end

          def error_message
            msg = Sermepa.response_code_message(error_code)
            error_code.to_s + ' - ' + (msg.nil? ? 'Operación Aceptada' : msg)
          end
          
          def secure_payment?
            params['ds_securepayment'] == '1'
          end

          def xml?
            !params['code'].nil?
          end

          # Acknowledge and confirm the transaction.
          #
          # If the transaction was standard 'authorization', calling this method will simply validate
          # the signature received to ensure it has not been falsified.
          #
          # TODO: If the original transaction type was 'deferred_authorization', calling acknowledge
          # will send a request to confirm the payment and finalize the purchase.
          #
          # Optionally, the secret key can be provided, useful when the global credentials
          # are not being used.
          #
          # Example:
          # 
          #   def notify
          #     notify = Sermepa::Notification.new(request.raw_post)
          #
          #     if notify.acknowledge
          #       ... process order ... if notify.complete?
          #     else
          #       ... log possible hacking attempt ...
          #     end
          #
          def acknowledge(secret_key = nil)
            str = 
              gross_cents.to_s +
              params['ds_order'] +
              params['ds_merchantcode'] + 
              params['ds_currency'] +
              params['ds_response']
            if xml?
              str += params['ds_transactiontype'] + params['ds_securepayment']
            end

            str += (secret_key || Sermepa::Helper.secret_key)
            sig = Digest::SHA1.hexdigest(str)
            sig.upcase == params['ds_signature'].upcase
          end

          private

          # Take the posted data and try to extract the parameters.
          #
          # Posted data can either be an XML string or CGI data in which case
          # a hash is expected.
          #
          def parse(post)
            @raw = post.to_s
            if @raw =~ /<retornoxml>/i
              # XML source
              self.params = xml_response_to_hash(@raw)
            else
              for line in @raw.split('&')    
                key, value = *line.scan( %r{^([A-Za-z0-9_.]+)\=(.*)$} ).flatten
                params[key.downcase] = CGI.unescape(value)
              end
            end
          end

          def xml_response_to_hash(xml)
            result = { }
            doc = Nokogiri::XML(xml)
            doc.css('retornoxml operacion').children().each do |child|
              result[child.name.downcase] = child.inner_text
            end
            result['code'] = doc.css('retornoxml codigo').inner_text
            result
          end
 
        end
      end
    end
  end
end
