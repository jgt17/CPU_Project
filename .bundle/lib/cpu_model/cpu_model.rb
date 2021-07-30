# frozen_string_literal: true

require_relative 'control_scheme'
require_relative 'instruction_set'
require_relative 'control_mapping'

# model of the cpu, used to generate microcode data
# TODO: add auto-generated control signals (refactor add_pc_incr_amount from control_mapping)
# TODO: add check that each control signal appears once per instruction
# TODO: add ROM generation logic
class CPUModel
  def initialize(control_scheme, instruction_set, control_mapping)
    @control_scheme = control_scheme.is_a?(ControlScheme) ? control_scheme : ControlScheme.new(control_scheme)
    @instruction_set = instruction_set.is_a?(InstructionSet) ? instruction_set : InstructionSet.new(instruction_set)
    @control_mapping = control_mapping.is_a?(ControlMapping) ? control_mapping : ControlMapping.new(control_mapping, @control_scheme, @instruction_set)
    human_readable_save
  end

  def human_readable_save
    File.write('../../tmp/control_lines.txt', @control_scheme)
    File.write('../../tmp/instruction_set.txt', @instruction_set)
    File.write('../../tmp/instruction_control_mapping.txt', @control_mapping)
  end
end

CPUModel.new('../../data/control_structure.txt', '../../data/cpu.isa', '../../data/control_mapping.txt')
