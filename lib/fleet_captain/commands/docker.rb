require 'fleet_captain/commands/hash_options'

module FleetCaptain
  module Commands
    class Docker
      attr_reader :service

      def initialize(service)
        @service = service
      end

      def to_command(command)
        parse(command) do |parsed_command|
          if parsed_command.action.inquiry.run?
            run_command(parsed_command)
          else
            other_command(parsed_command)
          end
        end
      end

      def run_command(parsed_command)
        [ "/usr/bin/docker",
          parsed_command.action,
          "--name #{service.container_name}",
          parsed_command.params,
          service.container,
          parsed_command.commands ].join(" ").squish
      end

      def other_command(parsed_command)
        [ "/usr/bin/docker",
          parsed_command.action,
          parsed_command.params,
          service.container_name ].join(" ").squish
      end

      def parse(command)
        case command
        when String, Symbol
          yield(HashOptions.new(command.to_s))
        when Hash
          # Array wrap implicitly converts hashes to arrays.  not what we
          # want so do it by hand.
          
          command.map { |k, args| 
            yield HashOptions.create(k => args)
          }
        end
      end
    end
  end
end
