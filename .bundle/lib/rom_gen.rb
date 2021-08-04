# frozen_string_literal: true

require_relative 'cpu_model/cpu_model'
require_relative 'dot_hex_util'

# iterate through all possible opcode and status combinations, generate active control lines for each
# break apart into different ROMs
# convert to binary/hex files for physical/simulation
module RomGen

  HEX_FOLDER = '../hex/'
  BIN_FOLDER = '../bin/'

  def self.generate_roms(name = '8bit_cpu',
                         control_filename = '../../data/control_structure.txt',
                         isa_filename = '../../data/cpu.isa',
                         mapping_filename = '../../data/control_mapping.txt')
    model = build_cpu_model(name, control_filename, isa_filename, mapping_filename)
    save_roms(split_by_roms(control_words(model), model), model.name)
  end

  def self.build_cpu_model(name, control_filename, isa_filename, mapping_filename)
    CPUModel.new(name, control_filename, isa_filename, mapping_filename)
  end

  def self.save_roms(roms, cpu_name)
    roms.each_with_index do |stage, stage_num|
      stage.each_with_index do |rom, rom_num|
        filename = "#{cpu_name}_stage_#{stage_num}_rom_#{rom_num}"
        notify_if_changed(rom, filename)
        save_hex_rom(rom, filename)
        save_binary_rom(rom, filename)
      end
    end
  end

  def self.notify_if_changed(rom, filename)
    full_filename = File.join(File.dirname(__FILE__), "#{HEX_FOLDER}#{filename}.hex")
    hex_from_file = File.exist?(full_filename) ? File.read(full_filename) : nil
    puts "'#{filename}' changed!" unless DotHexUtil.generate_hex(rom_data_to_ints(rom)).eql? hex_from_file
  end

  def self.save_hex_rom(data, filename)
    full_filename = File.join(File.dirname(__FILE__), "#{HEX_FOLDER}#{filename}")
    DotHexUtil.write_hex_file(full_filename, rom_data_to_ints(data))
  end

  def self.save_binary_rom(data, filename)
    # TODO
  end

  def self.rom_data_to_ints(rom_data)
    rom_data.map { |byte| byte.to_i(2) }
  end

  def self.control_words(cpu_model)
    microcode_addresses(cpu_model.rom_address_bits).map { |address| cpu_model[address] }
  end

  def self.split_by_roms(control_words, cpu_model)
    control_bytes = control_words.map { |word| split_control_word_by_roms(word, cpu_model) }
    roms = cpu_model.rom_counts.map { |num_roms| Array.new(num_roms) { [] } }
    control_bytes.each_with_index do |status, status_index|
      status.each_with_index do |stage, stage_index|
        stage.each_with_index { |rom_data, rom_index| roms[stage_index][rom_index][status_index] = rom_data }
      end
    end
    roms
  end

  def self.split_control_word_by_roms(control_word, cpu_model)
    binary = control_word.gsub(/.{#{cpu_model.rom_bit_width}}/, '\0 ').strip.split
    signals_by_roms = []
    cpu_model.rom_counts.each do |num_roms|
      signals_by_roms.append []
      num_roms.times { signals_by_roms[-1].append binary.shift }
    end
    signals_by_roms
  end

  def self.microcode_addresses(num_address_bits)
    %w[0 1].repeated_permutation(num_address_bits).map(&:join).sort
  end
end

RomGen.generate_roms
