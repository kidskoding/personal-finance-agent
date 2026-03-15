class ActionPlanController < ApplicationController
  before_action :authenticate_user!

  def index
    @date                    = Date.current.beginning_of_month
    @has_accounts            = current_user.plaid_items.exists?
    @opportunities           = Planning::SavingsOpportunityEstimator.new(user: current_user, date: @date).call
    @total_savings           = @opportunities.sum { |o| o[:estimated_savings] }
    @recommendations         = current_user.recommendations.order(generated_at: :desc).limit(3)
    @recommendation_this_month = current_user.recommendations.exists?(month: @date)
  end

  def generate
    unless current_user.plaid_items.exists?
      redirect_to action_plan_path, alert: "Connect a bank account before generating recommendations."
      return
    end

    date = Date.current.beginning_of_month
    if current_user.recommendations.exists?(month: date)
      redirect_to action_plan_path, notice: "A recommendation for #{date.strftime("%B %Y")} already exists."
      return
    end

    RecommendationGenerationJob.perform_later(current_user.id)
    redirect_to action_plan_path, notice: "Generating your recommendations — refresh in a few seconds."
  end
end
