# frozen_string_literal: true

# general methods for validating a config file
# including modules must define methods "validate_[DATA_PARAMETERS]"
# as well as additional_hard_checks and additional_soft_checks
# hard checks abort execution, soft checks just warn the user
module ConfigValidation
  def validate_config
    pass = expected_params?

    pass = validate_integer_params && pass
    abort("Invalid #{self.class.name} Parameters!") unless pass
    self.class::DATA_PARAMETERS.each { |data| pass = send("validate_#{data}".to_sym) && pass }
    pass = additional_hard_checks && pass
    abort("Invalid #{self.class.name}!") unless pass
    additional_soft_checks # a signal spanning multiple ROMs isn't a critical error, just potentially annoying
  end

  private

  def expected_params?
    required_params = self.class::REQUIRED_PARAMETERS + self.class::DATA_PARAMETERS
    possible_params = self.class::OPTIONAL_PARAMETERS + required_params
    all_required_params?(required_params) && no_unexpected_params?(possible_params)
  end

  def all_required_params?(required)
    pass = true
    required.each do |param|
      pass = warn "Missing param: #{param}" unless instance_variables.include?(to_instance_format(param))
    end
    pass
  end

  def no_unexpected_params?(expected)
    pass = true
    instance_variables.each do |param|
      pass = warn "Unexpected param: #{to_raw_format(param)}" unless expected.include?(to_raw_format(param))
    end
    pass
  end

  def validate_integer_params
    pass = true
    instance_variables.each do |param|
      expecting_an_integer = !(instance_variable_get(param).is_a?(Enumerable) ||
          self.class::STRING_PARAMETERS.include?(to_raw_format(param)))
      pass = warn "#{param} should be a positive integer" if expecting_an_integer && !valid_int?(param)
    end
    pass
  end

  def to_instance_format(var)
    "@#{var}".to_sym
  end

  def to_raw_format(var)
    var.to_s.delete('@').to_sym
  end
end
