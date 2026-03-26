class FinancialAnalysisJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id, date_str = nil)
    user = User.find(user_id)
    date = date_str ? Date.parse(date_str) : Date.today

    Analysis::RecurringChargeDetector.new(user: user).call
    Analysis::CategoryBreakdown.new(user: user, date: date).call
    Analysis::MerchantBreakdown.new(user: user, date: date).call
    Analysis::SpendingSpikeDetector.new(user: user, date: date).call
  end
end
