# frozen_string_literal: true

# methods for finding unused opcode ranges
module UnusedOpcodeUtil

  private

  def find_unused_opcodes(instructions, expansion_codes, word_size)
    used_opcodes = instructions.keys + expansion_codes.keys.map { |k| Instruction.binary_opcode(k, word_size) }
    unused_opcodes = possible_opcodes(expansion_codes, word_size) - used_opcodes
    unused_opcodes.map { |code| Instruction.new(code, 'dummy_instruction') }
  end

  def possible_opcodes(expansion_codes, word_size)
    opcodes = []
    ([''] + expansion_codes.keys).each do |expansion_code|
      prefix = expansion_code.is_a?(Integer) ? Instruction.binary_opcode(expansion_code, word_size) + ' ' : ''
      opcodes += (0...2**word_size).map { |i| prefix + Instruction.binary_opcode(i, word_size) }
    end
    opcodes
  end

  def find_opcode_ranges(instruction_array)
    instruction_array = instruction_array.sort
    ranges = [[]]
    previous = instruction_array[0]
    instruction_array.each do |instruction|
      ranges[-1].append previous unless instruction.next_from?(previous)
      previous = instruction
      ranges.append [instruction] if ranges[-1]&.size == 2
    end
    ranges[-1].append instruction_array[-1] unless ranges[-1].size == 2
    ranges
  end
end