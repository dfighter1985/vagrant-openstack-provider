module VagrantPlugins
  module Openstack
    class Utils
      def initialize
        @logger = Log4r::Logger.new('vagrant_openstack::action::config_resolver')
      end

      def get_ip_address(env)
        addresses = env[:openstack_client].nova.get_server_details(env, env[:machine].id)['addresses']
        addresses.each do |_, network|
          network.each do |network_detail|
            return network_detail['addr'] if network_detail['OS-EXT-IPS:type'] == 'floating'
          end
        end
        fail Errors::UnableToResolveIP if addresses.size == 0
        if addresses.size == 1 || !env[:machine].provider_config.networks
          net_addresses = addresses.first[1]
        else
          first_network = env[:machine].provider_config.networks[0]
          if first_network.is_a? String
            net_addresses = addresses[first_network]
          else
            net_addresses = addresses[first_network[:name]]
          end
        end
        fail Errors::UnableToResolveIP if net_addresses.size == 0
        
        config = env[:machine].provider_config
        host = nil
        
        if not config.ssh_ip_version.nil?
          net_addresses.each do |address|
            if address['version'] == config.ssh_ip_version
              host = address['addr']
              break
            end
          end
        end
        
        if host.nil?
          host = net_addresses[0]['addr']
        end
        
        host
      end
    end
  end
end
