class CompetencySearch
  attr_reader :industries, :occupations, :page, :per_page, :publishers, :query

  MAX_COSINE_DISTANCE = 0.7
  MAX_PER_PAGE = 100
  MIN_WORD_SIMILARITY = 0.6

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
    @query = query
  end

  def relation
    competencies = competencies_table

    if query.present?
      competencies = competencies.where(all_text_condition)
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
        .join(contextualizing_object_codes_table)
        .on(contextualizing_objects_table[:id].eq(contextualizing_object_codes_table[:contextualizing_object_id]))
        .join(codes_table)
        .on(contextualizing_object_codes_table[:code_id].eq(codes_table[:id]))

      if industries.any?
        competencies = competencies
          .where(contextualizing_objects_table[:type].eq(:industry))
          .where(codes_table[:value].in(industries))
      end

      if occupations.any?
        competencies = competencies
          .where(contextualizing_objects_table[:type].eq(:occupation))
          .where(codes_table[:value].in(occupations))
      end
    end

    competencies
  end

  def query_embedding
    @query_embedding ||= TextEmbedder.new.embed(query).first
  end

  def results
    sql = relation
      .project(competencies_table[Arel.star])
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
      word_similarity.gteq(MIN_WORD_SIMILARITY),
      [
        competencies_table[:all_text_embedding].not_eq(nil),
        cosine_distance.lteq(MAX_COSINE_DISTANCE)
      ].reduce(:and)
    ].reduce(:or)
  end

  def codes_table
    Code.arel_table
  end

  def combined_rank
    [fts_rank, cosine_rank, word_similarity].reduce do |acc, rank|
      Arel::Nodes::InfixOperation.new('+', acc, rank)
    end
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

  def contextualizing_object_codes_table
    ContextualizingObjectCode.arel_table
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
        Arel::Nodes.build_quoted(MAX_COSINE_DISTANCE)
      )
    )
  end

  def fts_rank
    competencies_table[:all_text_tsv].rank(query)
  end

  def order
    [
      (combined_rank.desc if query.present?),
      competencies_table[:id]
    ].compact
  end

  def word_similarity
    competencies_table[:all_text].word_similarity(query)
  end
end
