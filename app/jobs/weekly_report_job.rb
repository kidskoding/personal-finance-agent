class WeeklyReportJob < ApplicationJob
  queue_as :default
  discard_on ActiveRecord::RecordNotFound

  def perform(user_id, week_start_str = nil)
    user = User.find(user_id)
    week_start = week_start_str ? Date.parse(week_start_str) : Date.today.beginning_of_week

    Reporting::WeeklyDigestGenerator.new(user: user, week_start: week_start).call
  end
end
