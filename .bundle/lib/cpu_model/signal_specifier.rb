# frozen_string_literal:

# holds the name of a control signal and the value it should have for a specific instruction
class SignalSpecifier
  attr_reader :signal_name
  attr_reader :value

  def initialize(signal_name, value)
    @signal_name = signal_name
    @value = value
    freeze
  end

  def specify
    [signal_name, value]
  end

  def to_s
    "#{@signal_name}[#{@value}]"
  end
end
