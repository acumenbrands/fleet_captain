require 'fleet'
require 'forwardable'
require 'net/ssh'
require 'thread'
require 'addressable/uri'
require 'monitor'
require 'timeout'
require 'sshkit'
require 'sshkit/dsl'
require 'active_support/configurable'

require_relative 'fleet_client/connection_control'

SSHKit::Backend::Netssh.configure do |ssh|
  ssh.connection_timeout = 30
  ssh.ssh_options = {
    user: 'core',
    keys: %w(/Users/prater/.ssh/bork-knife-ec2.pem),
    forward_agent: false,
    auth_methods: %w(publickey password)
  }
end

module FleetCaptain
  class FleetClient
    class ConnectionError < StandardError; end
    class ServiceNotRegistered < StandardError; end
    class FleetOperationError < StandardError; end
    class FleetErrorStatus < StandardError; end

    include SSHKit::DSL
    include ActiveSupport::Configurable

    config_accessor :fleet_timeout do
      10
    end

    attr_reader :client, :queue, :cluster, :host, :connection

    def initialize(cluster, fleet_endpoint: "http://localhost:10001",
                            key_file: '~/.ssh/id_rsa')
      @cluster    = cluster
      @client     = Fleet.new(fleet_api_url: fleet_endpoint, adapter: :excon)
      @key_file   = key_file
      @connection = ConnectionControl.new
    end

    # Parse out the name of the lead instance for direct connections.
    #
    def actual
      return @actual if @actual
      connect(instance_ips.values.first)
      @actual = instance_ips[lead_machine_ip]
    end

    def connect_to_actual
      unless connected_to_actual?
        disconnect_ssh_tunnel!
        connect(actual)
      end
    end

    def connected_to_actual?
      @host == actual
    end

    def instance_ips
      @instances ||= FleetCaptain.cloud_client.new(cluster).ip_addresses
    end

    def connect(host = @actual)
      begin
        establish_ssh_tunnel!(host)
        loop until connection.ready?
      rescue Exception => e
        # Yes I really want a rescue Exception here as Queue raises a Fatal
        # if there are no other threads.
        raise ConnectionError, "SSH Connection Error to Fleet actual (because #{e})"
      end

      @connected = true
      self
    end

    def connected?
      @connected
    end

    def destroy(service)
      connect unless connected?
      @client.destroy(service.service_name)
    end

    def disconnect_ssh_tunnel!
      if @tunnel
        connection.stop!
        loop until connection.clean?
        connection.reset
      end
      @connected = false
    end

    def establish_ssh_tunnel!(host = @actual)
      @host   = host
      Thread.abort_on_exception = true
      @tunnel = Thread.new do
        session = Net::SSH.start(host, 'core', keys: @key_file)
        session.forward.local(10001, "localhost", 4001)
        session.forward.local(10002, "localhost", 7001)
        connection.ready!
        session.loop { break if connection.stop?; true }
        session.forward.cancel_local(10001)
        session.forward.cancel_local(10002)
        connection.clean!
      end
    end

    def exists?(service)
      connect unless connected?
      loaded?(service) || list.include?(service)
    end

    # Get the machine list from the etcd cluster
    #
    def lead_machine_ip
      return @lead_machine if @lead_machine
      res           = Faraday.new(url: 'http://localhost:10002').get('/v2/admin/machines')
      machines      = JSON.parse(res.body)
      machine_spec  = machines.find { |machine| machine.fetch('state', nil) == 'leader' }
      @lead_machine = Addressable::URI.parse(machine_spec['clientURL']).host
    end

    def list
      connect unless connected?
      response = @client.list_units
      Set.new(response['node'].fetch('nodes', []).map { |unit|
        service_from_unit(unit)
      })
    end

    def loaded?(service)
      check_status(service, load_state: 'loaded')
    end

    def running?(service)
      check_status(service, active_state: 'active', sub_state: 'running')
    end

    # The node key has a nodes key, which has a list of machines.
    #
    # Every machine has a nodes key, which is a list of units.
    #
    # Every unit has a value key, which is what we want.
    #
    # Because of course it does.
    #
    # It's a long story.
    #
    def machines
      connect unless connected?
      @client.list_machines['node']['nodes'].map { |machine|
        machine['nodes'].map { |machine_node|
          JSON.parse(machine_node['value'])
        }
      }.flatten
    end

    # From orbit.
    #
    # This actually nukes things.  Be so careful.
    #
    def nuke!
      connect unless connected?

      begin
        list.each do |service|
          service_name = service.service_name
          @client.stop(service_name)
          @client.unload(service_name)
          @client.destroy(service_name)
          @client.delete_unit(service.unit_hash)
        end
      rescue Fleet::NotFound
        # i mean, you can nuke the wasteland all you want.
      end

      res = Faraday.new(url: 'http://localhost:10001')
      res.delete('/v2/keys/_coreos.com/fleet/job', recursive: true)
      res.delete('/v2/keys/_coreos.com/fleet/unit', recursive: true)


      on instance_ips.values do
        execute "for i in $(docker ps -aq); do echo $i; done;"
      end

      true
    end

    # In this case the client is not an asynchronous response and so
    # nil is not returned.  However, in keeping with the existing
    # interface we've provided, this method masks the response and
    # returns true.
    #
    def start(service)
      connect unless connected?
      @client.start(service.service_name)
      true
    end

    def start!(service)
      start(service)
      sync_operation { running?(service) }
    end

    # As does this method.
    #
    def stop(service)
      connect unless connected?
      @client.stop(service.service_name)
      true
    end

    # The client will return nil because the last statement is an if
    # statment to see if it should wait for it to become loaded
    # as we don't want to wait on it, we'll uncondtionally return true
    # and hope that update_job_target_spec would raise an error
    # if something went wrong.
    #
    def submit(service)
      connect_to_actual unless connected_to_actual?
      @client.load(service.service_name, service.to_service_def)
      true
    end

    def submit!(service)
      submit(service)
      sync_operation { loaded?(service) }
    end

    def journal(service)
      status_response = @client.status(service.service_name)
      require 'pry'; binding.pry
      on actual do
        capture("fleetctl journal #{service.name}")
      end
    end

    # This method also returns true instead of a (probably more useful)
    # response body.
    #
    # What do we do here with these responses?
    #
    def unload(service)
      connect unless connected?
      @client.unload(service.service_name)
      true
    end

    private

    def sync_operation
      begin
        Timeout.timeout(config.fleet_timeout) do
          loop until yield
        end
      rescue Timeout::Error
        raise FleetOperationError, "Operation did not complete in #{config.fleet_timeout} seconds"
      end
    end

    def check_status(service, **state)
      connect unless connected?

      begin
        status_response = @client.status(service.service_name)
        puts status_response
      rescue Fleet::NotFound
        return false
      end


      state.each_pair do |key, value|
        if status_response[key] == 'failed'
          raise FleetErrorStatus, journal(service)
        elsif status_response[key] != value
          return false
        end
      end

      true
    end

    def service_from_unit(unit)
      unit_text = unit['value']

      begin
        unit_text = JSON.parse(unit_text)['Raw']
      rescue JSON::ParserError
        unit_text = JSON.parse("[#{unit_text}]").first
      end

      FleetCaptain::Service.from_unit(text: unit_text)
    end

  end
end
