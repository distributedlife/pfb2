# encoding: utf-8

require 'sinatra'
require 'sinatra/json'
require 'haml'
require 'mongo'
require 'json/ext'
require './lib/boom_crash_opera'
require './lib/interval'
require './lib/schedule'
require './routes/api_routes'

# class BoomCrashOpera < Sinatra::Base
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

		BoomCrashOpera.reset! conn.db
	end

	get '/' do
	 	haml :index, :format => :html5
	end



	get '/:language/review' do |language|
		redirect "/" unless supported_languages.include? language

		interval = Interval.new language, settings.db
		schedule = Schedule.new language, settings.db
		dataset = YAML.load_file('characters.yaml')[language]
		bco = BoomCrashOpera.new interval, schedule, dataset

		if bco.next_revision.nil?
			bco.learn_next_word
		end
		
		review = bco.next_revision
		redirect "/#{language}/done" if review.nil?

		haml :review, :format => :html5, :locals => { :language => language, :review =>  review}
	end

	get '/:language/:word/review/success' do |language, word|
		redirect "/" unless supported_languages.include? language

		interval = Interval.new language, settings.db
		schedule = Schedule.new language, settings.db
		dataset = YAML.load_file('characters.yaml')[language]
		bco = BoomCrashOpera.new interval, schedule, dataset

		bco.schedule_next_review! word

		redirect "/#{language}/review"
	end

	get '/:language/:word/review/failure' do |language, word|
		redirect "/" unless supported_languages.include? language

		interval = Interval.new language, settings.db
		schedule = Schedule.new language, settings.db
		dataset = YAML.load_file('characters.yaml')[language]
		bco = BoomCrashOpera.new interval, schedule, dataset

		bco.reset_schedule! word

		redirect "/#{language}/review"
	end



	get '/:langauge/done' do |language|
		haml :done, :format => :html5, :locals => {:language => language}
	end

	get '/languages' do
		json :supported_languages => supported_languages
	end

	get '/:langauge/:word' do |language, word|
		redirect "/" unless supported_languages.include? language

		set = YAML.load_file('characters.yaml')[language]

		json :language => language, :word => set.select {|items| items['word'] == word}.first
	end

	# run! if app_file == $0
# end