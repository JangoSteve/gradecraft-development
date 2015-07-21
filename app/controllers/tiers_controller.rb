class TiersController < ApplicationController
  before_filter :ensure_staff?

  before_action :find_tier, except: [:new, :create]

  respond_to :html, :json

  def new
    @tier = Tier.new params[:tier]
  end

  def edit
  end

  def create
    @tier = Tier.create params[:tier]
    respond_with @tier, layout: false
  end

  def destroy
    @tier.destroy
    respond_with @tier, layout: false
  end

  def show
  end

  def update
    @tier.update_attributes params[:tier]
    respond_with @tier, layout: false
  end

  private
  def find_tier
    @tier = Tier.find params[:id]
  end
end
