class SettingsController < ApplicationController
  before_action :authenticate_user!

  def index
    @plaid_items = current_user.plaid_items.includes(:accounts)
  end

  def disconnect_bank
    item = current_user.plaid_items.find(params[:id])
    item.destroy
    redirect_to settings_path, notice: "Bank account disconnected."
  end

  def clear_recommendations
    current_user.recommendations.delete_all
    redirect_to settings_path, notice: "All recommendations cleared."
  end
end
