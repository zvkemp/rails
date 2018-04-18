module ActionCable
  module Metal
    class Server
      include ActionCable::Server::Connections
      include ActiveSupport::Callbacks

      define_callbacks :restart
      define_callbacks :synchronized_restart

      def self.before_restart(*methods, &block)
        set_callback(:restart, :before, *methods, &block)
      end

      def self.on_restart(*methods, &block)
        set_callback(:synchronized_restart, :before, *methods, &block)
      end

      before_restart { connections.each(&:close) }

      attr_reader :config
      delegate :logger, to: :config

      def initialize
        @mutex = Monitor.new
        @remote_connections = @event_loop = @worker_pool = nil
      end

      def config
        @config ||= ActionCable::Server::Configuration.new
      end

      def restart
        run_callbacks(:restart) {}
        @mutex.synchronize do
          run_callbacks(:synchronized_restart) {}
        end
      end

      # Gateway to RemoteConnections. See that class for details.
      def remote_connections
        @remote_connections || @mutex.synchronize do
          @remote_connections ||= ActionCable::RemoteConnections.new(self)
        end
      end

      def event_loop
        @event_loop || @mutex.synchronize do
          @event_loop ||= ActionCable::Connection::StreamEventLoop.new
        end
      end

      def call(env)
        setup_heartbeat_timer unless config.disable_heartbeat
        config.connection_class.call.new(self, env).process
      end

      # The worker pool is where we run connection callbacks and channel actions. We do as little as possible on the server's main thread.
      # The worker pool is an executor service that's backed by a pool of threads working from a task queue. The thread pool size maxes out
      # at 4 worker threads by default. Tune the size yourself with <tt>config.action_cable.worker_pool_size</tt>.
      #
      # Using Active Record, Redis, etc within your channel actions means you'll get a separate connection from each thread in the worker pool.
      # Plan your deployment accordingly: 5 servers each running 5 Puma workers each running an 8-thread worker pool means at least 200 database
      # connections.
      #
      # Also, ensure that your database connection pool size is as least as large as your worker pool size. Otherwise, workers may oversubscribe
      # the database connection pool and block while they wait for other workers to release their connections. Use a smaller worker pool or a larger
      # database connection pool instead.
      def worker_pool
        @worker_pool || @mutex.synchronize do
          @worker_pool ||= ActionCable::Server::Worker.new(max_size: config.worker_pool_size)
        end
      end
      on_restart do
        @worker_pool.halt if @worker_pool
        @worker_pool = nil
      end
    end
  end
end
