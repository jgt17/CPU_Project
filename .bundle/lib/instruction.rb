# frozen_string_literal: true

# representation of an instruction the CPU supports
class Instruction
  include Comparable
  EXPANDED_ISA_OPCODES = [].freeze

  attr_reader :opcode
  attr_reader :mnemonic
  attr_reader :expanded_opcode
  attr_reader :args_expected

  def initialize(opcode, mnemonic, word_size = 8)
    opcode, expanded_opcode = opcode.split(/[, ]+/)
    @opcode = parse_opcode(opcode)
    @mnemonic = mnemonic
    @word_size = word_size
    @expanded_opcode = parse_opcode(expanded_opcode)
    @args_expected = count_args_expected
    freeze
  end

  def <=>(other)
    cmp = (@opcode <=> other.opcode)
    cmp.zero? ? @expanded_opcode <=> other.expanded_opcode : cmp
  end

  def binary_opcode
    opcode.to_s(2).rjust(@word_size, '0') + (@expanded_opcode.nil? ? '' : @expanded_opcode.to_s.rjust(@word_size, '0'))
  end

  def hex_opcode
    hex = opcode.to_s(16).rjust(@word_size / 4, '0')
    @expanded_opcode.nil? ? hex : hex + @expanded_opcode.to_s.rjust(@word_size / 4, '0')
  end

  def spaced_binary_opcode
    binary_opcode.gsub(/..../, '\0 ').strip
  end

  def to_s
    "#{spaced_binary_opcode}: #{@mnemonic}"
  end

  def self.parse_opcode(code)
    code = code.delete('^0-9').to_i(code.match?(/[^01]/) ? 16 : 2) if code.is_a? String
    code
  end

  private

  def count_args_expected
    @mnemonic.scan(/\[[^\[\]]+\]/).length
  end

  def parse_opcode(code)
    self.class.parse_opcode(code)
  end
end
