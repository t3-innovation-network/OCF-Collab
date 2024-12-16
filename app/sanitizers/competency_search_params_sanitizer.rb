class CompetencySearchParamsSanitizer < InputSanitizer::Sanitizer
  def self.array(key)
    custom key, converter: -> (value) { Array.wrap(value) }
  end

  array :industries
  array :occupations
  integer :page
  integer :per_page
  array :publishers
  string :query
end
