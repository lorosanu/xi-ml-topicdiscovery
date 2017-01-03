# encoding: utf-8



# Class displaying and storing the statistics of given prediction
class Xi::ML::Classify::PredictionStatistics < Xi::ML::Tools::Component
  attr_reader :categories, :data_files, :stats, :n_correct, :n_total

  # Initialize
  #
  # @param data_files [Array] list of data files with classified documents
  # @param categories [Array] list of document categories
  def initialize(data_files, categories)
    super()

    @stats = {}
    @data_files = data_files.clone
    @categories = categories.clone
  end

  # Save statistics to json file
  #
  # @param output [String] the file where to store statistics
  def save_stats(output)
    @logger.info("Save statistics to '#{output}' file")

    compute_stats()

    Xi::ML::Tools::Utils.create_path(output)
    File.open(output, 'w') {|stream| stream.puts(JSON.pretty_generate(@stats)) }
  end

  # Compute the accuracy, precision and recall statistics
  def compute_stats
    @stats = {}

    compute_accuracy_stats()
    compute_pr_stats()
  end

  # Compute the accuracy stats
  def compute_accuracy_stats
    @n_correct, @n_total = {}, {}

    # init stats dictionary
    # - number of total documents in class 'category'
    # - number of correctly classified documents in class 'category'
    @categories.each do |category|
      @n_total[category] = 0
      @n_correct[category] = 0
    end

    valid_format = false

    # count correct predictions in given data files
    @data_files.each do |input_file|
      sc = Xi::ML::Corpus::StreamCorpus.new(input_file)

      sc.each_doc do |doc|
        if doc['category'] && doc['season']
          valid_format = true

          real_category = doc['category']
          predicted_category = doc['season']

          @n_total[real_category] += 1
          @n_correct[real_category] += 1 if predicted_category == real_category
        end
      end
    end

    @logger.warn("Missing fields 'category' or 'season' in input data") \
      unless valid_format

    gc, gt = 0, 0
    # print stats by class
    @categories.each do |category|
      total = @n_total[category]
      correct = @n_correct[category]
      avg_accuracy = div(correct, total)

      @logger.info("Correctly classified documents of class=#{category}: "\
        "#{correct} / #{total} = #{avg_accuracy}")

      # global counts
      gc += correct
      gt += total
    end

    # global accuracy
    global_accuracy = div(gc, gt)

    # print global stats
    @logger.info("Correctly classified documents: #{gc} / #{gt} = "\
      "#{global_accuracy}")

    # store 'global accuracy' stat
    @stats['global-accuracy'] = global_accuracy
  end

  # Compute precision and recall statistics
  def compute_pr_stats
    # recall & precision stats for each class
    # true-positive, false-negative, false-positive, true-negative ratios
    precision, recall = {}, {}
    tp, fn, fp, tn = {}, {}, {}, {}

    @categories.each do |main_cat|
      tp[main_cat] = @n_correct[main_cat]
      fn[main_cat] = @n_total[main_cat] - @n_correct[main_cat]

      tn[main_cat] = 0
      fp[main_cat] = 0
      @categories.each do |other_cat|
        if main_cat != other_cat
          tn[main_cat] += @n_correct[other_cat]
          fp[main_cat] += (@n_total[other_cat] - @n_correct[other_cat])
        end
      end

      precision[main_cat] = div(tp[main_cat], tp[main_cat] + fp[main_cat])
      recall[main_cat] = div(tp[main_cat], tp[main_cat] + fn[main_cat])
    end

    # store P - R stats
    @categories.each do |category|
      @stats[category] = {}
      @stats[category]['precision'] = precision[category]
      @stats[category]['recall'] = recall[category]
    end

    # log the confusion matrix for each class
    @categories.each do |category|
      tpc = tp[category]
      fnc = fn[category]
      fpc = fp[category]
      tnc = tn[category]

      cmatrix = '=' * 40 << "\n"
      cmatrix << "Class=#{category}\n"
      cmatrix << '=' * 40 << "\n"
      cmatrix << "      | declare H1 |  declare H0 |\n"
      cmatrix << "is H1 | #{tpc.to_s.rjust(10)} | #{fnc.to_s.rjust(11)} |\n"
      cmatrix << "is H0 | #{fpc.to_s.rjust(10)} | #{tnc.to_s.rjust(11)} |\n"
      cmatrix << '-' * 40 << "\n"
      cmatrix << "Precision = #{precision[category]}\n"
      cmatrix << "Recall    = #{recall[category]}\n"

      @logger.info('Confusion matix, precision and recall stats ' \
        + "for the #{category} class: \n#{cmatrix}")
    end
  end

  # Own div method to account for zero division error
  def div(x, y)
    if y == 0
      @logger.warn('Zero division error')
      return 0
    end
    '%.2f' % ((x.to_f / y) * 100)
  end

  private :div, :compute_stats, :compute_accuracy_stats, :compute_pr_stats
end
