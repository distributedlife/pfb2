# encoding: utf-8
require 'rspec'
require 'mongo'
require './lib/interval'

include Mongo

chinese = nil
egyptian = nil

describe "intervals" do
	before(:all) do
		conn = MongoClient.new("localhost", 27017)
		@db = conn.db('production')
		@db.drop_collection 'interval'
		@db.create_collection 'interval'
	end

	before(:each) do
		chinese = Interval.new 'chinese', @db
	end

	describe "setup?" do
		before(:each) do
			egyptian = Interval.new 'egyptian', @db
			@db['interval'].insert({:language => 'chinese', :interval => 5, :sequence => 0})
		end

		it 'should return true if no interval for language is empty' do
			egyptian.setup?.should be_false
		end

		it "should return false if at least one interval exists" do
			chinese.setup?.should be_true
		end
	end

	describe "setup!" do
		before(:each) do
			chinese.setup!
		end

		it "should make an interval for each of the defaults" do
			[5, 25, 120, 600, 3600, 18000, 86400, 432000, 2160000, 10368000, 63072000].each do |seconds|
				@db['interval'].find({:language => 'chinese', :interval => seconds}).nil?.should be_false
				@db['interval'].find_one({:language => 'chinese', :interval => seconds})['sequence'].should eq 0
			end
		end
	end

	describe "get" do
		before(:each) do
			@db['interval'].insert({:language => 'chinese', :interval => 555, :sequence => 7})
		end

		it "returns the interval" do
			chinese.get(555)['sequence'].should eq 7
		end
	end

	describe "empty?" do
		before(:each) do
			egyptian = Interval.new 'egyptian', @db
			@db['interval'].insert({:language => 'chinese', :interval => 5, :sequence => 0})
		end

		it 'should return true if no interval for language is empty' do
			egyptian.empty?.should be_true
		end

		it "should return false if at least one interval exists" do
			chinese.empty?.should be_false
		end
	end

	describe "first" do
		it "should return the interval with the lowest number" do
			chinese.first.should eq 5
		end
	end

	describe "last" do
		it "should return the interval with the highest number" do
			chinese.last.should eq 63072000
		end
	end

	describe "next" do
		it "should return the interval with the next highest number" do
			chinese.next(5).should eq 25
		end

		it "should return the same number if there is no next highest" do
			chinese.next(63072000).should eq 63072000
		end
	end

	describe "previous" do
		it "should return the interval with the next lowest number" do
			chinese.previous(25).should eq 5
		end

		it "should return 0 if there is no next lowest" do
			chinese.previous(5).should eq 0
		end
	end

	describe "add failure" do
		it "should decrement the sequence by one" do
			@db['interval'].insert({:language => 'chinese', :interval => 200, :sequence => -5})

			chinese.add_failure(200)
			chinese.get(200)['sequence'].should eq -6
		end

		it "should force positive sequences to -1" do
			@db['interval'].insert({:language => 'chinese', :interval => 201, :sequence => 5})
			
			chinese.add_failure(201)
			chinese.get(201)['sequence'].should eq -1
		end
	end

	describe "add success" do
		it "should increment the sequence by one" do
			@db['interval'].insert({:language => 'chinese', :interval => 202, :sequence => 5})

			chinese.add_success(202)
			chinese.get(202)['sequence'].should eq 6
		end

		it "should force negative sequences to 1" do
			@db['interval'].insert({:language => 'chinese', :interval => 203, :sequence => -5})
			
			chinese.add_success(203)
			chinese.get(203)['sequence'].should eq 1
		end
	end

	describe "replace" do
		before(:each) do
			@db['interval'].insert({:language => 'chinese', :interval => 600, :sequence => 7})
			chinese.replace(600, 300)
		end

		it "should update the interval with it's new value" do
			chinese.get(600).nil?.should be_true
			chinese.get(300).nil?.should be_false
		end

		it "should reset the sequence" do
			chinese.get(300)['sequence'].should eq 0
		end
	end
end