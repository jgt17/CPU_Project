# frozen_string_literal: true

require 'set'

require_relative 'config_validation'

# methods for validating a control mapping
# noinspection RubyInstanceMethodNamingConvention
module ControlMappingValidation
  include ConfigValidation

  def validate_substitutions
    @substitutions.to_a.reduce(true) do |memo, sub|
      unless @control_scheme.control_signal?(sub[0])
        next warn "Mapping: Unknown substitution control signal name: #{sub[0]}"
      end

      values_in_bounds?(@control_scheme[sub[0]], sub[1]) && memo
    end
  end

  def validate_mappings
    @mappings.to_a.reduce(true) do |memo, mapping|
      mnemonic, signals = *mapping
      memo = no_duplicate_signals?(signals, mnemonic) && memo
      all_signals_valid?(signals) && memo
    end
  end

  def all_signals_valid?(signal_specifiers)
    signal_specifiers.reduce(true) do |memo2, signal|
      signal_name, value = *signal.specify
      unless @control_scheme.control_signal?(signal_name)
        next warn "Mapping: Unknown control signal name: #{signal_name}"
      end

      value_in_bounds?(@control_scheme[signal_name], value, mnemonic) && memo2
    end
  end

  # expressions auto-generate signals, which are then validated by validate_mappings
  def validate_control_signal_expressions
    true
  end

  def additional_hard_checks
    all_instructions_specified?
  end

  def additional_soft_checks
    extra_instructions_specified?
  end

  def values_in_bounds?(control_signal, values, mnemonic = 'SUBSTITUTIONS')
    values.each_value.reduce(true) { |memo, val| value_in_bounds?(control_signal, val, mnemonic) && memo }
  end

  def value_in_bounds?(control_signal, value, mnemonic)
    unless control_signal.value_in_bounds?(value)
      return warn "Mapping: Value #{value} out of range for control signal #{control_signal.name} of '#{mnemonic}'"
    end

    true
  end

  def all_instructions_specified?
    @instruction_set.instructions.sort.reduce(true) do |memo, kv|
      mappings.key?(kv[1].mnemonic) ? memo : warn("Mapping: Missing control definition of '#{kv[1].mnemonic}'!")
    end
  end

  def extra_instructions_specified?
    !(mappings.each_key.reduce(true) do |memo, mnemonic|
      if @instruction_set.include?(mnemonic) ||
          @instruction_set.expansion_opcodes.key?(mnemonic) ||
          mnemonic.include?(@instruction_set.expansion_mnemonic)
        next memo
      end

      warn("Mapping: Unexpected instruction definition '#{mnemonic}'")
    end)
  end

  def no_duplicate_signals?(signals, mnemonic)
    set = Set.new
    signals.map(&:signal_name).reduce(true) do |memo, name|
      next warn "Duplicate control signal name '#{name}' for instruction '#{mnemonic}'" unless set.add? name

      memo
    end
  end
end
