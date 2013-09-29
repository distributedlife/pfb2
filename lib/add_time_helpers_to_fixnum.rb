class Fixnum
	def second
		self.seconds
	end

	def seconds
		self
	end

	def minute
		self.seconds * 60
	end

	def minutes
		self.minute
	end

	def hour
		self.minutes * 60
	end

	def hours
		self.hour
	end

	def day
		self.hours * 24
	end

	def days
		self.day
	end

	def month
		self.day * 30
	end

	def months
		self.month
	end

	def year
		self.day * 365
	end

	def years
		self.day * 365
	end
end