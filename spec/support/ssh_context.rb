shared_context 'ssh connection established' do
  let(:fleet_client) {
    FleetCaptain::FleetClient.new('Test-Stack', key_file: '~/.ssh/bork-knife-ec2.pem')
  }

  before do
    # pretend the SSH tunnel is setup
    #
    # NOTE:  If you rerecord the cassettes you will need to ACTUALLY
    # establish an SSH tunnel TO THE cluster leader
    #

    if subject.respond_to? :fleet_client=
      subject.fleet_client = fleet_client
    end

    allow(fleet_client).to receive(:connected_to_actual?).and_return(true)
    
    allow(fleet_client).to receive(:connect) do |host|
      fleet_client.instance_variable_set('@connected', true)
      fleet_client
    end
  end
end
