# frozen_string_literal: true

require 'parseconfig'

# models the instruction set of the CPU
class InstructionSet
  attr_reader :groupings

  def initialize(isa)
    initialize_from_file(isa) if isa.is_a? String
    raise 'Can only build a Instruction Set from a file right now.' unless isa.is_a? String
  end

  private

  # parses a control scheme specification from a file and initializes it
  def initialize_from_file(filename)
    valid_filename?(filename)
    isa = ParseConfig.new(filename)
    add_groupings(isa.params['Instruction Groups'])
    # validate_instructions
  end

  def add_groupings(raw_groups)
    @groups = {}
    return if raw_groups.nil?

    raw_groups.each do |key, value|
      group = extract_hash(value).freeze
      names = key.split(/[, ]+/)
      names.each do |name|
        @groups[name] = group if valid_group?(name, group)
      end
    end
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

  def valid_filename?(filename)
    raise "Expected a filename: #{filename}" unless filename.is_a? String
    raise "File does not exist: #{filename}" unless File.exist?(filename)

    true
  end
end

InstructionSet.new('../data/cpu.isa')
