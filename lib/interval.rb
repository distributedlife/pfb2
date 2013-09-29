require './lib/add_time_helpers_to_fixnum'
require './lib/mongo_helpers'

class Interval
	include MongoHelpers

	def initialize language, db
		@language = language
		@db = db
	end

	def collection
		@db['interval']
	end

	def setup?
		return !empty?
	end

	def setup!
		[5.seconds, 25.seconds, 2.minutes, 10.minutes, 1.hour, 5.hours, 1.day, 5.days, 25.days, 4.months, 2.years].each do |interval|
			collection.insert({:interval => interval, :sequence => 0, :language => @language})
		end
	end

	def get seconds
		collection.find_one(:language => @language, :interval => seconds)
	end

	def empty?
		collection.find({:language => @language}).count == 0
	end

	def first
		collection.find({:interval => {"$gt" => 0}}).sort({:interval => ascending}).to_a.first['interval']
	end

	def last
		collection.find({:interval => {"$gt" => 0}}).sort({:interval => descending}).to_a.first['interval']
	end

	def next interval
		value = collection.find({:interval => {"$gt" => interval}}).sort({:interval => ascending}).to_a.first

		if value.nil?
			last
		else
			value['interval']
		end
	end

	def previous interval
		value = collection.find({:interval => {"$lt" => interval}}).sort({:interval => ascending}).to_a.last

		if value.nil?
			0
		else
			value['interval']
		end
	end

	def add_failure interval
		change = get(interval)['sequence'] >= 0 ? "$set" : "$inc"
		collection.update({:language => @language, :interval => interval}, {change => {:sequence => -1 }})
	end

	def add_success interval
		change = get(interval)['sequence'] <= 0 ? "$set" : "$inc"
		collection.update({:language => @language, :interval => interval}, {change => {:sequence => 1 }})
	end

	def replace current_interval, new_interval
		collection.find({:language => @language, :interval => current_interval}).to_a.each do |record|
			collection.update({:_id => record["_id"]}, {"$set" => {:interval => new_interval, :sequence => 0 }})
		end
	end
end
