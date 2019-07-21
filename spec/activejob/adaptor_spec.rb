require_relative '../spec_helper.rb'

RSpec.describe Activejob::GoogleCloudTasks::Adapter do
  let(:client) { spy('Google::Cloud::Tasks') }
  let(:queue) { 'my-queue' }
  let(:project) { 'my-project' }
  let(:location) { 'my-location' }
  subject do
    Activejob::GoogleCloudTasks::Adapter.new(
      project: project, location: location, cloud_tasks_client: client
    )
  end

  before do
    eval <<-JOB
      class GreetJob < ActiveJob::Base
        queue_as "#{queue}"
        def perform(args)
          "hello, \#{args[:name]}!"
        end
      end
    JOB
  end

  describe '#enqueue' do
    context 'app_engine_http_request' do
      before do
        Activejob::GoogleCloudTasks::Config.target = :app_engine
      end

      let(:job) { GreetJob.new(name: 'foo') }

      it 'creates cloud tasks job' do
        subject.enqueue(job)

        expect(client).to have_received(:create_task).with(
          "projects/#{project}/locations/#{location}/queues/#{queue}",
          {
            app_engine_http_request: {
              http_method: :GET,
              relative_uri: "#{Activejob::GoogleCloudTasks::Config.path}/perform?job=GreetJob&name=foo"
            }
          },
          response_view: 'FULL'
        )
      end

      it 'creates cloud tasks job with schedule' do
        scheduled_at = 1.hour.since
        subject.enqueue(job, scheduled_at: scheduled_at)

        expect(client).to have_received(:create_task).with(
          "projects/#{project}/locations/#{location}/queues/#{queue}",
          {
            app_engine_http_request: {
              http_method: :GET,
              relative_uri: "#{Activejob::GoogleCloudTasks::Config.path}/perform?job=GreetJob&name=foo"
            },
            schedule_time: Google::Protobuf::Timestamp.new(seconds: scheduled_at.to_i)
          },
          response_view: 'FULL'
        )
      end
    end

    context 'http_request' do
      before do
        Activejob::GoogleCloudTasks::Config.target = :http
      end

      let(:job) do
        GreetJob.new(
          { name: 'foo' }.to_json,
          headers: { 'Content-Type' => 'application/json' },
          url: 'https://example.com/',
          http_method: :GET
        )
      end

      it 'creates cloud tasks job' do
        subject.enqueue(job)

        expect(client).to have_received(:create_task).with(
          "projects/#{project}/locations/#{location}/queues/#{queue}",
          {
            http_request: {
              url: 'https://example.com/',
              http_method: :GET,
              headers: { 'Content-Type' => 'application/json' },
              body: { name: 'foo' }.to_json
            }
          },
          response_view: 'FULL'
        )
      end

      it 'creates cloud tasks job with schedule' do
        scheduled_at = 1.hour.since
        subject.enqueue(job, scheduled_at: scheduled_at)

        expect(client).to have_received(:create_task).with(
          "projects/#{project}/locations/#{location}/queues/#{queue}",
          {
            http_request: {
              url: 'https://example.com/',
              http_method: :GET,
              headers: { 'Content-Type' => 'application/json' },
              body: { name: 'foo' }.to_json
            },
            schedule_time: Google::Protobuf::Timestamp.new(seconds: scheduled_at.to_i)
          },
          response_view: 'FULL'
        )
      end
    end
  end
end
