# frozen_string_literal: true

require 'parslet'

require_relative 'instruction'

# stuff for parsing CSEs into ints
module ControlSignalExpressionParsing
  # a simple Parslet grammar for parsing auto-generating control signal rules
  # noinspection RubyResolve
  class ControlSignalExpressionParser < Parslet::Parser
    root(:expression)

    rule(:int_literal) { match('[0-9]').repeat(1).as(:int) }
    rule(:string_literal) { match('[a-zA-Z0-9_?]').repeat(1).as(:string) }
    rule(:power_op) { match['\^'].as(:op) }
    rule(:mul_op) { match['*/%'].as(:op) }
    rule(:add_op) { match['+-'].as(:op) }
    rule(:space) { match[' '] }

    rule(:expression) {
      infix_expression(value,
                       [power_op, 3, :right],
                       [mul_op, 2, :left],
                       [add_op, 1, :left])
    }

    rule(:literal) { int_literal | string_literal }
    rule(:parens) { str('(') >> expression >> str(')') }
    rule(:func) { (string_literal.as(:func_name) >> str('(') >> arguments.as(:func_args) >> str(')')) }
    rule(:variable) { str('[') >> string_literal.as(:var_name) >> str(']') }
    rule(:value) { func | parens | literal | variable }
    rule(:arguments) { argument.maybe >> (str(',') >> argument).repeat }
    rule(:argument) { expression }
  end

  CSE_PARSER = ControlSignalExpressionParser.new

  @expansion_opcodes = []

  # util functions for processing the CSE parse tree into something usable
  module CSETransformFunctions
    def self.ternary(condition, true_case, false_case)
      condition ? true_case : false_case
    end

    def self.or(left, right)
      left || right
    end

    def self.expansion_opcode?(opcode)
      ControlSignalExpressionParsing.expansion_opcodes.include?(opcode)
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/LineLength
  # rubocop:disable Metrics/MethodLength
  # noinspection RubyResolve
  def self.transform(instruction)
    Parslet::Transform.new do
      rule(int: simple(:x)) { Integer(x) }
      rule(string: simple(:x)) { String(x) }
      rule(var_name: simple(:x)) { instruction.send(x) }
      rule(op: simple(:x)) { String(x).to_sym }
      rule(exp: simple(:x)) { x }
      rule(func_name: simple(:func), func_args: sequence(:args)) do
        func.to_sym.to_proc.call(CSETransformFunctions, *args)
      end
      rule(func_name: simple(:func), func_args: simple(:arg)) do
        arg.size.zero? ? func.to_sym.to_proc.call(CSETransformFunctions) : func.to_sym.to_proc.call(CSETransformFunctions, arg)
      end
      rule(l: simple(:l), o: simple(:o), r: simple(:r)) { o.to_proc.call(l, r) }
    end
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/LineLength
  # rubocop:enable Metrics/MethodLength

  def self.parse_cse(expression, instruction)
    transform(instruction).apply(CSE_PARSER.parse(expression.delete(' ')))
  end

  def self.expansion_opcodes=(codes)
    @expansion_opcodes = codes
  end

  def self.expansion_opcodes
    @expansion_opcodes
  end
end
