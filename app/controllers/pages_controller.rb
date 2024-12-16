class PagesController < ApplicationController
  def empty
    head :no_content
  end

  def publishers
    render json: Container
      .distinct
      .order(:attribution_name)
      .pluck(:attribution_name)
  end

  def codes
    render json: ContextualizingObject
      .select('type, array_agg(DISTINCT codes.value) AS values')
      .joins(:codes)
      .where(type: %i[industry occupation])
      .where.not(codes: { value: '' })
      .group(:type)
      .map { [_1.type, _1.values] }
      .to_h
  end
end
