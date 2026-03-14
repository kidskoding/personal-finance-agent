class SubscriptionsController < ApplicationController
  before_action :authenticate_user!

  def index
    @recurring_charges  = current_user.recurring_charges.active.order(:merchant_name)
    @monthly_total      = @recurring_charges.sum do |charge|
      case charge.cadence
      when "weekly"  then charge.amount * 4
      when "annual"  then charge.amount / 12.0
      else                charge.amount
      end
    end.round(2)
  end
end
