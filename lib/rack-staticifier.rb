module Rack #:nodoc:

  # Rack::Staticifier doco ...
  class Staticifier

    # the Rack application
    attr_reader :app

    # configuration options
    attr_reader :config

    def initialize app, config_options = nil, &block
      @app     = app
      @config = default_config_options

      config.merge!(config_options) if config_options
      config[:cache_if] = block     if block
    end

    def call env
      response = @app.call env
      cache_response(env, response) if should_cache_response?(env, response)
      response
    end

    private

    def default_config_options
      { :root => 'cache' }
    end

    def should_cache_response? env, response
      return true unless config.keys.include?(:cache_if) and config[:cache_if].respond_to?(:call)
      should_cache = config[:cache_if].call(env, response)
      should_cache
    end

    def cache_response env, response
      request_path = env['PATH_INFO']

      basename     = ::File.basename request_path
      dirname      = ::File.join config[:root], ::File.dirname(request_path) # TODO grab 'public' from the config options
      fullpath     = ::File.join dirname, basename

      FileUtils.mkdir_p(dirname)
      ::File.open(fullpath, 'w'){|f| f << response_body(response) }
    end

    def response_body response
      body = ''
      response.last.each {|string| body << string } # per the Rack spec, the last object should respond to #each
      body
    end

  end

end