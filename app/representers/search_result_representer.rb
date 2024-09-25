class SearchResultRepresenter
  attr_reader :search

  delegate :competency_results, to: :search

  def initialize(search:)
    @search = search
  end

  def represent
    search.containers_with_competencies.map do |container, competencies|
      total_count = search
        .aggregated_containers
        .dig(container.external_id, :total_count)

      {
        **ContainerSearchResultRepresenter.new(container:).represent,
        competencies: competencies.map { represent_competency(_1) },
        total_count:
      }
    end
  end

  private

  def represent_competency(competency)
    {
      comment: competency.comment,
      competency_text: competency.competency_text,
      external_id: competency.external_id,
      hit_score: search.competency_hit_scores.fetch(competency.id),
      html_url: competency.html_url
    }
  end
end
