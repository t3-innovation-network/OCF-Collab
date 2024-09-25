class Search
  DEFAULT_PER_CONTAINER = 10
  DEFAULT_PER_PAGE = 10
  MAX_PER_CONTAINER = 25
  MAX_PER_PAGE = 25
  MAX_SIZE = 10_000

  attr_reader :container_id, :container_type, :facets, :per_container

  delegate :empty?, to: :facets

  def initialize(
    container_id: nil,
    container_type: nil,
    facets: [],
    page: 1,
    per_container: DEFAULT_PER_CONTAINER,
    per_page: DEFAULT_PER_PAGE
  )
    @container_id = container_id
    @container_type = container_type.presence
    @facets = Array.wrap(facets)
    @page = page
    @per_container = [per_container, MAX_PER_CONTAINER].min
    @per_page = [per_page, MAX_PER_PAGE].min
  end

  def aggregated_containers
    @aggregated_containers ||= begin
      container_query =
        if container_type
          {
            bool: {
              must: [
                { term: { container_type: } },
                *query.dig(:bool, :must)
              ],
              should: query.dig(:bool, :should)
            }
          }
        else
          query
        end

      Competency
        .search(
          body: {
            aggs: {
              containers: {
                terms: {
                  field: "container_external_id.keyword",
                  size: MAX_SIZE
                }
              }
            },
            query: container_query,
            size: 0
          },
          load: false,
          per_page: MAX_SIZE
        )
        .aggs
        .dig("containers", "buckets")
        .each_with_object({}) do |bucket, hash|
          hash[bucket["key"]] = { total_count: bucket["doc_count"] }
        end
    end
  end

  def competency_hit_scores
    @competency_hit_scores ||= begin
      competency_results
        .flat_map { _1.hits }
        .each_with_object({}) do |hit, hash|
          hash[hit['_id']] = hit['_score']
        end
    end
  end

  def competency_results
    return [] if container_ids.empty?

    @competency_results ||= begin
      queries = container_ids.map do |id|
        Competency.search(
          body: {
            query: {
              bool: {
                must: [
                  {
                    bool: {
                      should: {
                        term: { "container_external_id.keyword" => id }
                      }
                    }
                  },
                  *query.dig(:bool, :must)
                ],
                should: query.dig(:bool, :should)
              }
            }
          },
          load: false,
          per_page: container_id.present? ? MAX_SIZE : per_container
        )
      end

      Searchkick.multi_search(queries) || []
    end
  end

  def container_ids
    if container_id.present?
      [container_id]
    else
      aggregated_containers.keys[(page - 1) * per_page, per_page] || []
    end
  end

  def containers_with_competencies
    @containers_with_competencies ||= Competency
      .where(id: competency_results.flat_map { _1.pluck(:id) })
      .includes(container: :node_directory)
      .group_by(&:container)
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

      {
        bool: {
          must: required.map { |f| build_condition(f) },
          should: optional.map { |f| build_condition(f) }
        }
      }
    end
  end

  def total_competencies_count
    aggregated_containers.values.sum { _1.fetch(:total_count) }
  end

  def total_containers_count
    aggregated_containers.size
  end

  private

  def build_condition(facet)
    {
      match: { facet[:key] => facet[:value] }
    }
  end
end
