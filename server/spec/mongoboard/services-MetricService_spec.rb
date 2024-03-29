
require 'mongoid'
require 'mongoboard/domain'
require 'mongoboard/data_provider_helper'
require 'pry'

describe Mongoboard::MetricService do

	include Mongoboard::Spec::Testdata

	before :all do
		configureMongoDb
	end

	before :each do
		initEmptyDefaults
	end

	it "returns metrics of a release" do

		release = findRelease 'sample-1', 1
		saveNewMetric release, 'foo', 23
		saveNewMetric release, 'bar', 42
		saveNewMetric release, 'time', 16
		saveNewMetric release, 'value', 1

		release = findRelease 'sample-1', 2
		saveNewMetric release, 'foo', 33
		saveNewMetric release, 'bar', 40
		saveNewMetric release, 'time', 20
		saveNewMetric release, 'value', 2

		release = findRelease 'sample-1', 3
		saveNewMetric release, 'foo', 25
		saveNewMetric release, 'bar', 45
		saveNewMetric release, 'time', 26
		saveNewMetric release, 'value', 1
		
		service = Mongoboard::MetricService.instance
		history = service.findMetricHistory(release._id, 30)
	end
	
	it "raises an error if metric is not uniq" do

		release = findRelease 'sample-1', 1

		saveNewMetric release, 'foo'
		saveNewMetric release, 'foo'

		service = Mongoboard::MetricService.instance
		expect {
			service.findOrCreateMetric('sample-1', '1', 'foo')
		}.to raise_error(Mongoboard::Errors::WrongResultCount)
	end

	it "raises an error if release is not uniq" do
		saveNewRelease 'sample-1', 1

		service = Mongoboard::MetricService.instance
		expect {
			service.findOrCreateMetric('sample-1', '1', 'foo')
		}.to raise_error(Mongoboard::Errors::WrongResultCount)
	end

	it "raises an error if release cannot be found" do
		service = Mongoboard::MetricService.instance
		expect {
			service.findOrCreateMetric('sample-1', '-1', 'foo')
		}.to raise_error(Mongoboard::Errors::WrongResultCount)
	end

	it "finds an existing metric for a unique release" do

		release = findRelease 'sample-1', 1

		metric = saveNewMetric release, 'foo-bar'
		metric.value = 3.2
		metric.label = 'Other'
		metric.save!

		service = Mongoboard::MetricService.instance
		metric = service.findOrCreateMetric('sample-1', '1', 'foo-bar')

		metric.types[0].should eq 'foo-bar'
		metric.label.should eq 'Other'
		metric.value.should eq 3.2
	end

	it "creates a new metric for a unique release" do

		service = Mongoboard::MetricService.instance
		metric = service.findOrCreateMetric('sample-1', '1', 'foo-bar')
		metric.types[0].should eq 'foo-bar'
		metric.label.should eq 'Foo bar'
		metric.value.should eq nil

	end

end

