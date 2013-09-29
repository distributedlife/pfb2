class Schedule
	def name
		'schedule'
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

	def reset!
		@db.drop_collection name
	end

	def add! language, what, interval
		collection.insert({:language => language, :what => what, :when => Time.now, :interval => interval })
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

	def update! language, what, interval
		collection.update({:language => language, :what => what}, {"$set" => {:when => Time.now + interval, :interval => interval }})
	end

	def next language
		collection.find({:language => language, :when => {"$lte" => Time.now }}).sort({:when => ascending}).first
	end

	def current_interval language, what
		collection.find({:language => language, :what => what}).first['interval']
	end

	def in_shedule language, what
		collection.find({:language => language, :what => what}).count > 0
	end

	def transition language, old_interval, new_interval
		collection.find({:language => language, :interval => old_interval}).to_a.each do |schedule|
			collection.update({:_id => schedule['_id']}, {"$set" => {:interval => new_interval }})
		end
	end
end