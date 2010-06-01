module VirtualBox
  # Represents a network interface on the host. There are generally
  # two types of network interfaces wihch exist on the host: bridged
  # and host-only. This class represents both.
  class HostNetworkInterface < AbstractModel
    attribute :parent, :readonly => true, :property => false
    attribute :parent_collection, :readonly => true, :property => false
    attribute :interface, :readonly => true, :property => false
    attribute :name, :readonly => true
    attribute :uuid, :readonly => true, :property => :id
    attribute :network_name, :readonly => true
    attribute :dhcp_enabled, :readonly => true
    attribute :ip_address, :readonly => true
    attribute :network_mask, :readonly => true
    attribute :ip_v6_supported, :readonly => true
    attribute :ip_v6_address, :readonly => true
    attribute :ip_v6_network_mask_prefix_length, :readonly => true
    attribute :hardware_address, :readonly => true
    attribute :medium_type, :readonly => true
    attribute :status, :readonly => true
    attribute :interface_type, :readonly => true

    class << self
      # Populates a relationship with another model.
      #
      # **This method typically won't be used except internally.**
      #
      # @return [Array<HostNetworkInterface>]
      def populate_relationship(caller, ihost)
        relation = Proxies::Collection.new(caller, self, ihost)

        ihost.network_interfaces.each do |inet|
          relation << new(inet)
        end

        relation
      end

      # Creates a host only network interface. This method should not
      # be called directly. Instead, the `create` method on the
      # `Global#host` relationship should be called instead. Example:
      #
      #     VirtualBox::Global.global.host.network_interfaces.create
      #
      # The above will create a host only network interface, add it to
      # the collection, and will return the instance of the new
      # interface.
      def create(proxy, interface)
        inet, progress = interface.create_host_only_network_interface
        progress.wait

        new(inet)
      end
    end

    def initialize(inet)
      initialize_attributes(inet)
    end

    def initialize_attributes(inet)
      write_attribute(:interface, inet)

      load_interface_attributes(inet)
      existing_record!
    end

    def added_to_relationship(proxy)
      write_attribute(:parent, proxy.parent)
      write_attribute(:parent_collection, proxy)
    end

    # Sets up the static IPV4 configuration for the host only network
    # interface. This allows the caller to set the IPV4 address of the
    # interface as well as the netmask.
    def enable_static(ip, netmask=nil)
      netmask ||= network_mask

      interface.enable_static_ip_config(ip, netmask)
      reload
    end

    # Reloads the information regarding this host only network
    # interface.
    def reload
      # Find the interface again and reload the data
      inet = parent.interface.find_host_network_interface_by_id(uuid)
      initialize_attributes(inet)
      self
    end

    # Destroy the host only network interface. Warning: If any VMs are
    # currently attached to this network interface, their networks
    # will fail to work after removing this. Therefore, one should be
    # careful to make sure to remove all VMs from this network prior
    # to destroying it.
    def destroy
      parent.interface.remove_host_only_network_interface(uuid).wait

      # Remove from collection
      parent_collection.delete(self, true) if parent_collection

      true
    end
  end
end