# frozen_string_literal: true

require_relative 'control_scheme'
require_relative 'instruction_set'
require_relative 'control_mapping'

# model of the cpu, used to generate microcode data
class CPUModel
  def initialize(control_scheme, instruction_set, control_mapping)
    @control_scheme = control_scheme.is_a?(ControlScheme) ? control_scheme : ControlScheme.new(control_scheme)
    @instruction_set = instruction_set.is_a?(InstructionSet) ? instruction_set : InstructionSet.new(instruction_set)
    @control_mapping = control_mapping.is_a?(ControlMapping) ? control_mapping : ControlMapping.new(control_mapping, @control_scheme, @instruction_set)
    puts @control_mapping
    human_readable_save
  end

  def human_readable_save
    File.write('../../tmp/control_lines.txt', @control_scheme)
    File.write('../../tmp/instruction_set.txt', @instruction_set)
  end
end

CPUModel.new('../../data/control_structure.txt', '../../data/cpu.isa', '../../data/control_mapping.txt')
