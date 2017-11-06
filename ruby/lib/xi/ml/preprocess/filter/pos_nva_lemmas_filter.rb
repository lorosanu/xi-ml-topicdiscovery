# encoding: utf-8




# Keep only lemmas or tokens of pos-tags [NC NP NPP V VS VINF VPP VPR VIMP]
# from the input data
class Xi::ML::Preprocess::Filter::PosNVALemmasFilter \
  < Xi::ML::Preprocess::Filter::AbstractFilter

  TAGS = %w[NC NP NPP V VS VINF VPP VPR VIMP ADJ].freeze

  def filter(data = [])
    items = data.map do |token, tag, lemma, _|
      lemma || token if TAGS.include?(tag)
    end
    items.compact!
    items.join(' ')
  end
end
