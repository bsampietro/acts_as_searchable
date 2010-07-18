class ModelWord < ActiveRecord::Base
  belongs_to :word
  belongs_to :searchable, :polymorphic => true
  
  validates_uniqueness_of :word_id, :scope => [:searchable_id, :searchable_type]
  
  def self.find_with_words(words, options = {})
    words_conditions = ActsAsSearchable::Util.split_words(words).collect{|w| "words.word LIKE '#{w}%'"}.join(" OR ")
    returning = self.scoped(:conditions => "(#{words_conditions})", :joins => :word, :include => :searchable)

    include_models = options.delete(:include_models)
    if include_models && !include_models.empty?
      include_models_query = include_models.collect{|model| "model_words.searchable_type = '#{model.to_s.camelize}'"}.join(" OR ")
      returning = returning.scoped(:conditions => "(#{include_models_query})")
    end
    returning.all(options)
  end
end 
