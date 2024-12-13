class AddAllTextColumnsToCompetencies < ActiveRecord::Migration[8.0]
  def change
    add_column :competencies, :all_text, :string, default: '', null: false
    add_column :competencies, :all_text_embedding, :vector
    add_column :competencies, :all_text_tsv, :tsvector
    add_index :competencies, :all_text_tsv, using: :gin

    reversible do |dir|
      dir.up do
        execute <<~SQL
          CREATE TRIGGER update_competency_all_text_tsv BEFORE INSERT OR UPDATE
          ON competencies FOR EACH ROW EXECUTE PROCEDURE
          tsvector_update_trigger(all_text_tsv, 'pg_catalog.english', all_text);
        SQL
      end

      dir.down do
        execute <<~SQL
          DROP TRIGGER update_competency_all_text_tsv ON competencies;
        SQL
      end
    end
  end
end
