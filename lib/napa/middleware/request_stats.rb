module Napa
  class Middleware
    class RequestStats
      def initialize(app)
        @app = app
      end

      def normalize_path(path)
        case 
          when path == '/'
            'root'
          else
            path.start_with?('/') ? path[1..-1] : path
        end
      end

      def call(env)
        # Mark the request time
        start = Time.now

        # Process the request
        status, headers, body = @app.call(env)

        # Mark the response time
        stop = Time.now

        # Calculate total response time
        response_time = (stop - start) * 1000
        
        request = Rack::Request.new(env)
        path = normalize_path(request.path_info)
        Thread.current[:stats_context] = "#{Napa::Identity.name}.http.#{request.request_method.downcase}.#{path}".gsub('/', '.')

        # Emit stats to StatsD
        Napa::Stats.emitter.increment(Thread.current[:stats_context] + '.requests')
        Napa::Stats.emitter.timing(Thread.current[:stats_context] + '.response_time', response_time)
        # Return the results
        [status, headers, body]
      end
    end
  end
end
