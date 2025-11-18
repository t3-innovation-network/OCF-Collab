class CompetencySearchController < ApplicationController
  def index
    sanitized_params = sanitize_params!(CompetencySearchParamsSanitizer, params)
    search = CompetencySearch.new(**sanitized_params)
    render json: CompetencySearchResultRepresenter.new(search:).represent
  end
end
