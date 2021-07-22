# frozen_string_literal: true

# Defines the structure of ROMs used for microcode and programs
class Rom
  attr_reader :bit_width
  attr_reader :num_addresses

  def initialize(bit_width, num_addresses)
    @bit_width = bit_width
    @num_addresses = num_addresses
  end
end
