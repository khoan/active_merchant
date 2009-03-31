require File.dirname(__FILE__) + '/bbva_tpv/helper.rb'
require File.dirname(__FILE__) + '/bbva_tpv/notification.rb'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      # See the BbvaTpv::Helper class for more generic information on usage of
      # this integrated payment method.
      module BbvaTpv 
       
        mattr_accessor :service_url
        self.service_url = 'https://w3.grupobbva.com/TLPV/tlpv/TLPV_pub_RecepOpModeloServidor'

        mattr_accessor :notification_confirmation_url
        self.notification_confirmation_url = 'https://w3.grupobbva.com/TLPV/tlpv/TLPV_pub_rpcrouter'

        def self.notification(post)
          Notification.new(post)
        end

      end
    end
  end
end
