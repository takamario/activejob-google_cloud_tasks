require_relative '../spec_helper.rb'

RSpec.describe Activejob::GoogleCloudTasks::Config do
  subject { Activejob::GoogleCloudTasks::Config }

  before do
    Activejob::GoogleCloudTasks::Config.target = Activejob::GoogleCloudTasks::Config::DEFAULT_TARGET
  end

  describe 'path' do
    it 'have default path value' do
      expect(subject.path).to eq '/activejobs'
    end

    it 'changes arbitrary path' do
      subject.path = '/jobs'
      expect(subject.path).to eq '/jobs'
    end

    it 'raises if blank path is to be set' do
      expect { subject.path = nil }.to raise_error(RuntimeError)
      expect { subject.path = '' }.to raise_error(RuntimeError)
    end
  end

  describe 'target' do
    it 'have default target value' do
      expect(subject.target).to eq :app_engine
    end

    it 'changes target to http_request' do
      subject.target = 'http_request'
      expect(subject.target).to eq :http_request
    end
  end

  describe 'app_engine_http_request?' do
    it 'returns true' do
      subject.target = :app_engine
      expect(subject.app_engine_http_request?).to eq true
      expect(subject.http_request?).to eq false
    end
  end

  describe 'http_request?' do
    it 'returns true' do
      subject.target = :http
      expect(subject.app_engine_http_request?).to eq false
      expect(subject.http_request?).to eq true
    end
  end
end
