# encoding: utf-8
require 'rspec'
require 'mongo'
require 'timecop'
require './lib/schedule'

include Mongo

chinese = nil
egyptian = nil

describe 'the schedule' do
	before(:all) do
		conn = MongoClient.new("localhost", 27017)
		@db = conn.db('production')

		@start = Time.now.utc
  		Timecop.freeze(@start)
	end

	before(:each) do
		@db.drop_collection 'schedule'
		@db.create_collection 'schedule'

		chinese = Schedule.new 'chinese', @db
	end

	describe "empty?" do
		before(:each) do
			egyptian = Schedule.new 'egyptian', @db
			@db['schedule'].insert({:language => 'chinese', :what => "你", :interval => 5, :when => Time.now})
		end

		it 'should return true if no schedule for language is empty' do
			egyptian.empty?.should be_true
		end

		it "should return false if at least one schedule exists" do
			chinese.empty?.should be_false
		end
	end

	describe "add!" do
		before(:each) do
			chinese.add! "你", 5
		end

		it "should add the word to the schedule" do
			@db['schedule'].find_one({:language => 'chinese', :what => "你"})['interval'].should eq 5
		end

		it "should be scheduled for now" do
			@db['schedule'].find_one({:language => 'chinese', :what => "你"})['when'].to_s.should eq @start.to_s
		end
	end

	describe "update!" do
		before(:each) do
			chinese.add! "你", 5
			chinese.update! "你", 25
		end

		it "should update the interval" do
			@db['schedule'].find_one({:language => 'chinese', :what => "你"})['interval'].should eq 25
		end

		it "should update the when by the interval and now" do
			@db['schedule'].find_one({:language => 'chinese', :what => "你"})['when'].to_s.should eq (@start + 25).to_s
		end
	end

	describe "next_word" do
		before(:each) do
			@db['schedule'].insert({:language => 'chinese', :what => "你", :interval => 5, :when => Time.now})
			@db['schedule'].insert({:language => 'chinese', :what => "好", :interval => 25, :when => Time.now + 25})
		end

		it "should return the next due item" do
			chinese.next_word['what'].should eq '你'
		end

		it "should return nothing if nothing is due" do
			@db['schedule'].remove
			@db['schedule'].insert({:language => 'chinese', :what => "好", :interval => 25, :when => Time.now + 1})

			chinese.next_word.nil?.should be_true
		end
	end

	describe "interval" do
		before(:each) do
			@db['schedule'].insert({:language => 'chinese', :what => "你", :interval => 5, :when => Time.now})
		end

		it "should return the interval of the word" do
			chinese.interval("你").should be 5
		end
	end

	describe "scheduled" do
		before(:each) do
			@db['schedule'].insert({:language => 'chinese', :what => "你", :interval => 5, :when => Time.now})
		end

		it "should return true if the word is schedule" do
			chinese.scheduled?("你").should be_true
			chinese.scheduled?("好").should be_false
		end
	end

	describe "transition" do
		before(:each) do
			@db['schedule'].insert({:language => 'chinese', :what => "你", :interval => 5, :when => Time.now})
			@db['schedule'].insert({:language => 'chinese', :what => "好", :interval => 25, :when => Time.now})

			chinese.transition 5, 50
		end

		it "should move all the words on the old interval to the new interval" do
			chinese.interval("你").should be 50
			chinese.interval("好").should be 25
		end
	end
end