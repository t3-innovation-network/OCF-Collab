module Brokerage
  class SearchController < Brokerage::BaseController
    def index
      TransactionLogger.tagged(
        search_params: {
          query: params[:query],
          page: params[:page],
          per_page: params[:per_page],
        },
      ) do
        TransactionLogger.info(
          message: "Handling competency frameworks search request",
          event: "container_search_request",
        )

        search = Search.new(**sanitize_params!(SearchParamsSanitizer, params))

        render json: {
          search: {
            competencies_count: search.total_competencies_count,
            containers_count: search.total_containers_count,
            page: search.page,
            per_container: search.per_container,
            per_page: search.per_page,
            results: SearchResultRepresenter.new(search:).represent
          }
        }

        TransactionLogger.info(
          message: "Returned competency frameworks search results",
          event: "container_search_response",
        )
      end
    end
  end
end
