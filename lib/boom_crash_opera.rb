# encoding: utf-8
require 'yaml'

class BoomCrashOpera
	def next_word_to_review
		unless @interval.setup?
			@interval.setup!
		end

		if @schedule.empty?
			@schedule.add! @to_learn.first['word'], @interval.first
		end

		if @schedule.next_word.nil?
			add_new_word_to_schedule
		end

		@schedule.next_word
	end

	def add_new_word_to_schedule
		@to_learn.each do |item|
			next if @schedule.scheduled? item['word']

			@schedule.add! item['word'], @interval.first
			return
		end
	end

	def reset_word! word
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

	def advance_word! word
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