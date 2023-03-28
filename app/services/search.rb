class Search
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE = 100
  MAX_SIZE = 10_000

  attr_reader :container_type, :facets

  def initialize(container_type:, facets:, page:, per_page:)
    @container_type = container_type.presence
    @facets = facets
    @page = page
    @per_page = per_page || DEFAULT_PER_PAGE
  end

  def competency_result_hit_scores
    @competency_result_hit_scores = group_hit_scores(competency_results)
  end

  def competencies_count
    containers.map { |c| c["doc_count"] }.sum
  end

  def containers_count
    containers.size
  end

  def containers
    @containers ||= Competency
      .search(
        body: {
          aggs: {
            containers: {
              terms: {
                field: :container_external_id,
                size: MAX_SIZE
              }
            }
          },
          query:,
          size: 0
        },
        per_page: MAX_SIZE
      )
      .aggs
      .dig("containers", "buckets")
  end

  def page
    @page || 1
  end

  def per_page
    return MAX_PER_PAGE if @per_page.nil?

    [@per_page, MAX_PER_PAGE].min
  end

  def query
    @query ||= begin
      optional, required = facets.partition { |f| f[:optional] }
      required_conditions = required.map { |f| build_condition(f) }
      required_conditions << { match: { container_type: } } if container_type

      {
        bool: {
          must: required_conditions,
          should: optional.map { |f| build_condition(f) }
        }
      }
    end
  end

  def results
    @results ||= begin
      container_ids = containers[(page - 1) * per_page, per_page].map { |c| c["key"] }

      filter_terms = container_ids.map do |id|
        { term: { container_external_id: id } }
      end

      Competency.search(
        body: {
          query: {
            bool: {
              filter: { bool: { should: filter_terms } },
              **query.fetch(:bool)
            }
          }
        },
        includes: { container: :node_directory },
        per_page: MAX_SIZE
      )
    end
  end

  private

  def build_condition(facet)
    {
      match: { facet[:key] => facet[:value] }
    }
  end
end
