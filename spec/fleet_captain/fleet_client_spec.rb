require 'spec_helper'

describe FleetCaptain::FleetClient do
  context 'requires connecttion' do
    include_context 'ssh connection established'
    include_context 'units'
    
    subject { fleet_client }

    let(:expected_unit) {
      FleetCaptain::Service.from_unit(<<-UNIT.strip_heredoc
      [Unit]
      Description=Hello World
      
      [Service]
      ExecStart=/bin/bash -c "while true; do echo \\\"Hello, world\\\"; sleep 1; done"
      UNIT
                                     )
    }

    after do |example|
      require 'pry'; binding.pry
      subject.nuke!
    end

    it 'connects to the fleet actual via ssh tunnel', :vcr do
      expect(fleet_client.list.first).to eq expected_unit
    end

    describe '#nuke', :vcr do
      before do
        subject.submit(truebox)
        subject.submit(falsebox)
      end

      it 'destroys everything completely' do
        expect { subject.nuke! }
        .to change { subject.list.count }
        .from(2)
        .to(0)
      end
    end

    it 'raises a connection error if the ssh tunnel cannot be established' do
      allow(fleet_client).to receive(:establish_ssh_tunnel!) do
        raise 'fatal'
      end

      expect { fleet_client.list }.to raise_error FleetCaptain::FleetClient::ConnectionError
    end

    describe '#list', :live do
      before do
        subject.submit(truebox)
        subject.submit(falsebox)
        subject.submit(runbox)
      end

      it 'retrieves a set of units on the cluster' do
        expect(fleet_client.list.size).to be 3
      end
    end

    describe 'connecting to the fleet', :vcr do
      before do
        subject.submit(truebox)
        subject.submit(falsebox)
        subject.submit(runbox)
      end

      it 'can retrieve a list of machines' do
        expect(fleet_client.machines.length).to be 3
      end
    end


    describe '#loaded?', :vcr do

      context 'with an already loaded service' do
        before do
          subject.submit(truebox)
        end

        it "is true" do
          expect { fleet_client.loaded?(truebox) }.to become(true).within(5)
        end
      end

      context 'otherwise' do
        it "is false" do
          expect( fleet_client.loaded?(falsebox) ).to eq false
        end
      end
    end

    describe 'exists?', :live do
      include_context 'units'

      context 'it returns true for loaded or running unit' do
        it 'returns true' do
          require 'pry'; binding.pry
          #subject.exists?(truebox)
        end
      end
    end

    describe 'running?', :vcr do
      context 'with a service currently running' do
        before do
          subject.submit!(runbox)
          subject.start(runbox)
        end

        it 'is true' do
          expect { subject.running?(runbox) }.to become(true).within(5)
        end
      end

      context 'when service is not running' do
        before do
          subject.submit!(falsebox)
        end

        it 'is false' do
          expect(subject.running?(falsebox)).to eq false
        end
      end

    end

    describe 'submit!', :vcr do
      include_context 'units'
      
      it 'submits a unit to the cluster, and waits on it' do
        fleet_client.submit!(falsebox)
        expect(fleet_client.loaded?(falsebox)).to be true
      end
    end

    describe 'submit', :vcr do
      include_context 'units'

      it 'submits a unit to the cluster' do
        fleet_client.submit(falsebox) 
        expect { fleet_client.loaded?(falsebox) }.to become(true).within(5)
      end
    end
  end

  #describe 'connect_to_actual', :live do
  #  let(:fleet_client) { FleetCaptain::FleetClient.new('Test-Stack', key_file: '~/.ssh/bork-knife-ec2.pem') }

  #  it 'submits fleet / etcd requests the the lead machine' do
  #    expect { fleet_client.connect_to_actual }
  #    .to change { fleet_client.connected_to_actual? }
  #    .from(false).to(true)
  #  end
  #end

  describe 'connect to actual', :vcr do
    let(:fleet_client) { FleetCaptain::FleetClient.new('Test-Stack', key_file: '~/.ssh/id_rsa.pub') }
    
    before do
      allow(fleet_client).to receive(:actual).and_return('54.146.31.143')
    end

    it 'will try to connect to the actual' do
      expect(fleet_client).to receive(:connect).with('54.146.31.143')
      fleet_client.connect_to_actual
    end

  end

  describe 'actual', :vcr do
    it 'dynamically determines the etcd cluster leader' do
      expect(fleet_client.actual).to eq '54.146.31.143'
    end
  end
end
