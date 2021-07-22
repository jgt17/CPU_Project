# frozen_string_literal: true

# model of the cpu, used to generate microcode data
class CPUModel
  def initialize(control_scheme, instruction_set)
    @control_scheme = control_scheme.is_a? ControlScheme ? control_scheme : ControlScheme.new(control_scheme)
    @instruction_set = instruction_set.is_a? InstructionSet ? instruction_set : InstructionSet.new(instruction_set)
  end
end
