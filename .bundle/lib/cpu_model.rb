# frozen_string_literal: true

require_relative 'control_scheme'
require_relative 'instruction_set'

# model of the cpu, used to generate microcode data
class CPUModel
  def initialize(control_scheme, instruction_set)
    @control_scheme = control_scheme.is_a?(ControlScheme) ? control_scheme : ControlScheme.new(control_scheme)
    @instruction_set = instruction_set.is_a?(InstructionSet) ? instruction_set : InstructionSet.new(instruction_set)
    human_readable_save
  end

  def human_readable_save
    File.write('../tmp/control_lines.txt', @control_scheme)
    File.write('../tmp/instruction_set.txt', @instruction_set)
  end
end

CPUModel.new('../data/control_structure.txt', '../data/cpu.isa')
