# encoding: utf-8



# Keep only lemmas or tokens of pos-tags [NC, NP, NPP] from the input data
class Xi::ML::Preprocess::Filter::PosNLemmasFilter \
  < Xi::ML::Preprocess::Filter::AbstractFilter

  TAGS = %w[NC NP NPP].freeze

  def filter(data = [])
    items = data.map do |token, tag, lemma, _|
      lemma || token if TAGS.include?(tag)
    end
    items.compact!
    items.join(' ')
  end
end
