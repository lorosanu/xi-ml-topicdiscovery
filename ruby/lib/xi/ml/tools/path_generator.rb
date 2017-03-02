# encoding: utf-8



# Class generating the paths for local files/folders
class Xi::ML::Tools::PathGenerator < Xi::ML::Tools::Component
  attr_reader :paths, :res, :classes, :subsets, :preproc, :trans, :classifs

  # Initialize all the necessary paths for data files and models
  #
  # @param res [String] the base ressources path
  # @param classes [Array] the array of categories names
  # @param subsets [Array] the array of subsets names
  # @param preproc [Array] the array of preprocessing names
  # @param trans [Array] the array of transformation names
  # @param classifs [Array] the array of classifier names
  def initialize(res='', classes=[], subsets=[], preproc=[],
    trans=[], classifs=[])

    super()
    @logger.info('Generate all the necessary paths for data files and models')

    @res = res
    @classes = classes.clone
    @subsets = subsets.clone
    @preproc = preproc.clone
    @trans = trans.clone
    @classifs = classifs.clone

    @paths = {}

    # data files
    @paths['data'] = generate_data_files()

    @logger.info("The generated paths:\n#{PP.pp(@paths, '')}")
  end

  # Display the object's contents
  def to_s
    @paths
  end


  # Return the list of preprocessed training data files for each category
  # Files should already exist
  def get_train_preprocessed_files(ptype)
    files = []

    @classes.each do |category|
      filename = @paths['data'][category][:preprocessed][ptype]['train']
      Xi::ML::Tools::Utils.check_file_readable!(filename)
      files << filename
    end

    raise Xi::ML::Error::DataError, 'Empty list of files' if files.size == 0
    files
  end

  # Return the preprocessed file for given category, subset, preprocessing
  # File should already exist
  def get_preprocessed_file(category, subset, preprocess)
    begin
      filename = @paths['data'][category]['preprocessed'][preprocess][subset]

    rescue => e
      @logger.warn("Hash path #{category}/preprocessed/#{preprocess}/#{subset}"\
        + " does not exist: #{e.message}")
    end

    Xi::ML::Tools::Utils.check_file_readable!(filename)
    filename
  end

  # Return the transformed file for given category, subset,
  # transformation, preprocessing.
  # File should be created
  def get_transformed_file(category, subset, transformation, preprocess)
    format = "#{transformation}_#{preprocess}"

    begin
      filename = @paths['data'][category]['transformed'][format][subset]
    rescue => e
      @logger.warn("Hash path #{category}/transformed/#{format}/#{subset}"\
        + " does not exist: #{e.message}")
    end

    Xi::ML::Tools::Utils.create_path(filename)
    filename
  end

  # Return the classified file for given category, subset,
  # classification, transformation, preprocessing.
  # Files should be created
  def get_classified_file(category, subset,
    classification, transformation, preprocess)

    format = "#{classification}_#{transformation}_#{preprocess}"

    begin
      filename = @paths['data'][category]['classified'][format][subset]
    rescue => e
      @logger.warn("Hash path #{category}/classified/#{format}/#{subset}"\
        + " does not exist: #{e.message}")
    end

    Xi::ML::Tools::Utils.create_path(filename)
    filename
  end

  # Return the list of 'test' classified files for given
  # classification, transformation, preprocessing.
  # Files should already exist
  def get_test_classified_files(classification, transformation, preprocess)
    files = []
    @classes.each do |category|
      filename = get_classified_file(category, 'test',
        classification, transformation, preprocess)

      Xi::ML::Tools::Utils.check_file_readable!(filename)
      files << filename
    end

    raise Xi::ML::Error::DataError, 'Empty list of files' if files.size == 0
    files
  end

  # Return the file used to store the classification statistics,
  # given the classification, transformation, preprocessing names.
  # File should be created
  def get_stats_file(classification, transformation, preprocess)
    format = "#{classification}_#{transformation}_#{preprocess}"

    filename = File.join(@res, 'stats', format + '.json')
    Xi::ML::Tools::Utils.create_path(filename)

    filename
  end

  #=======================
  # 'private' methods
  #=======================

  # Generate all the data paths for each category, subset, preproc, trans, ...
  def generate_data_files
    files = {}

    # extracted data
    @classes.each do |category|
      files[category] = {}
      folder = File.join(@res, 'data', category, 'extracted')

      files[category]['extracted'] = File.join(folder, "#{category}.json")
    end

    # divided data
    @classes.each do |category|
      files[category]['divided'] = {}
      folder = File.join(@res, 'data', category, 'divided')

      @subsets.each do |subset|
        files[category]['divided'][subset] = File.join(folder,
          "#{category}_#{subset}.json")
      end
    end

    # preprocessed data
    @classes.each do |category|
      files[category]['preprocessed'] = {}

      @preproc.each do |preprocess|
        folder = File.join(@res, 'data', category, 'preprocessed', preprocess)

        files[category]['preprocessed'][preprocess] = {}

        @subsets.each do |subset|
          files[category]['preprocessed'][preprocess][subset] = File.join(
            folder, "#{category}_#{subset}.json")
        end
      end
    end

    # transformed data
    if @trans.size > 0
      @classes.each do |category|
        files[category]['transformed'] = {}

        @trans.each do |transformation|
          @preproc.each do |preprocess|
            ctrans = "#{transformation}_#{preprocess}"

            folder = File.join(@res, 'data', category, 'transformed', ctrans)
            files[category]['transformed'][ctrans] = {}

            @subsets.each do |subset|
              files[category]['transformed'][ctrans][subset] = File.join(
                folder, "#{category}_#{subset}.json")
            end
          end
        end
      end
    end

    # classified data
    if @classifs.size > 0
      @classes.each do |category|
        files[category]['classified'] = {}

        @classifs.each do |classifier|
          @trans.each do |transformation|
            @preproc.each do |preprocess|
              ctrans = "#{classifier}_#{transformation}_#{preprocess}"

              folder = File.join(@res, 'data', category, 'classified', ctrans)
              files[category]['classified'][ctrans] = {}

              @subsets.each do |subset|
                files[category]['classified'][ctrans][subset] = File.join(
                  folder, "#{category}_#{subset}.json")
              end
            end
          end
        end
      end
    end
    files
  end

  private :generate_data_files
end
