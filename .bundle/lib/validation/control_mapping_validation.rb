# frozen_string_literal: true

require_relative 'config_validation'

# methods for validating a control mapping
module ControlMappingValidation
  include ConfigValidation

  def validate_substitutions
    @substitutions.to_a.reduce(true) do |memo, sub|
      next warn "Unknown substitution control signal name: #{sub[0]}" unless @control_scheme.control_signal?(sub[0])

      values_in_bounds?(@control_scheme[sub[0]], sub[1]) && memo
    end
  end

  def validate_mappings
    @mappings.to_a.reduce(true) do |memo, mapping|
      mnemonic, signals = *mapping
      next warn "'#{mnemonic}' is not a recognized instruction" unless @instruction_set.include? mnemonic

      signals.reduce(true) do |memo2, signal|
        signal_name, value = *signal.specify
        next warn "Unknown control signal name: #{signal_name}" unless @control_scheme.control_signal?(signal_name)

        value_in_bounds?(@control_scheme[signal_name], value) && memo2
      end && memo
    end
  end

  def additional_hard_checks
    true
  end

  def additional_soft_checks; end

  def values_in_bounds?(control_signal, values)
    values.each_value.reduce(true) { |memo, val| value_in_bounds?(control_signal, val) && memo }
  end

  def value_in_bounds?(control_signal, value)
    unless control_signal.value_in_bounds?(value)
      return warn "Value #{value} out of range for control signal #{control_signal.name}"
    end

    true
  end
end
