# frozen_string_literal: true

# Generates a .hex file representing the binary data
# .hex format specs: https://www.keil.com/support/docs/1584/

RECORD_SIZE = 128
END_OF_FILE_RECORD = ':00000001FF'

public

# may change to bindata uint8 later
def validate_data(data)
  data.each do |byte|
    raise "Data should be single bytes: #{byte}" unless byte.is_a?(Integer) && byte >=0 && byte < 256
  end
  true
end

# data should be an array of ints between 0-255, inclusive
def generate_hex(data)
  validate_data(data)
  records = split_segments(data).each_with_index.map { |seg, i| to_record(seg, i * RECORD_SIZE) }
  records.reduce { |memo, record| memo + "\n" + record }
end

def write_hex_file(name, data)
  File.write("#{name}.hex", generate_hex(data))
end

private

# Change make data as needed to get the wanted test data
def make_data
  Array.new(2**15) { |i| (i / 16 % 256) }
end

def to_hex(byte)
  (byte.negative? ? byte + 256 : byte).to_s(16).upcase.rjust(2, '0')
end

# since the length of a record is represented by a single byte
# they can only be 255 bytes long, so the data must be split into
# multiple records accordingly
# I'm using 128 because I like powers of 2
def split_segments(data)
  pos = 0
  segments = []
  segments.append(data[pos...pos += RECORD_SIZE]) while pos < data.length
  segments
end

def make_length_portion(data_segment)
  to_hex(data_segment.length)
end

def make_address_portion(start_address)
  to_hex(start_address / 256) + to_hex(start_address % 256)
end

def make_data_portion(data_segment)
  data_segment.map { |byte| to_hex(byte) }.reduce { |memo, byte| memo + byte}
end

def make_checksum_portion(data_segment, start_address)
  to_hex(-((data_segment.sum + data_segment.length + start_address / 256 + start_address) % 256))
end

def to_record(data_segment, start_address)
  ll = make_length_portion(data_segment)
  aaaa = make_address_portion(start_address)
  tt = '00' # may add support for other types later, this meets my needs for now
  dd = make_data_portion(data_segment)
  cc = make_checksum_portion(data_segment, start_address)
  ":#{ll}#{aaaa}#{tt}#{dd}#{cc}"
end
