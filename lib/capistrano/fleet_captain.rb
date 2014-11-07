require "capistrano"
require "mkmf"

if Rake::Task.tasks.include?("deploy")
  Rake::Task["deploy"].clear_actions
end

require "capistrano/elastic_docker/version"
require "capistrano/scm"

load File.expand_path("../tasks/deploy.rake", __FILE__)
load File.expand_path("../tasks/docker.rake", __FILE__)

module Capistrano
  class FleetCaptain < Capistrano::SCM
    def docker(*args)
      args.unshift :docker
      require 'pry'; binding.pry
      #context.execute(*args)
    end

    module DefaultStrategy
      def verify
        unless find_executable('docker')
          exit 1 and puts "docker is not available"
        end

        Open3.popen3('docker ps') do |_, out, err, _|
          unless err.read.blank?
            exit 1 and puts err
          end
        end
      end

      def test
      end

      def check
      end

      def clone
      end

      def image_list
        context.capture(:docker, :images).each_line.grep(/hackuman\/ruby/).collect { |l| l.split(/\s{2,}/)[2] }
      end

      def tag(image_id, tag)
        docker :tag, image_id, tag
      end

      def update
        docker :build, repo_tag
      end

      def release
        docker :push, repo_tag
      end

      def fetch_revision
      end
    end
  end
end
