require File.dirname(__FILE__) + '/bbva_tpv/helper.rb'
require File.dirname(__FILE__) + '/bbva_tpv/notification.rb'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      # See the BbvaTpv::Helper class for more generic information on usage of
      # this integrated payment method.
      module BbvaTpv 
       
        def self.service_url 
          'https://w3.grupobbva.com/TLPV/tlpv/TLPV_pub_RecepOpModeloServidor'
        end

        def self.notification_confirmation_url
          'https://w3.grupobbva.com/TLPV/tlpv/TLPV_pub_rpcrouter'
        end

        def self.notification(post)
          Notification.new(post)
        end

        def self.currency_code( name )
          row = supported_currencies.assoc(name)
          row.nil? ? supported_currencies.first[1] : row[1]
        end

        def self.currency_from_code( code )
          row = supported_currencies.rassoc(code)
          row.nil? ? supported_currencies.first[0] : row[0]
        end

        def self.supported_currencies
          [ ['EUR', '978'] ]
        end

      end
    end
  end
end
