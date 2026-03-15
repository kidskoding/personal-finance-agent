class ActionPlanController < ApplicationController
  before_action :authenticate_user!

  def index
    @date                      = parse_month_param
    @has_accounts              = current_user.plaid_items.exists?
    @opportunities             = Planning::SavingsOpportunityEstimator.new(user: current_user, date: @date).call
    @total_savings             = @opportunities.sum { |o| o[:estimated_savings] }
    @recommendation_this_month = current_user.recommendations.find_by(month: @date)
    @past_recommendations      = current_user.recommendations.where.not(month: @date).order(month: :desc).limit(5)
    earliest = current_user.transactions.minimum(:posted_date)
    @earliest_month = earliest&.beginning_of_month
  end

  def generate
    unless current_user.plaid_items.exists?
      redirect_to action_plan_path, alert: "Connect a bank account before generating recommendations."
      return
    end

    date = parse_month_param
    if current_user.recommendations.exists?(month: date)
      redirect_to action_plan_path(month: date.strftime("%Y-%m")), notice: "A recommendation for #{date.strftime("%B %Y")} already exists."
      return
    end

    RecommendationGenerationJob.perform_later(current_user.id, date.iso8601)
    redirect_to action_plan_path(month: date.strftime("%Y-%m")), notice: "Generating recommendations for #{date.strftime("%B %Y")} — refresh in a few seconds."
  end

  private

  def parse_month_param
    Date.strptime(params[:month], "%Y-%m").beginning_of_month
  rescue ArgumentError, TypeError
    Date.current.beginning_of_month
  end
end
