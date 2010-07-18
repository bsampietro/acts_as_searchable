# ActsAsSearchable

module ActsAsSearchable
  def self.included(base)
    base.send :extend, ActsAsSearchable::ClassMethods
  end
  
  module ClassMethods
    def acts_as_searchable(*args)
      cattr_accessor :searchable_fields
      self.searchable_fields = (args.length == 0 || (args.length == 1 && args.first.to_s == "all")) ? :all : args
      self.send :include, ActsAsSearchable::InstanceMethods
      self.send :extend, ActsAsSearchable::SingletonMethods
      
      has_many :model_words, :as => :searchable, :dependent => :delete_all
      
      after_save :save_words
    end
  end
  
  module SingletonMethods
    def find_with_words(words, options = {})
      words_conditions = ActsAsSearchable::Util.split_words(words).collect{|w| "words.word LIKE '#{w}%'"}.join(" OR ")
      returning = self.scoped(:conditions => "(#{words_conditions})", :joins => {:model_words => :word})
      returning.all(options)
    end
  end
  
  module InstanceMethods
    private
  
    def save_words(only_changed = true)
      self.class.columns.each do |column|
        next if !column.text? || 
          (only_changed && !self.send("#{column.name}_changed?")) ||
          self[column.name].blank? || 
          (self.searchable_fields.to_s != "all" && !self.searchable_fields.collect{|sf| sf.to_s}.include?(column.name))
        
        ModelWord.delete_all("searchable_id = #{self.id} AND searchable_type = '#{self.class.to_s}' AND column_name = '#{column.name}'") unless self.send("#{column.name}_was").blank?
          
        ActsAsSearchable::Util.split_words(self[column.name]).each do |word|
          new_word = Word.find_or_create_by_word(word)
          ModelWord.create(:word => new_word, :searchable => self, :column_name => column.name)
        end
      end
    end
  end
end

ActiveRecord::Base.send :include, ActsAsSearchable
