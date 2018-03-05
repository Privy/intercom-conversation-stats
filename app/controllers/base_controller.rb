# Base controller for aplication
class BaseController < ActionController::Base
  respond_to :json

  private

  def set_headers
    @headers = request.env.select { |h| h.start_with? 'HTTP_' }
  end

  def set_request_params
    @request_params = request.request_parameters
  end

  def set_body_data
    request.body.rewind
    @body_data = request.body.read
  end
end
