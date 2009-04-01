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

        def notification_confirmation_url
          'https://w3.grupobbva.com/TLPV/tlpv/TLPV_pub_rpcrouter'
        end

        def self.notification(post)
          Notification.new(post)
        end

      end
    end
  end
end
