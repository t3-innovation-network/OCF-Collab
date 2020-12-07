class CompetencyFrameworksSearchParamsSanitizer < InputSanitizer::Sanitizer
  string :query, required: true
  integer :page
  integer :per_page
end
