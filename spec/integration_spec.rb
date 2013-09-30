# encoding: utf-8
require 'rspec'
require 'rack/test'
require	'timecop'
require 'mongo'
require "./sinatra"

include Mongo

describe "in boom crash opera" do
	include Rack::Test::Methods

	def app
    	Sinatra::Application
  	end

  	def connect_to_mongo
  		conn = MongoClient.new("localhost", 27017)
		@db = conn.db('production')
	end

	before(:all) do
  		connect_to_mongo
		@start = Time.now.utc
		@past = @start - 1
		@future = @start + 1
  		Timecop.freeze(@start)
	end

	before(:each) do
		@db.drop_collection 'interval'
		@db.create_collection 'interval'

		@db.drop_collection 'schedule'
		@db.create_collection 'schedule'
	end

	describe "when I start a language for the first time" do
	  	before(:each) do
	  		get '/chinese/review'
	  	end

		it "should setup the initial interval for the language" do
			@db['interval'].count.should be 11

			intervals = @db['interval'].find.to_a

			[5, 25, 120, 600, 3600, 18000, 86400, 432000, 2160000, 10368000, 63072000].each_with_index do |interval, index|
				intervals[index]['interval'].should be interval
				intervals[index]['sequence'].should eq 0
				intervals[index]['language'].should eq "chinese"
			end
		end

		it "should schedule the first word" do
			@db['schedule'].find.to_a.first['what'].should eq "你"
		end

		it "should only schedule one word" do
			@db['schedule'].count.should be 1
		end

		it "should set the correct language" do
			@db['schedule'].find.to_a.first['language'].should eq "chinese"
		end

		it "should make the card due now" do
			@db['schedule'].find.to_a.first['when'].to_s.should eq @start.to_s
		end

		it "should set the interval to first interval" do
			@db['schedule'].find.to_a.first['interval'].should eq 5
		end

		it "should not redirect to the language done page" do
			last_response.should_not be_redirect
		end
	end

	describe "when I visit a language I've started" do
		before(:each) do
			get '/chinese/review'
		end

		context "and there is a word to review" do
			before(:each) do
				@db['schedule'].update({:language => 'chinese', :what => '你'}, {"$set" => {:when => @past, :interval => 5 }})
				get '/chinese/review'
			end

			it "should not redirect to the language done page" do
				last_response.should_not be_redirect
			end

			it "should not schedule any more words" do
				@db['schedule'].count.should be 1
			end
		end

		context "and there are no words due" do
			before(:each) do
				@db['schedule'].remove
				@db['schedule'].insert({:language => 'chinese', :what => '你', :when => @future, :interval => 25 })
				@db['schedule'].insert({:language => 'chinese', :what => '好', :when => @future, :interval => 25 })
			end

			context "and there are available sentences" do
				before(:each) do
					get '/chinese/review'
				end

				it "should schedule the next allowed sentence" do
					@db['schedule'].find.to_a.last['what'].should eq "你好"
				end

				it "should be two words scheduled" do
					@db['schedule'].count.should be 3
				end

				it "should set the correct language" do
					@db['schedule'].find.to_a.last['language'].should eq "chinese"
				end

				it "should make the card due now" do
					@db['schedule'].find.to_a.last['when'].to_s.should eq @start.to_s
				end

				it "should set the interval to first interval" do
					@db['schedule'].find.to_a.last['interval'].should eq 5
				end

				it "should not redirect to the language done page" do
					last_response.should_not be_redirect
				end
			end

			context "and there are no new sentences to learn" do
				before(:each) do
					@db['schedule'].insert({:language => 'chinese', :what => '你好', :when => @future, :interval => 25 })
					get '/chinese/review'
				end

				it "should schedule the next word" do
					@db['schedule'].find.to_a.last['what'].should eq "吗"
				end

				it "should be two words scheduled" do
					@db['schedule'].count.should be 4
				end

				it "should set the correct language" do
					@db['schedule'].find.to_a.last['language'].should eq "chinese"
				end

				it "should make the card due now" do
					@db['schedule'].find.to_a.last['when'].to_s.should eq @start.to_s
				end

				it "should set the interval to first interval" do
					@db['schedule'].find.to_a.last['interval'].should eq 5
				end

				it "should not redirect to the language done page" do
					last_response.should_not be_redirect
				end
			end
		end

		describe "when I get a review incorrect" do
			before(:each) do
				@db['schedule'].update({:language => 'chinese', :what => '你'}, {"$set" => {:when => @start, :interval => 25 }})
				@db['interval'].update({:language => 'chinese', :interval => 25}, {"$set" => {:sequence => 0 }})
			end

			context "when the prior review was a failure" do
				before(:each) do
					@db['interval'].update({:language => 'chinese', :interval => 25}, {"$set" => {:sequence => -1 }})
					get URI.encode('/chinese/你/review/failure')
				end

				it "should add a failure to interval sequence" do
					@db['interval'].find_one(:interval => 25)['sequence'].should eq -2
				end
			end

			context "when the prior review was a success" do
				before(:each) do
					@db['interval'].update({:language => 'chinese', :interval => 25}, {"$set" => {:sequence => 1 }})
					get URI.encode('/chinese/你/review/failure')
				end

				it "should reset the interval sequence" do
					@db['interval'].find_one(:interval => 25)['sequence'].should eq -1
				end
			end

			it "should reset the interval" do
				get URI.encode('/chinese/你/review/failure')

				@db['schedule'].find.to_a.first['interval'].should eq 5
			end

			it "should reschedule the word for now plus interval" do
				get URI.encode('/chinese/你/review/failure')

				@db['schedule'].find.to_a.first['when'].to_s.should eq (@start + 5).to_s
			end

			it "should redirect to the review page" do
				get URI.encode('/chinese/你/review/failure')

				last_response.should be_redirect
				follow_redirect!
  				last_request.url.should == 'http://example.org/chinese/review'
			end
		end

		describe "when I get a review correct" do
			before(:each) do
				@db['schedule'].update({:language => 'chinese', :what => '你'}, {"$set" => {:when => @start, :interval => 25 }})
			end

			describe "when the prior review was a success" do
				before(:each) do
					@db['interval'].update({:language => 'chinese', :interval => 25}, {"$set" => {:sequence => -1 }})
					get URI.encode('/chinese/你/review/success')
				end

				it "should reset the interval sequence" do
					@db['interval'].find_one(:interval => 25)['sequence'].should eq 1
				end
			end

			describe "when the prior review was a success" do
				before(:each) do
					@db['interval'].update({:language => 'chinese', :interval => 25}, {"$set" => {:sequence => 1 }})
					get URI.encode('/chinese/你/review/success')
				end

				it "should add a success to interval sequence" do
					@db['interval'].find_one(:interval => 25)['sequence'].should eq 2
				end
			end

			it "should increase the interval" do
				get URI.encode('/chinese/你/review/success')

				@db['schedule'].find.to_a.first['interval'].should eq 120
			end

			it "should reschedule the word for now plus interval" do
				get URI.encode('/chinese/你/review/success')

				@db['schedule'].find.to_a.first['when'].to_s.should eq (@start + 120).to_s
			end

			it "should redirect to the review page" do
				get URI.encode('/chinese/你/review/success')

				last_response.should be_redirect
				follow_redirect!
  				last_request.url.should == 'http://example.org/chinese/review'
			end
		end

		describe "when I get 10 reviews correct for an interval in a row" do
			before(:each) do
				@db['schedule'].remove
				@db['schedule'].insert({:language => 'chinese', :what => '你', :when => @start, :interval => 25 })
				@db['schedule'].insert({:language => 'chinese', :what => '吗', :when => @start, :interval => 25 })
				
				@db['interval'].remove
				[5.seconds, 25.seconds, 2.minutes, 10.minutes, 1.hour, 5.hours, 1.day, 5.days, 25.days, 4.months, 2.years].each do |interval|
					@db['interval'].insert({:interval => interval, :sequence => 9, :language => 'chinese'})
				end

				get URI.encode('/chinese/你/review/success')
			end

			it "should increase the interval to the current interval plus the next divided by two" do
				@db['interval'].find_one(:language => 'chinese', :interval => 25).nil?.should be true
				@db['interval'].find_one(:language => 'chinese', :interval => 72.5).nil?.should be false
			end

			it "should reset the sequence" do
				@db['interval'].find_one(:language => 'chinese', :interval => 72.5)['sequence'].should eq 0
			end			

			it "should update all words at that interval to the new interval" do
				@db['schedule'].find_one({:language => 'chinese', :what => '吗', :when => @start})['interval'].should eq 72.5
			end
		end

		describe "when I get 10 reviews incorrect for an interval in a row" do
			before(:each) do
				@db['schedule'].remove
				@db['schedule'].insert({:language => 'chinese', :what => '你', :when => @start, :interval => 25 })
				@db['schedule'].insert({:language => 'chinese', :what => '吗', :when => @start, :interval => 25 })
				
				@db['interval'].remove
				[5.seconds, 25.seconds, 2.minutes, 10.minutes, 1.hour, 5.hours, 1.day, 5.days, 25.days, 4.months, 2.years].each do |interval|
					@db['interval'].insert({:interval => interval, :sequence => -9, :language => 'chinese'})
				end

				get URI.encode('/chinese/你/review/failure')
			end

			it "should decrease the interval by half the distance between this and the prior" do
				@db['interval'].find_one(:language => 'chinese', :interval => 25).nil?.should be true
				@db['interval'].find_one(:language => 'chinese', :interval => 15).nil?.should be false
			end

			it "should reset the sequence" do
				@db['interval'].find_one(:language => 'chinese', :interval => 15)['sequence'].should eq 0
			end

			it "should update all words at that interval to the new interval" do
				@db['schedule'].find_one({:language => 'chinese', :what => '吗', :when => @start})['interval'].should eq 15
			end
		end
	end
end