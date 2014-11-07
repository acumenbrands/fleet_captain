require 'mkmf'
require 'open3'
require 'active_support/core_ext/object/blank'

namespace :docker do
  def strategy
    @strategy ||= Capistrano::FleetCaptain.new(self, fetch(:docker_strategy, Capistrano::FleetCaptain::DefaultStrategy))
  end

  def production_tag
    "#{fetch(:repo)}/#{fetch(:application)}:#{fetch(:deploy_tag)}"
  end

  def rollback_tag
    "#{fetch(:repo)}/#{fetch(:application)}:#{fetch(:previous_tag, 'previous')}"
  end

  task :start do
    run_locally do
      strategy.verify
    end
  end

  task :retag do
    run_locally do
      image_id = strategy.image_list[production_tag]
      strategy.tag(image_id, rollback_tag)
    end
  end

  task :build do
    run_locally do
      strategy.build("#{fetch(:repo)}/#{fetch(:application)}:#{fetch(:deploy_tag)}")
    end
  end
end
