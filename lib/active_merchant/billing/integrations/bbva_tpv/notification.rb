require 'nokogiri'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module BbvaTpv
        class Notification < ActiveMerchant::Billing::Integrations::Notification

          def complete?
            status == 'Completed'
          end 

          def transaction_id
            params['idtransaccion']
          end

          # When was this payment received by the client. 
          def received_at
            Time.parse(params['fechahora'])
          end

          # the money amount we received in X.2 decimal.
          def gross
            params['importe'].sub(/,/, '.')
          end

          # Was this a test transaction?
          def test?
            false
          end

          # Status result provided as one of:
          #   'Completed' or 'Failed'
          def status
            params['estado'] == '2' ? 'Completed' : 'Failed'
          end

          # If the status is failed, provide a reasonable error message
          def error_message
            if status == 'Completed'
              '0000 - Operación Aceptada'
            else
              params['coderror'] + ' - ' + params['descerror']
            end
          end

          # Acknowledge the transaction to BbvaTpv. This method has to be called after a new 
          # apc arrives. BbvaTpv will verify that all the information we received are correct and will return a 
          # ok or a fail. 
          #
          # This currently uses the signature provided to confirm the information is valid, rather than sending
          # a request to the server.
          # 
          # Example:
          # 
          #   def ipn
          #     notify = BbvaTpvNotification.new(request.raw_post)
          #
          #     if notify.acknowledge 
          #       ... process order ... if notify.complete?
          #     else
          #       ... log possible hacking attempt ...
          #     end
          def acknowledge
            str = 
              params['idterminal'] +
              params['idcomercio'] +
              params['idtransaccion'] +
              gross_cents.to_s +
              params['moneda'] +
              params['estado'] +
              params['coderror'] +
              params['codautorizacion'] +
              BbvaTpv::Helper.secret_word

            sig = Digest::SHA1.hexdigest(str)

            sig == params['firma']
          end

            #### NOTE I'm leaving this here for the moment, as it may be useful in the future,
            #### although I am inclined to have the BBVA API calls done seperatly.
         
          
          private

          # Take the posted data and move the relevant data into a hash
          # Will only take notice of the XML data
          def parse(post)
            @raw = post
            data = nil
            if post =~ /(<tpv>.*)$/
              data = Nokogiri::XML(value)
              data.search('//tpv/respago/*').each do |item|
                params[item.name] = item.content
              end
            end
          end
        end
      end
    end
  end
end
