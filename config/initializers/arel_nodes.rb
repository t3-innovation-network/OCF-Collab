module Arel
  module Nodes
    class CosineDistance < Arel::Nodes::Binary
      def initialize(column, embedding)
        super(column, embedding)
      end
    end

    class FullTextSearch < Arel::Nodes::Binary
      attr_reader :dictionary

      def initialize(column, query, dictionary = 'english')
        @dictionary = dictionary
        super(column, query)
      end
    end

    class FullTextRank < Arel::Nodes::Binary
      attr_reader :dictionary

      def initialize(column, query, dictionary = 'english')
        @dictionary = dictionary
        super(column, query)
      end
    end

    class WeightedRank < Arel::Nodes::Binary
      def initialize(column, query)
        super(column, query)
      end
    end
  end

  module Predications
    def cosine_distance(embedding)
      Nodes::CosineDistance.new(self, embedding)
    end

    def rank(query, dictionary = 'english')
      Nodes::FullTextRank.new(self, query, dictionary)
    end

    def search(query, dictionary = 'english')
      Nodes::FullTextSearch.new(self, query, dictionary)
    end

    def weighted_rank(query)
      Nodes::WeightedRank.new(self, query)
    end
  end

  module Visitors
    class PostgreSQL
      private

      def visit_Arel_Nodes_CosineDistance(object, collector)
        collector << "("
        collector = visit object.left, collector
        collector << " <=> "
        collector = visit Arel::Nodes::Quoted.new(object.right.to_s), collector
        collector << ")"
        collector
      end

      def visit_Arel_Nodes_FullTextRank(object, collector)
        collector << "ts_rank_cd("
        collector = visit object.left, collector
        collector << ", plainto_tsquery('english', "
        collector = visit Arel::Nodes::Quoted.new(object.right), collector
        collector << ")) / (MAX("
        collector << "ts_rank_cd("
        collector = visit object.left, collector
        collector << ", plainto_tsquery('english', "
        collector = visit Arel::Nodes::Quoted.new(object.right), collector
        collector << "))) OVER () + 0.01)"
        collector
      end

      def visit_Arel_Nodes_FullTextSearch(object, collector)
        collector = visit object.left, collector
        collector << " @@ plainto_tsquery('english', "
        collector = visit Arel::Nodes::Quoted.new(object.right), collector
        collector << ")"
        collector
      end

      def visit_Arel_Nodes_WeightedRank(object, collector)
        collector << "(1 - (position(lower("
        collector = visit Arel::Nodes::Quoted.new(object.right), collector
        collector << ") in lower("
        collector = visit object.left, collector
        collector << ")) - 1) / length(lower("
        collector = visit object.left, collector
        collector << "))::float)"
        collector
      end
    end
  end
end