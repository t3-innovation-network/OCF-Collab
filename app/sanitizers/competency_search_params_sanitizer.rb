class CompetencySearchParamsSanitizer < ApplicationInputSanitizer
  array :industries
  array :occupations
  integer :page
  integer :per_page
  array :publishers
  string :query
end
