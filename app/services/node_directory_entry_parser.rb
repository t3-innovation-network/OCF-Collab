class NodeDirectoryEntryParser
  attr_reader :entry_data

  def initialize(entry_data:)
    @entry_data = entry_data
  end

  def parsed_container
    {
      attribution_name: container_data["attributionName"]&.values&.first,
      attribution_url: container_data["attributionURL"],
      beneficiary_rights: container_data["beneficiaryRights"],
      competencies: parsed_competencies,
      concept_keywords: container_data.dig("conceptKeyword")&.values&.first,
      contextualizing_objects: parsed_contextualizing_objects,
      data_url: container_data["dataURL"],
      description: container_data.dig("description")&.values&.first,
      html_url: container_data["htmlURL"],
      name: container_data.dig("name").values.first,
      provider_meta_model: container_data["providerMetaModel"],
      registry_rights: container_data["registryRights"],
      type: container_data["type"],
      url: container_data["id"]
    }
  end

  private

  def container_data
    entry_data["container"]
  end

  def parsed_competencies
    competencies_data.map do |competency_data|
      {
        comment: competency_data.dig("comment")&.values&.first&.join("\n"),
        competency_category: competency_data["competencyCategory"]&.values&.first,
        competency_label: competency_data["competencyLabel"]&.values&.first,
        competency_text: competency_data["competencyText"].values.first,
        contextualized_by: competency_data["contextualizedBy"],
        html_url: competency_data["htmlURL"],
        id: competency_data["id"],
        keywords: (competency_data["keywords"] || []).flat_map(&:values)
      }
    end
  end

  def parsed_contextualizing_objects
    contextualizing_objects_data.map do |contextualizing_object_data|
      {
        category: parse_categories(contextualizing_object_data),
        coded_notation: contextualizing_object_data["codedNotation"],
        data_url: contextualizing_object_data["dataURL"],
        description: contextualizing_object_data["description"]&.values&.first,
        id: contextualizing_object_data["id"],
        name: contextualizing_object_data["name"]&.values&.first,
        type: contextualizing_object_data["type"]
      }
    end
  end

  def parse_categories(contextualizing_object_data)
    (contextualizing_object_data["category"] || []).map do |category_data|
      {
        code_value: category_data["codeValue"],
        description: category_data["description"]&.values&.first,
        in_code_set: category_data["inCodeSet"],
        name: category_data["name"]&.values&.first,
        type: category_data["type"]
      }
    end
  end

  def competencies_data
    entry_data["competencies"]
  end

  def contextualizing_objects_data
    entry_data.fetch("contextualizingObjects", [])
  end
end
