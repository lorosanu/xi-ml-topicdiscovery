# encoding: utf-8



# Keep only stems or tokens of pos-tags [NC, NP, NPP] from the input data
class Xi::ML::Preprocess::Filter::PosNFilter \
  < Xi::ML::Preprocess::Filter::AbstractFilter

  TAGS = %w[NC NP NPP].freeze

  def filter(data = [])
    items = data.map do |token, tag, _, stem|
      stem || token if TAGS.include?(tag)
    end
    items.compact!
    items.join(' ')
  end
end
