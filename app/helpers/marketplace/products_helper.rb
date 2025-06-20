module Marketplace::ProductsHelper
  def number_with_comma(number)
    number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end
end
