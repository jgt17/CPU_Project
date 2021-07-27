# frozen_string_literal: true

require 'parseconfig'
require 'set'
require_relative 'configurable'
require_relative '../validation/instruction_set_validation'
require_relative 'instruction'

# models the instruction set of the CPU
class InstructionSet
  include Configurable
  include InstructionSetValidation

  REQUIRED_PARAMETERS = %i[isa_name word_size max_args].freeze
  OPTIONAL_PARAMETERS = %i[].freeze
  STRING_PARAMETERS = %i[isa_name].freeze
  INT_PARAMETERS = %i[word_size max_args].freeze

  DATA_PARAMETERS = %i[groups expansion_opcodes instructions].freeze
  DATA_TYPE = Hash
  GENERATED_DATA = %i[unused_opcodes instruction_conflicts].freeze

  attr_reader :groups
  attr_reader :instructions
  attr_reader :isa_name
  attr_reader :word_size
  attr_reader :max_args

  def include?(str)
    @instructions.key?(str) || @instructions.values.find_index { |instruction| instruction.mnemonic.eql? str }
  end

  private

  def add_groups(raw_groups)
    return if raw_groups.nil?

    raw_groups.each do |key, value|
      group = extract_hash(value).freeze
      names = key.split(/[, ]+/)
      names.each { |name| @groups[name] = group if valid_group?(name, group) }
    end
  end

  def add_expansion_opcodes(raw_expandable)
    @expansion_opcodes = {}
    raw_expandable.each do |code, num_args|
      @expansion_opcodes[Instruction.parse_opcode(code)] = num_args.to_i
    end
  end

  def add_instructions(raw_instructions)
    @instruction_conflicts = {}
    group_marker = /:\s+/
    raw_instructions.each do |opcode, mnemonic|
      mnemonic.gsub!(/[\s]*#[\s\S]*/, '') # remove comments
      next add_instruction(opcode, mnemonic) unless opcode.match(group_marker)

      add_instruction_group(opcode.split(group_marker)[1], mnemonic)
    end
  end

  def add_instruction_group(pattern, mnemonic)
    first = nil
    index = pattern.length
    @groups.each_key do |group|
      next unless pattern.include?(group) && pattern.index(group) < index

      first = group
      index = pattern.index(group)
    end
    return add_instruction(pattern, mnemonic) unless first

    @groups[first].each { |bits, arg| add_instruction_group(pattern.sub(first, bits), mnemonic.sub(/{\w+}/, arg)) }
  end

  def add_instruction(opcode, mnemonic)
    instruction = Instruction.new(opcode, mnemonic, @word_size)
    if @instructions.key? instruction.binary_opcode
      @instruction_conflicts[instruction.binary_opcode] ||= Set.new
      @instruction_conflicts[instruction.binary_opcode].add instruction
    else
      @instructions[instruction.binary_opcode] = instruction
    end
  end

  def format_instructions
    @instructions.values.sort.map(&:to_s).join "\n"
  end

  def format_unused_opcodes
    ranges = find_opcode_ranges(@unused_opcodes)
    ranges.map { |range| format_range(*range) }.join("\n")
  end

  def format_range(start_opcode, end_opcode)
    rel_opcode = @expansion_opcodes.include?(start_opcode.opcode) ? :expanded_opcode : :opcode
    range_size = end_opcode.send(rel_opcode) - start_opcode.send(rel_opcode)
    return "#{start_opcode.hex_opcode}-#{end_opcode.hex_opcode}" if range_size > 1

    range_size.zero? ? start_opcode.hex_opcode : "#{start_opcode.hex_opcode}\n#{end_opcode.hex_opcode}"
  end

  def post_validation_setup
    find_unused_opcodes
    super
  end

  def find_unused_opcodes
    used_opcodes = @instructions.keys + @expansion_opcodes.keys.map { |k| Instruction.binary_opcode(k, @word_size) }
    unused_opcodes = possible_opcodes - used_opcodes
    @unused_opcodes = unused_opcodes.map { |code| Instruction.new(code, 'dummy_instruction') }
  end

  def possible_opcodes
    opcodes = []
    ([''] + @expansion_opcodes.keys).each do |expansion_code|
      prefix = expansion_code.is_a?(Integer) ? Instruction.binary_opcode(expansion_code, @word_size) + ' ' : ''
      opcodes += (0...2**@word_size).map { |i| prefix + Instruction.binary_opcode(i, @word_size) }
    end
    opcodes
  end

  def find_opcode_ranges(instruction_array)
    instruction_array = instruction_array.sort
    ranges = [[]]
    previous = instruction_array[0]
    instruction_array.each do |instruction|
      ranges[-1].append previous unless instruction.next_from?(previous)
      previous = instruction
      ranges.append [instruction] if ranges[-1]&.size == 2
    end
    ranges[-1].append instruction_array[-1] unless ranges[-1].size == 2
    ranges
  end
end
