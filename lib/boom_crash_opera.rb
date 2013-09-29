# encoding: utf-8
require 'yaml'
require './lib/interval'
require './lib/schedule'

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
	def next_revision language
		all_in_language = YAML.load_file('characters.yaml')[language]

		unless @interval.setup_for_language? language
			@interval.setup_for_language language
		end

		if @schedule.empty?
			word = all_in_language.first['word']

			@schedule.add! language, word, @interval.first['interval']
		end

		@schedule.next language
	end

	def learn_next_word language
		all_in_language = YAML.load_file('characters.yaml')[language]

		all_in_language.each do |item|
			unless @schedule.in_shedule(language, item['word'])
				@schedule.add! language, item['word'], @interval.first['interval']
				return
			end
		end
	end

	def reset_schedule! language, word
		current_interval = @schedule.current_interval language, word

		@interval.add_failure language, current_interval

		if @interval.sequence(language, current_interval) <= -10
			prior_interval = @interval.prior current_interval
			new_interval = (current_interval + prior_interval).to_f / 2

			@interval.replace language, current_interval, new_interval

			@schedule.transition language, current_interval, new_interval
		end

		@schedule.update! language, word, @interval.first['interval']
	end

	def schedule_next_review! language, word
		current_interval = @schedule.current_interval language, word

		@interval.add_success language, current_interval

		if @interval.sequence(language, current_interval) >= 10
			next_interval = @interval.next current_interval
			new_interval = (current_interval + next_interval).to_f / 2

			@interval.replace language, current_interval, new_interval

			@schedule.transition language, current_interval, new_interval
		end

		@schedule.update! language, word, @interval.next(current_interval)
	end

	def initialize db
		@interval = Interval.new db
		@schedule = Schedule.new db
	end

	def collections
		['intervals', 'schedule']
	end

	def reset!
		@interval.reset!
		@schedule.reset!
	end

	def create!
		@interval.create!
		@schedule.create!
	end

	def setup!
		reset!
		create!
	end
end