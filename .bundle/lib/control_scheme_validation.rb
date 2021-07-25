# frozen_string_literal: true

require_relative 'config_validation'

# methods for validating a control scheme
module ControlSchemeValidation
  include ConfigValidation
  # verify that the specified config is valid, eg, has all expected params, no extra params, and signal lines are unique
  def validate_config
    pass = expected_params?

    pass = validate_integer_params && pass
    abort('Invalid Control Scheme Parameters!') unless pass
    pass = validate_signal_lines(:@control_lines) && pass
    pass = validate_signal_lines(:@status_lines) && pass
    pass = status_signals_in_bounds? && pass
    abort('Invalid Control Scheme!') unless pass
    roms_split_signal? # a signal spanning multiple ROMs isn't a critical error, just potentially annoying
  end

  def validate_signal_lines(type)
    pass = true
    lines = instance_variable_get(type)
    reserved_lines = Hash[(0...@stages).map { |stage| [stage, Set.new] }.prepend([nil, Set.new])]
    lines.each do |signal|
      pass = valid_stage?(signal) && pass
      pass = bits_available?(signal, reserved_lines) && pass
    end
    pass
  end

  def valid_stage?(signal)
    pass = true
    stage_error_string = "The CPU only has #{@stages} stages but #{signal} is in stage #{signal.stage}"
    pass = warn stage_error_string unless signal.stage.nil? || (0...@stages).include?(signal.stage)

    pass
  end

  def bits_available?(signal, reserved_lines)
    pass = true
    start_bit = signal.bit_position
    end_bit = start_bit + signal.size
    (start_bit...end_bit).each do |bit|
      unless reserved_lines[signal.stage].add? bit
        pass = warn "Signal Line Conflict at bit #{bit} of stage #{signal.stage || 'nil'}"
      end
    end
    pass
  end

  def valid_int?(val)
    val = instance_variable_get(val) if val.is_a? Symbol

    val.is_a?(Integer) && val.positive?
  end

  def status_signals_in_bounds?
    pass = true
    @status_lines.each do |signal|
      top_bit = signal.top_bit_position
      unless top_bit <= @rom_address_bits
        pass = warn "#{signal.name} has status line #{top_bit}, but ROMs only have #{@rom_address_bits} address bits."
      end
    end
    pass
  end

  def roms_split_signal?
    pass = true
    @control_lines.each do |sig|
      start_rom = sig.bit_position / @rom_bit_width
      end_rom = sig.top_bit_position / @rom_bit_width
      unless start_rom == end_rom
        pass = warn "Control Signal #{sig.name} of stage #{sig.stage} is split between ROMs #{start_rom}-#{end_rom}."
      end
    end
    pass
  end
end
