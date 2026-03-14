require 'rails_helper'

RSpec.describe WeeklyReportJob do
  let(:user) { create(:user) }
  let(:week_start) { Date.new(2026, 3, 9) }
  let(:service) { instance_double(Reporting::WeeklyDigestGenerator, call: nil) }

  before { allow(Reporting::WeeklyDigestGenerator).to receive(:new).and_return(service) }

  it "calls WeeklyDigestGenerator for the user and week" do
    described_class.perform_now(user.id, week_start.to_s)
    expect(Reporting::WeeklyDigestGenerator).to have_received(:new)
      .with(user: user, week_start: week_start)
    expect(service).to have_received(:call)
  end

  it "defaults to current week when no date given" do
    travel_to(week_start) do
      described_class.perform_now(user.id)
      expect(Reporting::WeeklyDigestGenerator).to have_received(:new)
        .with(user: user, week_start: week_start)
    end
  end

  it "discards the job if user does not exist" do
    expect { described_class.perform_now(0) }.not_to raise_error
  end
end
