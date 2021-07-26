# frozen_string_literal: true

require 'parseconfig'
require 'set'
require_relative 'configurable'
require_relative 'instruction_set_validation'
require_relative 'instruction'

# models the instruction set of the CPU
class InstructionSet
  include Configurable
  include InstructionSetValidation
  REQUIRED_PARAMETERS = %i[isa_name word_size max_args].freeze
  OPTIONAL_PARAMETERS = %i[].freeze
  STRING_PARAMETERS = %i[isa_name].freeze

  DATA_PARAMETERS = %i[groups expansion_opcodes instructions].freeze
  DATA_TYPE = Hash
  GENERATED_DATA = %i[unused_opcodes instruction_conflicts].freeze

  attr_reader :groups
  attr_reader :instructions
  attr_reader :isa_name
  attr_reader :word_size
  attr_reader :max_args

  private

  def add_groups(raw_groups)
    return if raw_groups.nil?

    raw_groups.each do |key, value|
      group = extract_hash(value).freeze
      names = key.split(/[, ]+/)
      names.each do |name|
        @groups[name] = group if valid_group?(name, group)
      end
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

  def extract_hash(string)
    hash = {}
    string.delete('{} ').split(',').map { |kv_str| kv_str.split(/:/) }.each { |pair| hash[pair[0]] = pair[1] }
    hash
  end

  def format_instructions
    @instructions.values.sort.map(&:to_s).join "\n"
  end

  def format_unused_opcodes
    @instructions.keys
    ''
  end
end
