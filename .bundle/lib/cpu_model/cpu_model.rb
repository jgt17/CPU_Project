# frozen_string_literal: true

require_relative 'control_scheme'
require_relative 'instruction_set'
require_relative 'control_mapping'

# model of the cpu, used to generate microcode data
# TODO: add ROM generation logic
class CPUModel
  TMP_FILE_LOCATION = '../../tmp/'
  DATA_FILE_LOCATION = '../../data/'
  VARS_TO_SAVE = %i[control_scheme instruction_set control_mapping].freeze


  def initialize(control_scheme, instruction_set, control_mapping)
    @control_scheme = control_scheme.is_a?(ControlScheme) ? control_scheme : ControlScheme.new(control_scheme)
    @instruction_set = instruction_set.is_a?(InstructionSet) ? instruction_set : InstructionSet.new(instruction_set)
    @control_mapping = control_mapping.is_a?(ControlMapping) ? control_mapping : ControlMapping.new(control_mapping, @control_scheme, @instruction_set)
    puts @control_mapping.mappings
    puts 'Valid CPU Model initialized.'
    human_readable_save
  end

  def human_readable_save
    VARS_TO_SAVE.each do |var_name|
      File.write("#{TMP_FILE_LOCATION}#{var_name}_out.txt", instance_variable_get("@#{var_name}"))
    end
  end
end

CPUModel.new('../../data/control_structure.txt', '../../data/cpu.isa', '../../data/control_mapping.txt')
