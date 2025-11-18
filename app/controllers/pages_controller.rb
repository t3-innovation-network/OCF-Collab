class PagesController < ApplicationController
  def empty
    head :no_content
  end

  def codes
    render json: ContextualizingObject
      .select("type, array_agg(DISTINCT jsonb_build_object('name', name, 'value', coded_notation)) AS values")
      .joins(:competencies)
      .where(type: %i[industry occupation])
      .where.not(coded_notation: "")
      .group(:type)
      .map { [_1.type, _1.values] }
      .to_h
  end

  def providers
    containers = Container.distinct.order(:attribution_name)

    sanitized_params = sanitize_params!(ProvidersParamsSanitizer, params)
    names = sanitized_params[:names] || []

    if names.present?
      containers = containers.where('LOWER(attribution_name) IN (?)', names)
    end

    render json: containers.pluck(:attribution_name)
  end
end
