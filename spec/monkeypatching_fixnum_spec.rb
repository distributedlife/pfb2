require 'rspec'
require './lib/add_time_helpers_to_fixnum'

describe "monkeypatching fixnum" do
	describe "second" do
		it "should return itself" do
			1.second.should eq 1
		end
	end

	describe "seconds" do
		it "should return itself" do
			5.seconds.should eq 5
		end
	end

	describe "minute" do
		it "should return the number of minutes in seconds" do
			1.minute.should eq 60
		end
	end

	describe "minutes" do
		it "should return the number of minutes in seconds" do
			2.minutes.should eq 120
		end
	end

	describe "hour" do
		it "should return the number of minutes in seconds" do
			1.hour.should eq 3600
		end
	end

	describe "hours" do
		it "should return the number of minutes in seconds" do
			2.hours.should eq 7200
		end
	end

	describe "day" do
		it "should return the number of minutes in seconds" do
			1.day.should eq 86400
		end
	end

	describe "days" do
		it "should return the number of minutes in seconds" do
			2.days.should eq 172800
		end
	end

	describe "month" do
		it "should return the number of minutes in seconds" do
			1.month.should eq 2592000
		end
	end

	describe "months" do
		it "should return the number of minutes in seconds" do
			2.months.should eq 5184000
		end
	end

	describe "year" do
		it "should return the number of minutes in seconds" do
			1.year.should eq 31536000
		end
	end

	describe "years" do
		it "should return the number of minutes in seconds" do
			2.years.should eq 63072000
		end
	end
end