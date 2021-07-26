# frozen_string_literal: true

require_relative 'config_validation'

# common functionality for objects generated from config files
#  classes using it must include the following constants and methods
#   REQUIRED_PARAMETERS = %i[].freeze
#   OPTIONAL_PARAMETERS = %i[].freeze
#   STRING_PARAMETERS = %i[].freeze

#   DATA_PARAMETERS = %i[].freeze
#   DATA_TYPE = Hash or Array
#   GENERATED_DATA = %i[].freeze
#
# add_[data_parameter], format_[data_parameter], format_[generated_data] methods
# as well as validate_config and post_validation_setup
module Configurable
  include ConfigValidation

  def initialize(config)
    self.class::DATA_PARAMETERS.each { |type| instance_variable_set("@#{type}", self.class::DATA_TYPE.new) }

    initialize_from_file(config) if config.is_a? String
    raise "Can only build a #{self.class.name} from a file right now." unless config.is_a? String

    validate_config
    post_validation_setup
    freeze
  end

  def to_s
    @string
  end

  private

  # parses a config from a file and initializes it
  def initialize_from_file(filename)
    valid_filename?(filename)
    config_data = ParseConfig.new(filename)
    [:metadata].concat(self.class::DATA_PARAMETERS).each do |type|
      next warn "Missing #{to_file_format(type)}!" unless config_data.params[to_file_format(type)].is_a? Enumerable

      send("add_#{type}".to_sym, config_data.params[to_file_format(type)])
    end
  end

  def valid_filename?(filename)
    raise "Expected a filename: #{filename}" unless filename.is_a? String
    raise "File does not exist: #{filename}" unless File.exist?(filename)

    true
  end

  def add_metadata(meta)
    meta.each do |param_name, param_value|
      param_value = param_value.to_i unless self.class::STRING_PARAMETERS.include?(param_name.to_sym)
      instance_variable_set("@#{param_name}", param_value)
      self.class.attr_reader(param_name.to_s)
    end
  end

  def format_metadata
    fields = self.class::REQUIRED_PARAMETERS + self.class::OPTIONAL_PARAMETERS
    lines = fields.map do |field|
      instance_variable_defined?("@#{field}") ? "#{field}: #{instance_variable_get("@#{field}")}\n" : ''
    end
    lines.join + "\n"
  end

  def post_validation_setup
    generate_format_string
  end

  def generate_format_string
    s =  "=== #{format_class_name} ===\n"
    s += format_metadata
    (self.class::DATA_PARAMETERS + self.class::GENERATED_DATA).each do |type|
      if respond_to?("format_#{type}", true)
        s += "== #{type.to_s.split('_').map(&:capitalize).join(' ')} ==\n#{send("format_#{type}")}\n"
      end
    end
    @string = s
  end

  def format_class_name
    self.class.name.gsub(/[A-Z][^A-Z]/, ' \0').strip
  end

  def to_file_format(sym)
    sym.to_s.split('_').map(&:capitalize).join(' ')
  end
end
