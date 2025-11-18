class ApplicationController < ActionController::API
  before_action :set_cors_headers

  def cors_preflight_check
    head :ok
  end

  def sanitize_params!(sanitizer, params)
    s = sanitizer.new(params)

    if !s.valid?
      raise InvalidParamsError.new(params_errors: s.errors)
    end

    return s.cleaned
  end

  private

  def set_cors_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] =  'GET, OPTIONS, POST'
    headers['Access-Control-Allow-Headers'] = 'Accept, Authorization, Content-Type, Origin'
  end

  class InvalidParamsError < StandardError
    def initialize(msg = "Request contains missing or invalid parameters", params_errors: nil)
      @params_errors = params_errors
      super(msg)
    end
  end
end
