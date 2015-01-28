require 'active_support/inflector'

module FleetCaptain
  module Commands
    class Parser
      attr_reader :command, :container_command, :service

      def initialize(service, command, failable: true)
        @service           = service
        container_klass    = "FleetCaptain::Commands::#{service.container_type.classify}"
        @container_command = container_klass.constantize.new(service)
        @failable          = failable
        @command           = command
      end

      def failable?
        @failable
      end

      def to_command(command = self.command)
        case command
        when NilClass
          nil
        when String
          fail_prefix command.chomp
        when Symbol, Hash
          fail_prefix @container_command.to_command(command)
        when Array
          command.map { |v| self.class.new(service, v, failable: failable?).to_command }.flatten
        end
      end

      def fail_prefix(command)
        if command.respond_to? :map
          command.map do |c|
            "#{ '-' if failable? }#{c}"
          end
        else
          "#{ '-' if failable? }#{command}"
        end
      end
    end
  end
end
