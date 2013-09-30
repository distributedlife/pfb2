# encoding: utf-8

class Character
	def initialize char
		@char = char
	end

	def value
		@char
	end

	def is_varation_of_a?
		["ā", "á", "ǎ", "à", "a"].include? @char
	end
	
	def is_varation_of_e?
		["e", "ē", "é", "ě", "è"].include? @char
	end
	
	def is_varation_of_i?
		["ī", "í", "ǐ", "ì", "i"].include? @char
	end
	
	def is_varation_of_o?
		["o", "ō", "ó", "ǒ", "ò"].include? @char
	end

	def is_varation_of_u?
		["u", "ū", "ú", "ǔ", "ù"].include? @char
	end

	def to_s
		@char
	end

	def ==(other_object)
		(value.to_s == other_object.to_s) or 
		(is_varation_of_a? and other_object.is_varation_of_a?) or
		(is_varation_of_e? and other_object.is_varation_of_e?) or
		(is_varation_of_i? and other_object.is_varation_of_i?) or
		(is_varation_of_o? and other_object.is_varation_of_o?) or
		(is_varation_of_u? and other_object.is_varation_of_u?)
	end
end