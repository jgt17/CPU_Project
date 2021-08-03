# frozen_string_literal: true

require_relative 'configurable'
require_relative 'signal_specifier'
require_relative '../validation/control_mapping_validation'
require_relative 'control_signal_expression_parser'

# defines the mapping of opcodes to control signals
class ControlMapping
  include Configurable
  include ControlMappingValidation

  REQUIRED_PARAMETERS = %i[name].freeze
  OPTIONAL_PARAMETERS = %i[].freeze
  STRING_PARAMETERS = %i[name].freeze
  INT_PARAMETERS = %i[].freeze

  DATA_PARAMETERS = %i[substitutions mappings control_signal_expressions].freeze
  DATA_TYPE = Hash
  GENERATED_DATA = %i[control_scheme instruction_set].freeze

  attr_reader :name
  attr_reader :mappings

  def initialize(config, control_scheme, instruction_set)
    @control_scheme = control_scheme
    @instruction_set = instruction_set
    super(config)
  end

  private

  def add_substitutions(raw_substitutions)
    @substitutions = {}
    raw_substitutions.each do |signal, value_mapping|
      @substitutions[signal] = extract_hash(value_mapping)
    end
  end

  def add_mappings(raw_mappings)
    @mappings = {}
    raw_mappings.each do |mnemonic, signals|
      @mappings[mnemonic] = extract_array(signals)
      @mappings[mnemonic].map! do |signal|
        sig_name, sig_value = signal.delete(']').split('[')
        sig_value ||= 1
        @substitutions.each { |name| break sig_value = @substitutions[sig_name][sig_value] if name == sig_name }
        SignalSpecifier.new(sig_name, sig_value)
      end
    end
    @instruction_set.expansion_opcodes.each { |code, args| @mappings[@instruction_set.expansion_mnemonic(args, code)] = [] }
  end

  def add_control_signal_expressions(raw_expressions)
    ControlSignalExpressionParsing.expansion_opcodes = @instruction_set.expansion_opcodes
    raw_expressions.to_a.reverse_each do |kv_pair|
      signal_name, expression = *kv_pair
      @mappings.each do |mnemonic, signals|
        instruction = @instruction_set[mnemonic]
        next unless instruction

        signals.prepend(SignalSpecifier.new(signal_name,
                                            ControlSignalExpressionParsing.parse_cse(expression, instruction)))
      end
    end
  end

  def format_mappings
    @mappings.map { |mnemonic, signals| "'#{mnemonic}': [#{signals.map(&:to_s).join(', ')}]" }.join("\n")
  end
end
