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

          def currency
            BbvaTpv.currency_from_code( params['moneda'] ) 
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
              params['coderror'].to_s + ' - ' + params['descerror'].to_s
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
          #     notify = BbvaTpvNotification.new(params)
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
              params['moneda'].to_s +
              params['estado'].to_s +
              params['coderror'].to_s +
              params['codautorizacion'].to_s +
              BbvaTpv::Helper.secret_word
            sig = Digest::SHA1.hexdigest(str)
            sig.upcase == params['firma'].upcase
          end

          private

          # Take the posted data and add the main fields into the notification parameter hash.
          #
          # This method, in contrast to other payment mechanisms, will accept a hash of CGI
          # parameters. If this is the case, the expected 'peticion' parameter will be used to extract
          # the information. Passing a raw query string WILL NOT work here!
          #
          # Raw data (String) will be parsed as XML. 
          #
          # Searches for the root 'tpv' tag and searches two levels deep for
          # all the entries.
          def parse(post)
            if post.is_a? Hash and ! post[:peticion].to_s.empty?
              post = post[:peticion]
            end
            @raw = post.to_s
            doc = Nokogiri::XML(@raw)
            doc.search("//tpv/*/*").each do |item|
              params[item.name] = item.content
            end
            # grab errors seperatly
            [doc.search("//tpv/coderror").first, doc.search("//tpv/deserror").first].compact.each do |item|
              params[item.name] = item.content
            end
          end
        end
      end
    end
  end
end
