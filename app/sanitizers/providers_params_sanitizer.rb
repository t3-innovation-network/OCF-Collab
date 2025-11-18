class ProvidersParamsSanitizer < ApplicationInputSanitizer
  array :names, item_converter: -> (value) { value&.downcase&.squish }
end
