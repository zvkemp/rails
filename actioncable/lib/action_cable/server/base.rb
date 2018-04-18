# frozen_string_literal: true

require "monitor"

module ActionCable
  module Server
    # A singleton ActionCable::Server instance is available via ActionCable.server. It's used by the Rack process that starts the Action Cable server, but
    # is also used by the user to reach the RemoteConnections object, which is used for finding and disconnecting connections across all servers.
    #
    # Also, this is the server instance used for broadcasting. See Broadcasting for more information.
    class Base < ActionCable::Metal::Server
      include ActionCable::Server::Broadcasting

      cattr_accessor :config, instance_accessor: true, default: ActionCable::Server::Configuration.new

      def self.logger; config.logger; end

      attr_reader :mutex

      def initialize
        super
        @pubsub = nil
      end

      # Called by Rack to setup the server.
      def call(env)
        setup_heartbeat_timer
        config.connection_class.call.new(self, env).process
      end

      # Disconnect all the connections identified by +identifiers+ on this server or any others via RemoteConnections.
      def disconnect(identifiers)
        remote_connections.where(identifiers).disconnect
      end

      # Adapter used for all streams/broadcasting.
      def pubsub
        @pubsub || @mutex.synchronize { @pubsub ||= config.pubsub_adapter.new(self) }
      end
      on_restart do
        # Shutdown the pub/sub adapter
        @pubsub.shutdown if @pubsub
        @pubsub = nil
      end

      # All of the identifiers applied to the connection class associated with this server.
      def connection_identifiers
        config.connection_class.call.identifiers
      end
    end

    ActiveSupport.run_load_hooks(:action_cable, Base.config)
  end
end
