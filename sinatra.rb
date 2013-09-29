# encoding: utf-8

require 'sinatra'
require 'sinatra/json'
require 'haml'
require 'mongo'
require 'json/ext'
require './lib/boom_crash_opera'
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

		bco = BoomCrashOpera.new settings.db
		bco.setup!
	end

	get '/' do
	 	haml :index, :format => :html5
	end

	get '/:language/review' do |language|
		redirect "/" unless supported_languages.include? language

		bco = BoomCrashOpera.new settings.db
		review = bco.next_revision(language)

		if review.nil?
			bco.learn_next_word language
		end
		
		review = bco.next_revision(language)
		redirect "/#{language}/done" if review.nil?

		haml :review, :format => :html5, :locals => { :language => language, :review =>  review}
	end

	get '/:language/:word/review/success' do |language, word|
		redirect "/" unless supported_languages.include? language

		bco = BoomCrashOpera.new settings.db
		bco.schedule_next_review! language, word

		redirect "/#{language}/review"
	end

	get '/:language/:word/review/failure' do |language, word|
		redirect "/" unless supported_languages.include? language

		bco = BoomCrashOpera.new settings.db
		bco.reset_schedule! language, word

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