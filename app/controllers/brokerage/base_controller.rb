module Brokerage
  class BaseController < ApplicationController
    before_action :doorkeeper_authorize!
    around_action :tag_transaction_logger

    def tag_transaction_logger(&block)
      TransactionLogger.tagged({
        request_id: request.request_id,
        requester_application_id: doorkeeper_token.application.id,
        requester_application_name: doorkeeper_token.application.name,
        requester_directory_id: doorkeeper_token.application.node_directory&.id,
        requester_node_directory_name: doorkeeper_token.application.node_directory&.name,
      }, &block)
    end
  end
end
