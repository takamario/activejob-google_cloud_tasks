module Activejob
  module GoogleCloudTasks
    class Config
      DEFAULT_PATH = '/activejobs'.freeze
      DEFAULT_TARGET = :app_engine

      class << self
        def path
          @path.presence || DEFAULT_PATH
        end

        def path=(path)
          raise "path can't be blank" if path.blank?

          @path = path
        end

        def target
          @target.presence || DEFAULT_TARGET
        end

        def target=(target)
          @target = target.to_sym
        end

        def http_request?
          @target == :http
        end

        def app_engine_http_request?
          @target == DEFAULT_TARGET
        end
      end
    end
  end
end
