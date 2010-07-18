module ActsAsSearchable
  module Util
    def self.split_words(str)
      return [] if str.blank?
      str.split(/[^\w]+/).collect{|w| w.parameterize}.uniq
    end
  end
end
