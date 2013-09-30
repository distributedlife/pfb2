require './lib/mongo_helpers'
require 'action_view'

class Schedule
	include MongoHelpers
	include ActionView::Helpers::DateHelper

	def initialize language, db
		@language = language
		@db = db
	end

	def collection
		@db['schedule']
	end

	def empty?
		collection.find({:language => @language}).count == 0
	end

	def add! what, interval
		collection.insert({:language => @language, :what => what, :when => Time.now, :interval => interval })
	end

	def update! what, interval
		collection.update({:language => @language, :what => what}, {"$set" => {:when => Time.now + interval, :interval => interval }})
	end

	def next_word
		collection.find({:language => @language, :when => {"$lte" => Time.now }}).sort({:when => ascending}).first
	end

	def pending_reviews
		collection.find({:language => @language, :when => {"$lte" => Time.now }}).count
	end

	def interval what
		collection.find({:language => @language, :what => what}).first['interval']
	end

	def scheduled? what
		collection.find({:language => @language, :what => what}).count > 0
	end

	def transition old_interval, new_interval
		collection.find({:language => @language, :interval => old_interval}).to_a.each do |schedule|
			collection.update({:_id => schedule['_id']}, {"$set" => {:interval => new_interval }})
		end
	end

	def time_of_next_review
		what = collection.find({:language => @language}).sort({:when => ascending}).first

		return nil if what.nil?

		distance_of_time_in_words_to_now what['when']
	end
end