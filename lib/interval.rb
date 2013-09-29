class Interval
	def language
		return @language
	end

	def name
		'interval'
	end

	def collection
		@db[name]
	end

	def initialize db
		@db = db
	end

	def create!
		@db.create_collection(name) unless @db.collection_names.include? name
	end

	def empty?
		collection.count == 0
	end

	def ascending
		1
	end

	def descending
		-1
	end

	def reset!
		@db.drop_collection name
	end

	def first
		collection.find({:interval => {"$gt" => 0}}).sort({:interval => ascending}).to_a.first
	end

	def next interval
		collection.find({:interval => {"$gt" => interval}}).sort({:interval => ascending}).to_a.first['interval']
	end

	def prior interval
		collection.find({:interval => {"$lt" => interval}}).sort({:interval => ascending}).to_a.last['interval']
	end

	def setup_for_language? language
		collection.find({:language => language}).count != 0
	end

	def setup_for_language language
		[5.seconds, 25.seconds, 2.minutes, 10.minutes, 1.hour, 5.hours, 1.day, 5.days, 25.days, 4.months, 2.years].each do |interval|
			collection.insert({:interval => interval, :sequence => 0, :language => language})
		end
	end

	def add_failure language, interval
		change = sequence(language, interval) >= 0 ? "$set" : "$inc"
		collection.update({:language => language, :interval => interval}, {change => {:sequence => -1 }})
	end

	def add_success language, interval
		change = sequence(language, interval) <= 0 ? "$set" : "$inc"
		collection.update({:language => language, :interval => interval}, {change => {:sequence => 1 }})
	end

	def sequence language, interval
		collection.find_one({:language => language, :interval => interval})['sequence']
	end

	def replace language, current_interval, new_interval
		collection.update({:language => language, :interval => current_interval}, {"$set" => {:interval => new_interval, :sequence => 0 }})
	end
end
