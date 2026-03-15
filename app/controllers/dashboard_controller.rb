class DashboardController < ApplicationController
  before_action :authenticate_user!

  def index
    @date = current_month
    @has_accounts = current_user.accounts.exists?
    @categories   = Analysis::CategoryBreakdown.new(user: current_user, date: @date).call
    @merchants    = Analysis::MerchantBreakdown.new(user: current_user, date: @date).call.first(5)
    @spikes       = Analysis::SpendingSpikeDetector.new(user: current_user, date: @date).call.first(1)
    @total_spend  = @categories.sum { |c| c[:total] }
    @recommendation = current_user.recommendations.find_by(month: @date)
    earliest = current_user.transactions.minimum(:posted_date)
    @earliest_month = earliest&.beginning_of_month
  end
end
