# encoding: utf-8




# Keep only tokens of pos-tags [NC NP NPP V VS VINF VPP VPR VIMP]
# from the input data
class Xi::ML::Preprocess::Filter::PosNVFilter \
  < Xi::ML::Preprocess::Filter::AbstractFilter

  TAGS = %w[NC NP NPP V VS VINF VPP VPR VIMP].freeze

  def filter(data = [])
    items = data.map{|token, stem, tag| stem || token if TAGS.include?(tag) }
    items.compact!
    items.join(' ')
  end
end
