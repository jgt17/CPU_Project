# frozen_string_literal: true

require 'parseconfig'
require 'set'
require_relative 'signal_line'
require_relative 'control_scheme_validation'

# models the control structure of the CPU
class ControlScheme
  include ControlSchemeValidation

  REQUIRED_PARAMETERS = %i[@stages @rom_bit_width @rom_address_bits @control_lines @status_lines].freeze
  OPTIONAL_PARAMETERS = %i[@rom_counts @cpu_name].freeze
  STRING_PARAMETERS = %i[@cpu_name].freeze

  attr_reader :stages
  attr_reader :rom_bit_width
  attr_reader :rom_address_bits
  attr_reader :control_lines
  attr_reader :status_lines
  attr_reader :rom_counts
  attr_reader :cpu_name

  def initialize(scheme)
    @status_lines = []
    @control_lines = []

    initialize_from_file(scheme) if scheme.is_a? String
    raise 'Can only build a Control Scheme from a file right now.' unless scheme.is_a? String

    to_s # initialize the string representation of the ControlScheme
    freeze
  end

  def to_s
    return @string if @string

    s =  "=== CONTROL SCHEME ===\n"
    s += "Name: #{@cpu_name}\n" if @cpu_name
    s += "Stages: #{@stages}\n"
    s += "Microcode ROMs: 2^#{@rom_address_bits} x #{@rom_bit_width}\n\n"
    s += "== Status Lines: ==\n"
    s += format_status_lines
    s += "\n== Control Lines: ==\n"
    @string = s + format_control_lines
  end

  private

  # parses a control scheme specification from a file and initializes it
  def initialize_from_file(filename)
    valid_filename?(filename)
    scheme = ParseConfig.new(filename)
    scheme.params.each do |key, value|
      value.is_a?(Enumerable) ? add_signal_lines(value, key.downcase.tr(' ', '_')) : add_parameter(key, value)
    end
    validate_config
    @status_lines.sort!
    @control_lines.sort!
    set_rom_counts
  end

  def valid_filename?(filename)
    raise "Expected a filename: #{filename}" unless filename.is_a? String
    raise "File does not exist: #{filename}" unless File.exist?(filename)

    true
  end

  def add_parameter(param_name, param_value)
    instance_variable_set("@#{param_name}", STRING_PARAMETERS.include?(param_name) ? param_value : param_value.to_i)
  end

  def add_signal_lines(lines, type)
    lines.each { |key, value| add_signal_line(key, extract_signal_params(value), type) }
  end

  def add_signal_line(name, params, type)
    params.prepend nil if type.eql? 'status_lines'

    instance_variable_get("@#{type}").append(SignalLine.new(name, *params))
  end

  def extract_signal_params(param_string)
    param_string.split(',').map { |param| param.strip.to_i }
  end

  def set_rom_counts
    @rom_counts = (0...@stages).map { |stage| (highest_signal(stage) + @rom_bit_width - 1) / @rom_bit_width }
  end

  def highest_signal(stage)
    highest = 0
    @control_lines.each do |signal|
      highest = signal.top_bit_position if signal.stage.eql?(stage) && signal.top_bit_position > highest
    end
    highest
  end

  def format_status_lines
    s = ''
    (0...@rom_address_bits).each do |i|
      s += format_signal_bit(@status_lines, i)
    end
    s
  end

  def format_control_lines
    s = ''
    (0...@stages).each do |stage|
      s += format_stage(stage)
    end
    s
  end

  def format_stage(stage)
    s = "\n== Stage #{stage}: ==\n"
    roms = @rom_counts[stage]
    s += "Roms Required: #{roms}\n"
    (0...roms * @rom_bit_width).each do |i|
      s += "\n" if (i % @rom_bit_width).zero? && i.positive?
      s += format_signal_bit(@control_lines, i, stage)
    end
    s
  end

  def format_signal_bit(signals, bit, stage = nil)
    # not the most efficient code, but it works and isn't worth the time to optimize further
    signal = signals.select { |sig| sig.stage == stage && sig.bit_position <= bit && sig.top_bit_position >= bit }.first
    bit_descriptor_string = signal.nil? ? '*' : signal.name
    bit_number = !signal.nil? && signal.size > 1 ? ", bit #{bit - signal.bit_position}" : ''
    "#{format('%<align>02d', align: bit)}: #{bit_descriptor_string}#{bit_number}\n"
  end
end
