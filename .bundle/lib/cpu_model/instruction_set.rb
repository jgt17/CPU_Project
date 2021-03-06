# frozen_string_literal: true

require 'parseconfig'
require 'set'
require_relative 'configurable'
require_relative '../validation/instruction_set_validation'
require_relative 'instruction'
require_relative 'unused_opcode_util'

# models the instruction set of the CPU
class InstructionSet
  include Configurable
  include InstructionSetValidation
  include UnusedOpcodeUtil

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
  attr_reader :expansion_opcodes

  def include?(str)
    @instructions.key?(str) || @instructions.values.find_index { |instruction| instruction.mnemonic.eql? str }
  end

  def [](id)
    return @instructions[id] if @instructions.key?(id)

    instruction_list = @instructions.values
    index = instruction_list.find_index { |instruction| instruction.mnemonic.eql? id }
    index.nil? ? nil : instruction_list[index]
  end

  def expansion_mnemonic(num_args = 0, code = nil)
    "EXPANSION #{Instruction.parse_opcode(code)} #{'[dummy] ' * num_args.to_i}".strip
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
      add_instruction(code, expansion_mnemonic(num_args, code))
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

  def format_expansion_opcodes
    @expansion_opcodes.to_a.map { |kv_pair| "#{kv_pair[0]}: #{kv_pair[1]} args" }.join("\n")
  end

  def format_instructions
    @instructions.values.map(&:to_s).sort.join "\n"
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
    @unused_opcodes = find_unused_opcodes(@instructions, @expansion_opcodes, @word_size)
    super
  end
end
