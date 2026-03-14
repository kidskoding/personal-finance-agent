module Planning
  class RecommendationGenerator
    MODEL = :"claude-opus-4-6"
    MAX_TOKENS = 1024

    def initialize(user:, date:)
      @user = user
      @date = date
    end

    def call
      summary = build_analytics_summary
      response = call_claude(summary)
      store_recommendation(response)
    end

    private

    def build_analytics_summary
      {
        month: @date.strftime("%B %Y"),
        category_breakdown: Analysis::CategoryBreakdown.new(user: @user, date: @date).call,
        merchant_breakdown: Analysis::MerchantBreakdown.new(user: @user, date: @date).call.first(5),
        savings_opportunities: Planning::SavingsOpportunityEstimator.new(user: @user, date: @date).call,
        spending_spikes: Analysis::SpendingSpikeDetector.new(user: @user, date: @date).call,
        recurring_charges: @user.recurring_charges.active.map { |r|
          { merchant: r.merchant_name, amount: r.amount, cadence: r.cadence }
        }
      }
    end

    def call_claude(summary)
      client = Anthropic::Client.new(api_key: ENV.fetch("ANTHROPIC_API_KEY"))

      message = client.messages.create(
        model: MODEL,
        max_tokens: MAX_TOKENS,
        system: system_prompt,
        messages: [
          { role: "user", content: user_prompt(summary) }
        ]
      )

      message.content.find { |b| b.type == :text }&.text
    end

    def store_recommendation(content)
      Recommendation.create!(
        user: @user,
        month: @date.beginning_of_month,
        content: content,
        raw_response_json: { model: MODEL.to_s, generated_at: Time.current.iso8601 },
        generated_at: Time.current
      )
    end

    def system_prompt
      <<~PROMPT
        You are a personal finance advisor. You receive a structured summary of a user's
        monthly spending analytics and provide clear, actionable financial recommendations.

        Respond with 3-5 concise recommendations. Focus on:
        - Reducing spending in high-spend categories
        - Addressing unusual spending spikes
        - Evaluating recurring subscription costs
        - Practical savings strategies

        Be specific and encouraging. Keep each recommendation to 1-2 sentences.
      PROMPT
    end

    def user_prompt(summary)
      <<~PROMPT
        Here is my financial summary for #{summary[:month]}:

        TOP SPENDING CATEGORIES:
        #{format_categories(summary[:category_breakdown])}

        TOP MERCHANTS:
        #{format_merchants(summary[:merchant_breakdown])}

        SAVINGS OPPORTUNITIES:
        #{format_savings(summary[:savings_opportunities])}

        SPENDING SPIKES (vs. prior 3 months):
        #{format_spikes(summary[:spending_spikes])}

        RECURRING CHARGES:
        #{format_recurring(summary[:recurring_charges])}

        Please provide personalised financial recommendations based on this data.
      PROMPT
    end

    def format_categories(breakdown)
      return "No data" if breakdown.empty?
      breakdown.first(5).map { |c| "  #{c[:category]}: $#{c[:total]} (#{c[:percentage]}%)" }.join("\n")
    end

    def format_merchants(merchants)
      return "No data" if merchants.empty?
      merchants.map { |m| "  ##{m[:rank]} #{m[:merchant]}: $#{m[:total]}" }.join("\n")
    end

    def format_savings(opportunities)
      return "No data" if opportunities.empty?
      opportunities.map { |o| "  #{o[:category]}: save ~$#{o[:estimated_savings]} (#{o[:reduction_percentage]}% reduction)" }.join("\n")
    end

    def format_spikes(spikes)
      return "No unusual spikes" if spikes.empty?
      spikes.map { |s| "  #{s[:category]}: $#{s[:current_total]} vs $#{s[:baseline_average]} avg (+#{s[:spike_percentage]}%)" }.join("\n")
    end

    def format_recurring(charges)
      return "None detected" if charges.empty?
      charges.map { |r| "  #{r[:merchant]}: $#{r[:amount]} #{r[:cadence]}" }.join("\n")
    end
  end
end
