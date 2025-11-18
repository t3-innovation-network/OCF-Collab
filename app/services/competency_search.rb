class CompetencySearch
  attr_reader :industries, :occupations, :page, :per_page, :publishers, :query

  DEFAULT_MAX_COSINE_DISTANCE = 0.7
  MAX_PER_PAGE = 50

  def initialize(
    industries: nil,
    occupations: nil,
    page: nil,
    per_page: nil,
    publishers: nil,
    query: ""
  )
    @industries = Array.wrap(industries) || []
    @occupations = Array.wrap(occupations) || []
    @page = page || 1
    @per_page = per_page || MAX_PER_PAGE
    @publishers = Array.wrap(publishers) || []
    @query = query&.squish
  end

  def relation
    competencies = competencies_table

    if query.present?
      competencies = competencies
        .join(matched_competencies_table)
        .on(competencies_table[:id].eq(matched_competencies_table[:id]))
        .group(*selected_columns)
    end

    if publishers.any?
      competencies = competencies
        .join(containers_table)
        .on(competencies_table[:container_id].eq(containers_table[:id]))
        .where(containers_table[:attribution_name].in(publishers))
    end

    if industries.any? || occupations.any?
      competencies = competencies
        .join(competency_contextualizing_objects_table)
        .on(competencies_table[:id].eq(competency_contextualizing_objects_table[:competency_id]))
        .join(contextualizing_objects_table)
        .on(competency_contextualizing_objects_table[:contextualizing_object_id].eq(contextualizing_objects_table[:id]))

      if industries.any?
        competencies = competencies
          .where(contextualizing_objects_table[:type].eq(:industry))
          .where(contextualizing_objects_table[:coded_notation].in(industries))
      end

      if occupations.any?
        competencies = competencies
          .where(contextualizing_objects_table[:type].eq(:occupation))
          .where(contextualizing_objects_table[:coded_notation].in(occupations))
      end
    end

    competencies
  end

  def query_embedding
    @query_embedding ||= TextEmbedder.new.embed(query).first
  end

  def results
    @results ||= begin
      sql = relation
        .project(*project)
        .order(*order)
        .take(per_page)
        .skip((page - 1) * per_page)
        .to_sql

      competencies = Competency.find_by_sql(sql)

      ActiveRecord::Associations::Preloader
        .new(associations: :container, records: competencies)
        .call

      competencies
    end
  end

  def total_count
    sql = relation
      .project(Arel.star.count.as('total_count'))
      .to_sql

    Competency.find_by_sql(sql).first.total_count
  end

  private

  def all_text_condition
    [
      competencies_table[:all_text_tsv].search(query),
      [
        competencies_table[:all_text_embedding].not_eq(nil),
        cosine_distance.lteq(max_cosine_distance)
      ].reduce(:and)
    ].reduce(:or)
  end

  def codes_table
    Code.arel_table
  end

  def combined_rank
    matched_competencies_table[:rank].sum
  end

  def competency_contextualizing_objects_table
    CompetencyContextualizingObject.arel_table
  end

  def competencies_table
    Competency.arel_table
  end

  def containers_table
    Container.arel_table
  end

  def contextualizing_objects_table
    ContextualizingObject.arel_table
  end

  def cosine_distance
    competencies_table[:all_text_embedding].cosine_distance(query_embedding)
  end

  def cosine_rank
    Arel::Nodes::InfixOperation.new(
      '-',
      1,
      Arel::Nodes::InfixOperation.new(
        '/',
        cosine_distance,
        Arel::Nodes.build_quoted(max_cosine_distance)
      )
    )
  end

  def fts_rank
    competencies_table[:all_text_tsv].rank(query)
  end

  def max_cosine_distance
    Float(ENV['MAX_COSINE_DISTANCE'])
  rescue ArgumentError, TypeError
    DEFAULT_MAX_COSINE_DISTANCE
  end

  def order
    [
      (combined_rank.desc if query.present?),
      competencies_table[:id]
    ].compact
  end

  def vector_query
    competencies_table
      .project(
        competencies_table[:id],
        cosine_rank.as('rank')
      )
      .where(cosine_distance.lt(max_cosine_distance))
  end

  def fts_query
    competencies_table
      .project(
        competencies_table[:id],
        competencies_table[:all_text_tsv].rank(query).as('rank')
      )
      .where(competencies_table[:all_text_tsv].search(query))
  end

  def like_query
    competencies_table
      .project(
        competencies_table[:id],
        Arel::Nodes::InfixOperation.new(
          '*',
          2,
          competencies_table[:all_text].weighted_rank(query).as('rank')
        )
      )
      .where(competencies_table[:all_text].matches("%#{query}%"))
  end

  def all_text_query
    [fts_query, like_query, vector_query].inject do |union, query|
      Arel::Nodes::UnionAll.new(union, query)
    end
  end

  def matched_competencies_table
    competencies_table.create_table_alias(all_text_query, 't')
  end

  def project
    [
      *selected_columns,
      Arel.star.count.over.as('total_count'),
      (combined_rank.as('rank') if query.present?)
    ].compact
  end

  def selected_columns
    [
      competencies_table[:id],
      competencies_table[:external_id],
      competencies_table[:container_id],
      competencies_table[:competency_text]
    ]
  end
end
