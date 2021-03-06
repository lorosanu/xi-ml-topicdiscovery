# encoding: utf-8



# Keep only stems from the input data
class Xi::ML::Preprocess::Filter::OnlyStemsFilter \
  < Xi::ML::Preprocess::Filter::AbstractFilter

  def filter(data = [])
    items = data.map{|token, _, _, stem| stem || token }
    items.join(' ')
  end
end
