# encoding: utf-8
require './lib/character'

class Word
  def initialize word
  	@word = word
  	@offset = 0
  end

  def move_to offset
  	@offset = offset
  end

  def offset
  	@offset
  end

  def move_to_next
  	@offset = @offset + 1
  end

  def shift_right amount
  	@offset = @offset + amount
  end

  def length
  	@word.each_char.count
  end

  def multibyte_array
  	@word.split ""
  end

  def current_char
  	multibyte_array[@offset]
  end

  def next_char
  	return nil if at_last_character

  	Character.new multibyte_array[@offset + 1]
  end

  def previous_char
  	return nil if at_first_character

  	Character.new multibyte_array[@offset - 1]
  end

  def char_at i
  	return nil if i < 0
  	return nil if i >= length

  	Character.new multibyte_array[i]
  end

  def at_first_character
  	@offset == 0
  end

  def at_last_character
  	@offset == (length - 1)
  end

  def not_at_end
  	offset < length
  end

  def to_s
    @word
  end
end