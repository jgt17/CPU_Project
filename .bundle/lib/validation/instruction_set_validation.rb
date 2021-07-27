# frozen_string_literal: true

require_relative 'config_validation'

# methods for validating an instruction set
module InstructionSetValidation
  DATA_PARAMETERS = %i[groups instructions].freeze
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

  # groups validated by valid_group? during construction
  def validate_groups
    true
  end

  def validate_expansion_opcodes
    pass = true
    @expansion_opcodes.each do |code, num_args|
      pass = warn "Expansion opcode #{code.to_s(2).rjust(@word_size, '0')} out of bounds" unless opcode_in_bounds? code
      unless num_args.is_a?(Integer) && !num_args.negative? && num_args <= 2
        pass = warn "Invalid number of args (#{num_args}) for expansion opcode #{code}"
      end
    end
    pass
  end

  def validate_instructions
    pass = true
    @instructions.each_value do |instruction|
      pass = instruction_in_bounds(instruction) && num_args_in_bounds(instruction) && pass
    end
    @instruction_conflicts.each_value do |instructions|
      instructions.each do |instruction|
        pass = warn "Instruction #{instruction} conflicts with #{@instructions[instruction.binary_opcode]}"
      end
    end
    pass
  end

  def instruction_in_bounds(instruction)
    pass = true
    unless opcode_in_bounds? instruction.opcode
      pass = warn "Opcode '#{instruction.opcode}' out of bounds for instruction #{instruction}"
    end
    e_opcode = instruction.expanded_opcode
    unless e_opcode.nil? || opcode_in_bounds?(e_opcode)
      pass = warn "Expansion opcode '#{e_opcode}' out of bounds for instruction #{instruction}"
    end
    pass
  end

  def num_args_in_bounds(instruction)
    num_args = instruction.args_expected
    unless num_args.is_a?(Integer) && !num_args.negative? && num_args <= 2
      return warn "Invalid number of args (#{num_args}) for instruction #{instruction}"
    end

    true
  end

  def opcode_in_bounds?(opcode)
    opcode >= 0 && opcode < 2**@word_size
  end

  def validate_expanded_instructions
    pass = true
    @instructions.each_value do |instruction|
      pass = properly_expanded(instruction) && proper_num_args(instruction) && pass
    end
    pass
  end

  def properly_expanded(instruction)
    pass = true
    unless instruction.expanded_opcode.nil? || @expansion_opcodes.key?(instruction.opcode)
      pass = warn "#{instruction} should not have an expansion code"
    end
    if @expansion_opcodes.key?(instruction.opcode) && instruction.expanded_opcode.nil?
      pass = warn "#{instruction} should have an expansion code"
    end
    pass
  end

  def proper_num_args(instruction)
    pass = true
    proper_arg_number = @expansion_opcodes[instruction.opcode]
    unless instruction.expanded_opcode.nil? || (instruction.args_expected == proper_arg_number)
      pass = warn "#{instruction} has #{instruction.args_expected} arguments instead of #{proper_arg_number}"
    end
    pass
  end

  def additional_hard_checks
    validate_expanded_instructions
  end

  def additional_soft_checks
    true
  end
end
