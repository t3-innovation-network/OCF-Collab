class CompetencySearchResultRepresenter
  attr_reader :search

  delegate :results, to: :search

  def initialize(search:)
    @search = search
  end

  def represent
    {
      competencies: results.map { represent_competency(_1) },
      totalCount: search.results.first&.total_count || 0
    }
  end

  private

  def represent_competency(competency)
    {
      id: competency.external_id,
      competencyText: competency.competency_text,
      containerName: competency.container_name,
      containerDescription: competency.container_description,
      attributionName: competency.container_attribution_name
    }
  end
end
