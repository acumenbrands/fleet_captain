require 'spec_helper'

describe FleetCaptain::Service do
  let(:unit_text) { <<-UNIT_FILE.strip_heredoc
    [Unit]
    Description=The box of comparison.
    After=docker.service
    Requires=docker.service
    
    [Service]
    ExecStart=/bin/bash test 1
    UNIT_FILE
  }
  
  let(:service1) { FleetCaptain::Service.from_unit('compbox1.service', unit_text) }

  describe '#==' do
    let(:service1) { FleetCaptain::Service.from_unit('compbox1.service', unit_text) }

    it 'is equal because they have the same unit file context' do
      expect(service1).to eq service2
    end
  end

  describe '#attribute=' do
    it 'converts to a command on assignment' do
      expect(service1.start = :run).to eq '/usr/bin/docker run --name compbox1.service'
    end
  end

  describe '#attribute_concat'
  describe '#attribute_multiple?'
  describe '#attributes'
  describe '#container_name'
  describe '#eql?'
  describe '#failable_attribute='
  describe '#failable_attribute_concat'
  describe '#hash'
  describe '#initialize'
  describe '#name='
  describe '#template?'
  describe '#to_command'
  describe '#to_hash'
  describe '#to_service_def'
  describe '#to_unit'
  describe '#unit_hash'
  describe '.command_parser'
  describe '.define_attributes'
  describe '.from_unit'
  describe '.services'
end
