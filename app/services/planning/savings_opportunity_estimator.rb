module Planning
  class SavingsOpportunityEstimator
    # Percentage reduction assumed achievable per category
    REDUCTION_TARGETS = {
      "FOOD_AND_DRINK"  => 0.20,
      "SHOPPING"        => 0.25,
      "ENTERTAINMENT"   => 0.30,
      "TRAVEL"          => 0.15,
      "PERSONAL_CARE"   => 0.15
    }.freeze
    DEFAULT_REDUCTION = 0.10

    TOP_CATEGORIES = 5

    def initialize(user:, date:)
      @user = user
      @date = date
    end

    def call
      breakdown = Analysis::CategoryBreakdown.new(user: @user, date: @date).call
      return [] if breakdown.empty?

      breakdown
        .first(TOP_CATEGORIES)
        .map do |entry|
          reduction = REDUCTION_TARGETS.fetch(entry[:category], DEFAULT_REDUCTION)
          savings = (entry[:total] * reduction).round(2)

          {
            category: entry[:category],
            current_spend: entry[:total],
            reduction_percentage: (reduction * 100).round,
            estimated_savings: savings
          }
        end
    end
  end
end
