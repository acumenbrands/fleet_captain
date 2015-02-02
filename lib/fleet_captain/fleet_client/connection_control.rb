require 'monitor'

module FleetCaptain
  class FleetClient
    class ConnectionControl
      include MonitorMixin

      def ready!
        synchronize do
          @ready = true
        end
      end

      def ready?
        synchronize do
          @ready
        end
      end

      def stop!
        synchronize do
          @stop = true
        end
      end

      def stop?
        synchronize do
          @stop
        end
      end

      def clean?
        synchronize do
          @clean
        end
      end

      def clean!
        synchronize do
          @clean = true
        end
      end

      def reset
        synchronize do
          @ready = false
          @stop = false
          @clean = false
        end
      end
    end
  end
end

    
