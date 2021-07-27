# frozen_string_literal: true

# Describes the control signals used in the processor
class SignalLine
  include Comparable

  attr_reader :name
  attr_reader :stage
  attr_reader :bit_position
  attr_reader :size
  attr_reader :top_bit_position
  attr_reader :values

  def initialize(*args)
    @name, @stage, @bit_position, @size = *args
    @size = 1 if @size.nil?
    @top_bit_position = @bit_position + @size - 1
    raise 'Invalid control signal' unless validate

    @values = %w[0 1].repeated_permutation(size).map(&:join).sort
    freeze
  end

  def <=>(other)
    @bit_position <=> other.bit_position
  end

  def value_in_bounds?(val)
    val = val.to_i unless val.is_a? Integer
    @values.size > val && !val.negative?
  end

  def [](val)
    @values[val]
  end

  private

  def validate
    return false unless @name.is_a? String
    return false unless valid_int(@stage) || @stage.nil? # status lines are the same for every stage
    return false unless valid_int(@bit_position)
    return false unless valid_int(@size)

    true
  end

  def valid_int(int)
    int.is_a?(Integer) && !int.negative?
  end
end
