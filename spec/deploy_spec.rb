require 'spec_helper'

include Capistrano::DSL
load 'fixtures/test.rb'

describe "capistrano elastic docker deploy" do
  # basically, we just instrument parts of capistrano and make sure it does all
  # the right stuff

  it 'works' do
    Rake::Task[:deploy].invoke
  end
end

describe Capistrano::ElasticDocker do
  let!(:test_context) { double }

  subject do 
    Capistrano::ElasticDocker.new(test_context, Capistrano::ElasticDocker::DefaultStrategy)
  end

  describe '#image_list' do
    let(:results) {
      {
        'test/test' => 'deadbeef', 
        'ubuntu' => '00000000', 
        'ruby/ruby' => ['12345678', '876543321'] 
      }
    }

    it 'returns a list of images and their tags' do
      expect { image_list }.to eq results
    end
  end
end
