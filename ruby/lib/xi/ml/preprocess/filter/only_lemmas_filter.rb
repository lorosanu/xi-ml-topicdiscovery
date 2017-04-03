# encoding: utf-8



# Keep only stems from the input data
class Xi::ML::Preprocess::Filter::OnlyLemmasFilter \
  < Xi::ML::Preprocess::Filter::AbstractFilter

  def filter(data = [])
    items = data.map{|token, _, lemma, _| lemma || token }
    items.join(' ')
  end
end
