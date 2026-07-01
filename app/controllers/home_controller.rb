class HomeController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index]
  def index
    if user_signed_in?
      render :dashboard
    else
      render :landing
    end
  end
end
