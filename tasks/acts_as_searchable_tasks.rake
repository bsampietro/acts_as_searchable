# desc "Explaining what the task does"
namespace :aas do
  task :generate_words => :environment do
    models = ENV['models'].to_s.split(',').collect{|m| m.strip.constantize}
    models.each do |model|
      next unless model.respond_to?(:searchable_fields)
      model.find_each do |m|
        m.send(:save_words, false)
      end
    end
  end
end
