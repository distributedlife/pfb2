# encoding: utf-8
require 'yaml'

module Mongo
	@db = nil
	@name = nil

	def collection
		@db[@name]
	end

	def create!
		@db.create_collection(@name) unless @db.collection_names.include? @name
	end

	def ascending
		1
	end

	def descending
		-1
	end

	def reset!
		@db.drop_collection @name
	end

	def empty?
		collection.count == 0
	end
end

module Language
	@language = nil

	def language
		return @language
	end

	def empty?
		collection.find(:language => language).count == 0
	end
end

class BoomCrashOpera
	def next_revision
		unless @interval.setup?
			@interval.setup!
		end

		if @schedule.empty?
			@schedule.add! @to_learn.first['word'], @interval.first
		end

		@schedule.next_word
	end

	def learn_next_word
		@to_learn.each do |item|
			next if @schedule.scheduled? item['word']

			@schedule.add! item['word'], @interval.first
			return
		end
	end

	def reset_schedule! word
		current_interval = @schedule.interval word

		@interval.add_failure current_interval

		if @interval.get(current_interval)['sequence'] <= -10
			prior_interval = @interval.previous current_interval
			new_interval = (current_interval + prior_interval).to_f / 2

			@interval.replace current_interval, new_interval

			@schedule.transition current_interval, new_interval
		end

		@schedule.update! word, @interval.first
	end

	def schedule_next_review! word
		current_interval = @schedule.interval word

		@interval.add_success current_interval

		if @interval.get(current_interval)['sequence'] >= 10
			next_interval = @interval.next current_interval
			new_interval = (current_interval + next_interval).to_f / 2

			@interval.replace current_interval, new_interval

			@schedule.transition current_interval, new_interval
		end

		@schedule.update! word, @interval.next(current_interval)
	end

	def initialize interval, schedule, dataset
		@interval = interval
		@schedule = schedule
		@to_learn = dataset
	end

	def self.reset! db
		['interval', 'schedule'].each do |name|
			db.drop_collection name
			db.create_collection name
		end
	end
end