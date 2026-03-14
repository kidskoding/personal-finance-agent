require 'rails_helper'

RSpec.describe FinancialAnalysisJob do
  let(:user) { create(:user) }
  let(:date) { Date.new(2026, 3, 1) }

  before do
    allow(Analysis::RecurringChargeDetector).to receive(:new).and_return(double(call: nil))
    allow(Analysis::CategoryBreakdown).to receive(:new).and_return(double(call: nil))
    allow(Analysis::MerchantBreakdown).to receive(:new).and_return(double(call: nil))
    allow(Analysis::SpendingSpikeDetector).to receive(:new).and_return(double(call: nil))
  end

  it "runs all analysis services for the user" do
    described_class.perform_now(user.id, date.to_s)
    expect(Analysis::RecurringChargeDetector).to have_received(:new).with(user: user)
    expect(Analysis::CategoryBreakdown).to have_received(:new).with(user: user, date: date)
    expect(Analysis::SpendingSpikeDetector).to have_received(:new).with(user: user, date: date)
  end

  it "defaults to today when no date given" do
    travel_to(date) do
      described_class.perform_now(user.id)
      expect(Analysis::CategoryBreakdown).to have_received(:new).with(user: user, date: date)
    end
  end

  it "discards the job if user does not exist" do
    expect { described_class.perform_now(0) }.not_to raise_error
  end
end
