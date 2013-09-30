# encoding: utf-8
require './lib/word'
require './lib/character'

class PronunciationGuidance
	def self.get_helper_array
	    YAML.load_file("chinese_pronunciation_guidance.yaml").sort_by {|x| x[0].each_char.count}.reverse
  	end

  	def self.resolve_helper_text_from_variations variations, word, default
		variations.each do |variation|
			skip_variation = false

			variation['when'].each do |condition|
				break if skip_variation

				if condition['rule'] == 'previous'
					skip_variation = true unless condition['value'].include? word.previous_char.to_s
				end
				if condition['rule'] == 'previousprevious'
					skip_variation = true if word.char_at(word.offset - 2).nil?
					skip_variation = true unless condition['value'].include? word.char_at(word.offset - 2).to_s
				end
				if condition['rule'] == 'next'
					skip_variation = true unless condition['value'].include? word.next_char.to_s
				end
				if condition['rule'] == 'nextnext'
					skip_variation = true if word.char_at(word.offset + 2).nil?
					skip_variation = true unless condition['value'].include? word.char_at(word.offset + 2).to_s
				end
			end	

			next if skip_variation

			return variation['use']
		end

		return default
  	end

  	def self.is_variation_allowed helper, variations
  		helper.length == 1 && variations
  	end

	def self.chinese pinyin
		string = []

		word = Word.new pinyin
	    while word.not_at_end do
	        matched = false
	        updated = false

	        get_helper_array.select {|i| (word.offset + i[0].each_char.count) <= word.length }.each do |key, helper_text|
				helper = Word.new key

		        default = helper_text['default']
		        variations = helper_text['variations']

				helper.multibyte_array.map{|e| Character.new(e) }.each_with_index do |element, i|
					break unless word.char_at(word.offset + i) == element

					helper.move_to(i)

		        	if is_variation_allowed(helper, variations)
	        			string << resolve_helper_text_from_variations(variations, word, default)

	    		        word.move_to_next

	    		        matched = true
	    		        updated = true
	  		            break
			        end

				  	next if i < (helper.length - 1)

				  	matched = true if helper.at_last_character
			    end

			    if matched and !updated
			        string << default

			        word.shift_right helper.length
			    end

			    break if matched
			end

			unless matched 
			    string << word.char_at(word.offset)

			    word.move_to_next
			end
	    end

	    string.compact.join(", ")
	end
end