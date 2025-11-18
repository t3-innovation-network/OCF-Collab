class TextEmbedder
  attr_reader :client

  def initialize
    @client = OpenAI::Client.new(access_token:) if access_token.present?
  end

  def access_token
    ENV['OPENAI_API_KEY']
  end

  def embed(texts, batch_size: 1_000, model: "text-embedding-3-small")
    return [] unless client

    Array.wrap(texts).each_slice(batch_size).flat_map do |slice|
      client
        .embeddings(parameters: { input: slice, model: })
        .fetch("data")
        .map { _1.fetch("embedding") }
    end
  end
end
