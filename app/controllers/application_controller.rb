class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  helper_method :current_month

  private

  def current_month
    if params[:month].present?
      date = Date.strptime(params[:month], "%Y-%m").beginning_of_month
      session[:current_month] = date.strftime("%Y-%m")
      date
    elsif session[:current_month].present?
      Date.strptime(session[:current_month], "%Y-%m").beginning_of_month
    else
      Date.current.beginning_of_month
    end
  rescue ArgumentError
    Date.current.beginning_of_month
  end
end
