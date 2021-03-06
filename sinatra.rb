# encoding: utf-8

require 'sinatra'
require 'sinatra/json'
require 'haml'
require 'mongo'
require 'json/ext'
require 'yaml'
require './lib/push_flash_bang'
require './lib/interval'
require './lib/schedule'
require './lib/pronunciation_guidance'
require './routes/api_routes'

# class PushFlashBang < Sinatra::Base
	include Mongo
	include Sinatra::ApiRoutes

	def supported_languages
		['chinese']
	end

	before do
	  content_type :html, 'charset' => 'utf-8'
	end

	configure do
		Encoding.default_internal = nil

		conn = MongoClient.new("localhost", 27017)
		set :db, conn.db('production')

		PushFlashBang.reset! settings.db
	end

	get '/' do
	 	haml :index, :format => :html5
	end

	def setup_things_for language
		@interval = Interval.new language, settings.db
		@schedule = Schedule.new language, settings.db
		@word_dataset = YAML.load_file("#{language}.yaml")['words']
		@sentence_dataset = YAML.load_file("#{language}.yaml")['sentences']
	end

	get '/:language/review' do |language|
		redirect "/" unless supported_languages.include? language

		setup_things_for language
		bco = PushFlashBang.new @interval, @schedule, @word_dataset, @sentence_dataset
		
		redirect "/#{language}/done" if bco.next_word_to_review.nil?

		haml :review, :format => :html5, :locals => { :language => language, :review =>  bco.next_word_to_review}
	end

	get '/:language/:word/review/success' do |language, word|
		redirect "/" unless supported_languages.include? language

		setup_things_for language

		bco = PushFlashBang.new @interval, @schedule, @word_dataset, @sentence_dataset
		bco.advance_word! word

		redirect "/#{language}/review"
	end

	get '/:language/:word/review/failure' do |language, word|
		redirect "/" unless supported_languages.include? language

		setup_things_for language
		bco = PushFlashBang.new @interval, @schedule, @word_dataset, @sentence_dataset
		bco.reset_word! word

		redirect "/#{language}/review"
	end

	get '/:language/done' do |language|
		redirect "/" unless supported_languages.include? language

		setup_things_for language

		haml :done, :format => :html5, :locals => {:language => language, :time_of_next_review => @schedule.time_of_next_review}
	end


	get '/languages' do
		json :supported_languages => supported_languages
	end

	get '/:language/review/pending' do |language|
		redirect "/" unless supported_languages.include? language

		setup_things_for language
		bco = PushFlashBang.new @interval, @schedule, @word_dataset, @sentence_dataset

		json :pending => bco.pending_review_count
	end

	get '/:language/:word' do |language, word|
		redirect "/" unless supported_languages.include? language

		words = YAML.load_file("#{language}.yaml")['words']
		sentences = YAML.load_file("#{language}.yaml")['sentences']
		item = words.select {|items| items['word'] == word}.first
		item = words.select {|items| items['meaning'] == word}.first if item.nil?
		item = sentences.select {|items| items['sentence'] == word}.first if item.nil?
		item = sentences.select {|items| items['meaning'] == word}.first if item.nil?
		
		puts word
		puts item

		item['pronunciation'] = PronunciationGuidance.chinese item['guide']

		json :language => language, :word => item
	end

	# run! if app_file == $0
# end