# frozen_string_literal: true

# general methods for validating a config file
module ConfigValidation
  def validate_config
    true
  end

  def expected_params?
    required_params = ControlScheme::REQUIRED_PARAMETERS
    possible_params = ControlScheme::OPTIONAL_PARAMETERS + required_params
    pass = true
    required_params.map { |param| pass = warn "Missing param: #{param}" unless instance_variables.include?(param) }
    instance_variables.map { |param| pass = warn "Unexpected param: #{param}" unless possible_params.include?(param) }

    pass
  end

  def validate_integer_params
    pass = true
    instance_variables.each do |param|
      expecting_an_integer = !(instance_variable_get(param).is_a?(Enumerable) ||
          ControlScheme::STRING_PARAMETERS.include?(param))
      pass = warn "#{param} should be a positive integer" if expecting_an_integer && !valid_int?(param)
    end
    pass
  end
end
