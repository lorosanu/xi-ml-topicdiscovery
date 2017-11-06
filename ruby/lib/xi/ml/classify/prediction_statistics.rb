# encoding: utf-8



# Class displaying and storing the statistics of given prediction
class Xi::ML::Classify::PredictionStatistics < Xi::ML::Tools::Component
  attr_reader :categories, :data_files, :stats, \
    :confusion_matrix, :real_categories, :predicted_categories

  # Initialize
  #
  # @param data_files [Array] list of data files with classified documents
  # @param categories [Array] list of document categories
  def initialize(data_files, categories)
    super()

    @stats = {}
    @data_files = data_files.dup
    @categories = categories.dup
  end

  # Compute the accuracy, precision and recall statistics;
  # Save statistics to json file
  #
  # @param output [String] the file where to store statistics
  def save_stats(output)
    @logger.info("Save statistics to '#{output}' file")

    compute_confusion_matrix()
    compute_accuracy_stats()
    compute_pr_stats()

    Xi::ML::Tools::Utils.create_path(output)
    File.open(output, 'w') {|stream| stream.puts(JSON.pretty_generate(@stats)) }
  end

  # Compute the confusion matrix
  def compute_confusion_matrix
    @cm = {}
    @cm['total'] = Hash.new(0)

    @real_categories = []
    @predicted_categories = []

    @data_files.each do |input_file|
      sc = Xi::ML::Corpus::StreamCorpus.new(input_file)

      sc.each_doc do |doc|
        if doc['category'] && doc['season']
          real_category = doc['category']
          predicted_category = doc['season']

          @real_categories << real_category \
            unless @real_categories.include?(real_category)

          @predicted_categories << predicted_category \
            unless @predicted_categories.include?(predicted_category)

          @cm[real_category] = Hash.new(0) unless @cm.key?(real_category)
          @cm[real_category][predicted_category] += 1
          @cm[real_category]['total'] += 1

          @cm['total'][predicted_category] += 1
          @cm['total']['total'] += 1
        end
      end
    end

    @real_categories.sort!
    @predicted_categories.sort!

    display_confusion_matrix()
  end

  def display_confusion_matrix
    rcategories = @real_categories.dup << 'total'
    pcategories = @predicted_categories.dup << 'total'

    n = (rcategories | pcategories).map{|x| x.size }.max + 3

    display = ' ' * n
    pcategories.each{|pcat| display << pcat.rjust(n) }

    display << "\n"
    rcategories.each do |rcat|
      display << rcat.ljust(n)
      pcategories.each{|pcat| display << @cm[rcat][pcat].to_s.rjust(n) }
      display << "\n"
    end

    @logger.info("Confusion matrix and marginals\n#{display}")
  end

  # Compute the accuracy stats
  def compute_accuracy_stats
    gc, gt = 0, 0

    # print stats by class
    @real_categories.each do |cat|
      correct = @cm[cat][cat] ? @cm[cat][cat] : 0
      total = @cm[cat]['total'] ? @cm[cat]['total'] : 0
      avg_acc = percentage(correct, total)

      @logger.info("Correctly classified '#{cat}' documents : "\
        "#{correct} / #{total} = #{avg_acc} %")

      # global counts
      gc += correct
      gt += total
    end

    # global accuracy
    g_acc = percentage(gc, gt)
    @logger.info("Correctly classified documents: #{gc} / #{gt} = #{g_acc} %")

    # store 'global accuracy' stat
    @stats[:global_accuracy] = g_acc
  end

  # Compute precision and recall statistics
  def compute_pr_stats
    # recall & precision stats for each class
    precision, recall = {}, {}

    @real_categories.each do |cat|
      correct = @cm[cat][cat] ? @cm[cat][cat] : 0
      ptotal = @cm['total'][cat] ? @cm['total'][cat] : 0
      rtotal = @cm[cat]['total'] ? @cm[cat]['total'] : 0

      precision[cat] = percentage(correct, ptotal)
      recall[cat] = percentage(correct, rtotal)

      # store P - R stats
      @stats[cat] = {
        precision: precision[cat],
        recall: recall[cat],
      }
    end

    # display the 1-versus-rest confusion matrix for each class
    @real_categories.each do |cat|
      tp = @cm[cat][cat] ? @cm[cat][cat] : 0
      fn = @cm[cat]['total'] - tp
      fp = @cm['total'][cat] - tp
      tn = @cm['total']['total'] - tp - fn - fp

      cmatrix = '=' * 40 << "\n"
      cmatrix << "Class=#{cat}\n"
      cmatrix << '=' * 40 << "\n"
      cmatrix << "      | declare H1 |  declare H0 |\n"
      cmatrix << "is H1 | #{tp.to_s.rjust(10)} | #{fn.to_s.rjust(11)} |\n"
      cmatrix << "is H0 | #{fp.to_s.rjust(10)} | #{tn.to_s.rjust(11)} |\n"
      cmatrix << '-' * 40 << "\n"
      cmatrix << "Precision = #{precision[cat]} %\n"
      cmatrix << "Recall    = #{recall[cat]} %\n"

      @logger.info("Confusion matix, precision, recall for #{cat}\n#{cmatrix}")
    end
  end

  # Own percentage method to account for zero division error
  def percentage(x, y)
    if y == 0
      @logger.warn('Zero division error')
      return 0.0
    end
    ((x.to_f / y) * 100).round(2)
  end

  private :compute_pr_stats, :compute_accuracy_stats, :compute_pr_stats, \
    :percentage
end
