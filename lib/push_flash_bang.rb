# encoding: utf-8

class PushFlashBang
	def next_word_to_review
		unless @interval.setup?
			@interval.setup!
		end

		if @schedule.empty?
			add_first_word
		end

		if @schedule.next_word.nil?
			add_new_sentence_to_schedule
		end

		if @schedule.next_word.nil?
			add_new_word_to_schedule
		end

		@schedule.next_word
	end

	def pending_review_count
		@schedule.pending_reviews
	end

	def add_first_word
		@schedule.add! @words.first['word'], @interval.first
		@schedule.add! @words.first['meaning'], @interval.first
	end

	def add_new_sentence_to_schedule
		words_learnt = @words.select {|item| @schedule.scheduled? item['word'] }.map {|item| item['word']}
		available_sentences = @sentences.select { |item| !@schedule.scheduled?(item['sentence']) }.select { |item| (item['sentence'].split("") - words_learnt).empty?}

		unless available_sentences.empty?
			@schedule.add! available_sentences.first['sentence'], @interval.first
			@schedule.add! available_sentences.first['meaning'], @interval.first
		end
	end

	def add_new_word_to_schedule
		@words.each do |item|
			next if @schedule.scheduled? item['word']

			@schedule.add! item['word'], @interval.first
			@schedule.add! item['meaning'], @interval.first
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

	def initialize interval, schedule, word_dataset, sentence_dataset
		@interval = interval
		@schedule = schedule
		@words = word_dataset
		@sentences = sentence_dataset
	end

	def self.reset! db
		['interval', 'schedule'].each do |name|
			db.drop_collection name
			db.create_collection name
		end
	end
end