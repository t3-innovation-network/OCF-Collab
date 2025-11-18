class ApplicationInputSanitizer < InputSanitizer::Sanitizer
  def self.array(key, item_converter: nil)
    custom key, converter: -> (value) {
      Array.wrap(value).map { item_converter&.call(_1) || _1 }
    }
  end
end
