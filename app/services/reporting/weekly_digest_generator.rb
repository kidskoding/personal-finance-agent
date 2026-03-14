module Reporting
  class WeeklyDigestGenerator
    MODEL = :"claude-opus-4-6"
    MAX_TOKENS = 1024

    def initialize(user:, week_start:)
      @user = user
      @week_start = week_start.beginning_of_week
      @week_end = @week_start.end_of_week
    end

    def call
      summary = build_weekly_summary
      call_claude(summary)
    end

    private

    def build_weekly_summary
      transactions = weekly_transactions

      category_totals = transactions
        .group_by { |t| t.category_primary.presence || "Uncategorized" }
        .transform_values { |txns| txns.sum(&:amount).round(2) }
        .sort_by { |_, v| -v }
        .to_h

      {
        week: "#{@week_start.strftime('%b %d')} – #{@week_end.strftime('%b %d, %Y')}",
        transaction_count: transactions.size,
        total_spend: transactions.sum(&:amount).round(2),
        category_totals: category_totals,
        top_merchants: top_merchants(transactions),
        prior_week_total: prior_week_total
      }
    end

    def weekly_transactions
      @user.transactions
           .posted
           .where(posted_date: @week_start..@week_end)
           .where("amount > 0")
    end

    def top_merchants(transactions)
      transactions
        .group_by { |t| t.merchant_name.presence || t.name }
        .transform_values { |txns| txns.sum(&:amount).round(2) }
        .sort_by { |_, v| -v }
        .first(3)
        .map { |merchant, total| { merchant: merchant, total: total } }
    end

    def prior_week_total
      prior_start = @week_start - 1.week
      prior_end = @week_end - 1.week
      @user.transactions
           .posted
           .where(posted_date: prior_start..prior_end)
           .where("amount > 0")
           .sum(:amount)
           .round(2)
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
        You are a personal finance assistant generating a concise weekly spending digest.
        Summarise the week's spending in 3-4 short paragraphs:
        1. Overall spend and comparison to prior week
        2. Top spending categories
        3. Notable transactions or merchants
        4. One actionable tip for the coming week
        Keep the tone friendly and encouraging.
      PROMPT
    end

    def user_prompt(summary)
      change = summary[:prior_week_total].zero? ? "no prior data" :
        format("%+.1f%%", ((summary[:total_spend] - summary[:prior_week_total]) / summary[:prior_week_total]) * 100)

      <<~PROMPT
        Weekly spending summary for #{summary[:week]}:

        Total spent: $#{summary[:total_spend]} (#{change} vs prior week)
        Transactions: #{summary[:transaction_count]}

        BY CATEGORY:
        #{summary[:category_totals].map { |cat, amt| "  #{cat}: $#{amt}" }.join("\n").presence || "  No data"}

        TOP MERCHANTS:
        #{summary[:top_merchants].map { |m| "  #{m[:merchant]}: $#{m[:total]}" }.join("\n").presence || "  No data"}

        Please generate a friendly weekly digest.
      PROMPT
    end
  end
end
