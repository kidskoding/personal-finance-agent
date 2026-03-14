module Reporting
  class MonthlyReviewGenerator
    MODEL = :"claude-opus-4-6"
    MAX_TOKENS = 1536

    def initialize(user:, date:)
      @user = user
      @date = date
    end

    def call
      summary = build_monthly_summary
      call_claude(summary)
    end

    private

    def build_monthly_summary
      {
        month: @date.strftime("%B %Y"),
        category_breakdown: Analysis::CategoryBreakdown.new(user: @user, date: @date).call,
        merchant_breakdown: Analysis::MerchantBreakdown.new(user: @user, date: @date).call.first(5),
        spending_spikes: Analysis::SpendingSpikeDetector.new(user: @user, date: @date).call,
        savings_opportunities: Planning::SavingsOpportunityEstimator.new(user: @user, date: @date).call,
        latest_recommendations: @user.recommendations
                                     .where(month: @date.beginning_of_month)
                                     .order(generated_at: :desc)
                                     .first&.content
      }
    end

    def call_claude(summary)
      client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

      message = client.messages.create(
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system: system_prompt,
        messages: [ { role: "user", content: user_prompt(summary) } ]
      )

      message.content.find { |b| b.type == :text }&.text
    end

    def system_prompt
      <<~PROMPT
        You are a personal finance advisor generating a comprehensive monthly financial review.
        Structure your review as follows:
        1. Monthly overview — total spend and highlights
        2. Spending trends — notable categories and changes
        3. Unusual activity — any spending spikes worth noting
        4. Savings opportunities — concrete ways to reduce expenses next month
        5. Summary — 2-3 sentence encouragement and key takeaways

        Be specific, use the numbers provided, and keep the tone constructive.
      PROMPT
    end

    def user_prompt(summary)
      <<~PROMPT
        Monthly financial review for #{summary[:month]}:

        SPENDING BY CATEGORY:
        #{format_categories(summary[:category_breakdown])}

        TOP MERCHANTS:
        #{format_merchants(summary[:merchant_breakdown])}

        SPENDING SPIKES (vs. prior 3-month average):
        #{format_spikes(summary[:spending_spikes])}

        SAVINGS OPPORTUNITIES:
        #{format_savings(summary[:savings_opportunities])}

        #{summary[:latest_recommendations] ? "PRIOR RECOMMENDATIONS:\n#{summary[:latest_recommendations]}" : ""}

        Please generate a comprehensive monthly financial review.
      PROMPT
    end

    def format_categories(breakdown)
      return "  No data" if breakdown.empty?
      breakdown.first(6).map { |c| "  #{c[:category]}: $#{c[:total]} (#{c[:percentage]}%)" }.join("\n")
    end

    def format_merchants(merchants)
      return "  No data" if merchants.empty?
      merchants.map { |m| "  #{m[:merchant]}: $#{m[:total]}" }.join("\n")
    end

    def format_spikes(spikes)
      return "  No unusual spikes" if spikes.empty?
      spikes.map { |s| "  #{s[:category]}: $#{s[:current_total]} vs $#{s[:baseline_average]} avg (+#{s[:spike_percentage]}%)" }.join("\n")
    end

    def format_savings(opportunities)
      return "  No data" if opportunities.empty?
      opportunities.map { |o| "  #{o[:category]}: save ~$#{o[:estimated_savings]}" }.join("\n")
    end
  end
end
