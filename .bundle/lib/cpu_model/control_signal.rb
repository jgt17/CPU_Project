# frozen_string_literal: true

# a control signal and it's specified value
class ControlSignal
  attr_reader :signal_line
  attr_reader :signal_value

  def initialize(signal_line, signal_value)
    raise TypeError, 'signal_line should be a SignalLine' unless signal_line.is_a? SignalLine
    raise TypeError, 'signal_value should be an Integer' unless signal_value.is_a? Integer

    @signal_line = signal_line
    @signal_value = signal_value

    return if @signal_line.value_in_bounds?(@signal_value)

    raise "Signal value #{@signal_value} out of range of signal line #{@signal_line}"
  end

  def to_binary_string
    signal_value.to_s(2).rjust(@signal_line.size, '0')
  end

  def name
    signal_line.name
  end
end
