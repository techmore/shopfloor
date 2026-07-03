class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  stale_when_importmap_changes

  include Pundit::Authorization

  before_action :authenticate_user!
  before_action :set_paper_trail_whodunnit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def user_not_authorized
    flash[:alert] = "You are not authorized to perform this action."
    redirect_back(fallback_location: root_path)
  end
end
