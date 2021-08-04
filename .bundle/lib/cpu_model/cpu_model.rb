# frozen_string_literal: true

require_relative 'control_scheme'
require_relative 'instruction_set'
require_relative 'control_mapping'
require_relative 'control_signal'

# model of the cpu, used to generate microcode data
# TODO: add ROM generation logic
class CPUModel
  TMP_FILE_LOCATION = '../../tmp/'
  DATA_FILE_LOCATION = '../../data/'
  VARS_TO_SAVE = %i[control_scheme instruction_set control_mapping].freeze

  attr_reader :binary_mapping

  def initialize(control_scheme, instruction_set, control_mapping)
    parse_cpu_config_files(control_scheme, instruction_set, control_mapping)
    puts 'Valid CPU Model initialized.'
    match_instructions_to_controls
    instructions_to_binary
    human_readable_save
  end

  def parse_cpu_config_files(control_scheme, instruction_set, control_mapping)
    @control_scheme = control_scheme.is_a?(ControlScheme) ? control_scheme : ControlScheme.new(control_scheme)
    @instruction_set = instruction_set.is_a?(InstructionSet) ? instruction_set : InstructionSet.new(instruction_set)
    # control_mapping needs to check against control scheme and instruction set for validation
    @control_mapping = if control_mapping.is_a? ControlMapping
                         control_mapping
                       else
                         ControlMapping.new(control_mapping, @control_scheme, @instruction_set)
                       end
  end

  def human_readable_save
    VARS_TO_SAVE.each do |var_name|
      File.write("#{TMP_FILE_LOCATION}#{var_name}_out.txt", instance_variable_get("@#{var_name}"))
    end
  end

  def match_instructions_to_controls
    @instruction_mapping = {}
    @instruction_set.instructions.each do |_opcode, instruction|
      @instruction_mapping[instruction] = @control_mapping.mappings[instruction.mnemonic].map do |specifier|
        ControlSignal.new(@control_scheme[specifier.signal_name], specifier.value)
      end
    end
    @instruction_mapping.each { |k, v| p "#{k}: #{v}" }
  end

  def instructions_to_binary
    @binary_mapping = {}
    @instruction_mapping.to_a.map do |kv_pair|
      instruction, control_signals = *kv_pair
      @binary_mapping[instruction_to_binary(instruction)] = control_signals_to_binary(control_signals)
    end
  end

  def instruction_to_binary(instruction)
    status_lines = Array.new(@control_scheme.status_lines)
    status_lines.map! { |status_line| ControlSignal.new(status_line, get_status_line_value(status_line, instruction)) }
    status_signals_to_binary(status_lines)
  end

  def control_signals_to_binary(control_signals)
    control_word = '0' * @control_scheme.control_word_size
    control_signals.each do |signal|
      signal_start_pos = @control_scheme.signal_start(signal)
      signal_end_pos = @control_scheme.signal_end(signal)
      control_word[signal_start_pos..signal_end_pos] = signal.to_binary_string
    end
    control_word
  end

  def get_status_line_value(status_line, instruction)
    if status_line.name == 'OPCODE'
      instruction.expanded? ? instruction.expanded_opcode : instruction.opcode
    elsif status_line.name == 'EXPANDED_INSTRUCTION_SET' && !instruction.expanded?
      0
    elsif @instruction_mapping[instruction].map(&:name).include?(status_line.name)
      status_val_from_control_signal(status_line, instruction)
    end
  end

  def status_val_from_control_signal(status_line, instruction)
    status_line_index = @instruction_mapping[instruction].find_index { |signal| signal.name.eql? status_line.name }
    @instruction_mapping[instruction][status_line_index].signal_value
  end

  def status_signals_to_binary(status_signals)
    status_word = '0' * @control_scheme.rom_address_bits
    status_signals.each do |signal|
      signal_start = @control_scheme.signal_start(signal.signal_line)
      signal_end = @control_scheme.signal_end(signal.signal_line)
      status_word[signal_start..signal_end] = signal.to_binary_string
    end
    status_word
  end
end

model = CPUModel.new('../../data/control_structure.txt', '../../data/cpu.isa', '../../data/control_mapping.txt')
model.binary_mapping.each { |status_word, control_word| p "#{status_word}: #{control_word}" }
