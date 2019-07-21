require 'activejob/google_cloud_tasks/config'
require 'google/cloud/tasks'
require 'google/cloud/tasks/v2beta3/cloud_tasks_client'

module Activejob
  module GoogleCloudTasks
    class Adapter
      def initialize(project:, location:, cloud_tasks_client: Google::Cloud::Tasks.new(version: :v2beta3))
        @project = project
        @location = location
        @cloud_tasks_client = cloud_tasks_client
      end

      def enqueue(job, attributes = {})
        formatted_parent = Google::Cloud::Tasks::V2beta3::CloudTasksClient.queue_path(@project, @location, job.queue_name)

        task =
          # NOTE: [Usage]
          #       Job.perform_later(
          #         { id: 1 }.to_json,
          #         url: 'https://example.com/',
          #         http_method: :GET,
          #         headers: {
          #           'Content-Type': 'application/json'
          #         }
          #       )
          if Activejob::GoogleCloudTasks::Config.http_request?
            body = job.arguments.first
            http_request = job.arguments.last
            default_request = {
              url: '',
              http_method: :POST,
              headers: {},
              body: ''
            }
            { http_request: default_request.merge(http_request).merge(body: body) }
          else
            relative_uri = "#{Activejob::GoogleCloudTasks::Config.path}/perform?job=#{job.class}&#{job.arguments.to_param}"
            {
              app_engine_http_request: {
                http_method: :GET,
                relative_uri: relative_uri
              }
            }
          end
        task[:schedule_time] = Google::Protobuf::Timestamp.new(seconds: attributes[:scheduled_at].to_i) if attributes.key?(:scheduled_at)

        # NOTE: Need `response_view: 'FULL'` to check http request body
        @cloud_tasks_client.create_task(formatted_parent, task, response_view: 'FULL')
      end

      def enqueue_at(job, scheduled_at)
        enqueue(job, scheduled_at: scheduled_at)
      end
    end
  end
end
