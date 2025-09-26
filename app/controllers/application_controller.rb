class ApplicationController < ActionController::Base
  def health
    render json: { status: 'ok', timestamp: Time.current }
  end
end
