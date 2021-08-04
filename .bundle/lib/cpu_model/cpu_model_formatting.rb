# frozen_string_literal: true

# # methods for formatting a human-readable dump of a CPUModel
module CPUModelFormatting

  INDENTATION = '    '

  private

  def generate_format_string
    @human_readable_string = "=== CPU MODEL ===\nname: #{@name}\n\n== Specification ==\n"
    @labeled.each do |readable, binary|
      instruction, signals = *readable
      status_binary, control_binary = *binary
      @human_readable_string += "#{instruction}\n" \
      "#{INDENTATION}#{split_binary(status_binary)}\n" \
      "#{INDENTATION}#{signals.map(&:to_s).join(', ')}\n" \
      "#{INDENTATION}#{format_control_word(control_binary).join("\n#{INDENTATION}")}\n\n"
    end
  end

  def split_binary(binary)
    binary.gsub(/..../, '\0 ').strip
  end

  def format_control_word(control_word)
    divide_control_word_by_roms(control_word).map.with_index do |stage_roms, stage_num|
      "Stage #{stage_num}: #{stage_roms.join ' '}"
    end
  end

  def divide_control_word_by_roms(control_word)
    binary = control_word.gsub(/.{#{rom_bit_width}}/, '\0 ').strip.split
    signals_by_roms = []
    rom_counts.each do |num_roms|
      signals_by_roms.append []
      num_roms.times { signals_by_roms[-1].append binary.shift }
    end
    signals_by_roms
  end
end
