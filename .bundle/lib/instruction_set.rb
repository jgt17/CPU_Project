# frozen_string_literal: true

require 'parseconfig'
require_relative 'configurable'

# models the instruction set of the CPU
class InstructionSet
  include Configurable
  REQUIRED_PARAMETERS = %i[isa_name word_size].freeze
  OPTIONAL_PARAMETERS = %i[].freeze
  STRING_PARAMETERS = %i[isa_name].freeze

  DATA_PARAMETERS = %i[groups instructions].freeze
  DATA_TYPE = Hash
  GENERATED_DATA = %i[unused_opcodes].freeze

  attr_reader :groups
  attr_reader :instructions
  attr_reader :isa_name
  attr_reader :word_size

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

  def add_instructions(raw_instructions)
    group_marker = /[, ]+/
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
    opcode = opcode.to_i(opcode.include?('\x') ? 16 : 2) # accept binary and hex opcodes
    @instructions[opcode] = mnemonic # TODO: implement instruction class
  end

  def extract_hash(string)
    hsh = {}
    string.delete('{} ').split(',').map { |kv_str| kv_str.split(/:/) }.each { |pair| hsh[pair[0]] = pair[1] }
    hsh
  end

  def valid_group?(name, group)
    pass = true
    pass = warn "Group name must be a single repeated character: #{name}" unless name.squeeze.length == 1
    group.each_key do |key|
      pass = warn "Group name #{name} does not match the length of instance #{key}" unless name.size == key.size
      pass = warn "Group instance #{key} of group #{name} must contain only 0s and 1s" if key.match?(/[^01]+/)
    end
    abort "Error Processing group #{name}" unless pass

    pass
  end

  def format_instructions
    @instructions.sort.map { |op, mem| "#{op.to_s(2).rjust(@word_size, '0').insert(4, ' ')}: #{mem}" }.join "\n"
  end

  def format_unused_opcodes
    @instructions.keys
    ''
  end
end

b = InstructionSet.new('../data/cpu.isa')
puts b