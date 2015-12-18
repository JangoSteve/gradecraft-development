class PagesController < ApplicationController

  skip_before_filter :require_login

  def home
    if current_user
      redirect_to dashboard_path
    end
  end
  
end
