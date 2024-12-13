class Competency < ApplicationRecord
  has_neighbors :all_text_embedding

  searchkick mappings: {
    properties: {
      competency_category: { type: "text" },
      competency_label: { type: "text" },
      competency_text: { type: "text" },
      container_attribution_name: { type: "text" },
      container_description: { type: "text" },
      container_external_id: { type: "keyword" },
      container_name: { type: "text" },
      container_text: { type: "text" },
      container_type: { type: "keyword" },
      keywords: { type: "text" },
      text: { type: "text" },
      type: { type: "keyword" },
      **ContextualizingObject.types.keys.each_with_object(type: "text").to_h
    }
  }

  belongs_to :container
  has_one :node_directory, through: :container
  has_many :competency_contextualizing_objects
  has_many :contextualizing_objects, through: :competency_contextualizing_objects
  has_many :codes, through: :contextualizing_objects

  scope :search_import, -> { includes(:container, contextualizing_objects: :codes) }

  validates :competency_text, presence: true

  delegate :attribution_name, :description, :external_id, :name, :type,
           prefix: true,
           to: :container

  before_save :assign_all_text

  def search_data
    {
      competency_category:,
      competency_label:,
      competency_text:,
      container_attribution_name:,
      container_description:,
      container_external_id:,
      container_name:,
      container_text:,
      container_type:,
      keywords: keywords.join(" "),
      text: [competency_label, competency_text, container_text].join(" "),
      **contextualizing_objects_search_data
    }
  end

  private

  def container_text
    [
      container_attribution_name,
      container_description,
      container_name
    ].compact.join(" ")
  end

  def contextualizing_objects_search_data
    data = contextualizing_objects
      .group_by(&:type)
      .map { |type, objects| [type, objects.map(&:text).join(" ")].presence }
      .to_h

    ContextualizingObject
      .types
      .keys
      .each_with_object(nil)
      .to_h
      .merge(data)
  end

  def assign_all_text
    self.all_text = [
      competency_text,
      container_name,
      container_description,
      container_attribution_name
    ].join(' ')
  end
end
