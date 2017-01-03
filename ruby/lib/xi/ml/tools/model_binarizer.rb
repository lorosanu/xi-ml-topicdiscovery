# encoding: utf-8



# The class to convert models from json to binary format and vice-versa
class Xi::ML::Tools::ModelBinarizer
  BYTESIG = 'XiML'.freeze
  NUMBER_FORMAT = 'f'.freeze
  NUMBER_SIZE = 4

  # static method to binarize json LSI model
  def self.convert(input, output)
    Xi::ML::Tools::Utils.check_file_readable!(input)
    Xi::ML::Tools::Utils.create_path(output)

    header = true
    File.open(output, 'w') do |bin|
      bin.write(BYTESIG)

      begin
        File.open(input, 'r').each_line do |line|
          projection = JSON.load(line)

          id = projection.keys[0]
          n_weights = projection[id].size
          bin_format = "L#{NUMBER_FORMAT * n_weights}"

          values = []
          values << id.to_i
          values += projection[id]

          bin.write([n_weights].pack('L')) if header
          bin.write(values.pack(bin_format))

          header = false
        end
      rescue => e
        raise Xi::ML::Error::CaughtException, \
          "Bad format of JSON file '#{input}' : #{e.message}"
      end
    end
  end

  # static method to binarize partial json LSI model
  def self.partial_convert(input, output, ids=[])
    Xi::ML::Tools::Utils.check_file_readable!(input)
    Xi::ML::Tools::Utils.create_path(output)

    header = true
    File.open(output, 'w') do |bin|
      bin.write(BYTESIG)

      begin
        File.open(input, 'r').each_line do |line|
          projection = JSON.load(line)

          id = projection.keys[0]
          n_weights = projection[id].size
          bin_format = "L#{NUMBER_FORMAT * n_weights}"

          values = []
          values << id.to_i
          values += projection[id]

          bin.write([n_weights].pack('L')) if header
          bin.write(values.pack(bin_format)) if ids.include?(id.to_i)

          header = false
        end
      rescue => e
        raise Xi::ML::Error::CaughtException, \
          "Bad format of JSON file '#{input}' : #{e.message}"
      end
    end
  end

  # static method to extract LSI hash model from binary file
  def self.revert(input)
    Xi::ML::Tools::Utils.check_file_readable!(input)

    model = {}

    File.open(input, 'r') do |bin|
      raise Xi::ML::Error::DataError, 'Invalid binary format' \
        unless bin.read(BYTESIG.bytesize) == BYTESIG

      # read NUM_WEIGHTS(uint32) (4 bytes)
      num_weights = bin.read(4).unpack('L').first
      bin_format = "L#{NUMBER_FORMAT * num_weights}"

      # sizeof(uint32) + num_weights * sizeof(Float)
      bin_size = 4 + (num_weights * NUMBER_SIZE)

      until bin.eof?
        entry = bin.read(bin_size).unpack(bin_format)

        id = entry[0].to_i
        weights = entry[1..-1]

        model[id] = weights
      end
    end

    model
  end

  # static method to extract partial LSI hash model from binary file
  def self.partial_revert(input, ids = [])
    Xi::ML::Tools::Utils.check_file_readable!(input)

    model = {}

    File.open(input, 'r') do |bin|
      raise Xi::ML::Error::DataError, 'Invalid binary format' \
        unless bin.read(BYTESIG.bytesize) == BYTESIG

      # read NUM_WEIGHTS(uint32) (4 bytes)
      num_weights = bin.read(4).unpack('L').first
      bin_format = "L#{NUMBER_FORMAT * num_weights}"

      # sizeof(uint32) + num_weights * sizeof(Float)
      bin_size = 4 + (num_weights * NUMBER_SIZE)

      until bin.eof?
        entry = bin.read(bin_size).unpack(bin_format)

        id = entry[0].to_i
        weights = entry[1..-1]

        model[id] = weights if ids.include?(id)
      end
    end

    model
  end

end
