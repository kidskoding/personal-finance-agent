class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def analyze
    FinancialAnalysisJob.perform_later(current_user.id)
    redirect_to subscriptions_path, notice: "Analyzing transactions for recurring charges — refresh in a few seconds."
  end

  def index
    @date               = current_month
    @recurring_charges  = current_user.recurring_charges.active.order(:merchant_name)
    @monthly_total      = @recurring_charges.sum do |charge|
      case charge.cadence
      when "weekly"  then charge.amount * 4
      when "annual"  then charge.amount / 12.0
      else                charge.amount
      end
    end.round(2)
    earliest = current_user.transactions.minimum(:posted_date)
    @earliest_month = earliest&.beginning_of_month
  end
end
