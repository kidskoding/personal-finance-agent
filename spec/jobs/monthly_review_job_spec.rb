require 'rails_helper'

RSpec.describe MonthlyReviewJob do
  let(:user) { create(:user) }
  let(:date) { Date.new(2026, 3, 1) }
  let(:service) { instance_double(Reporting::MonthlyReviewGenerator, call: nil) }

  before { allow(Reporting::MonthlyReviewGenerator).to receive(:new).and_return(service) }

  it "calls MonthlyReviewGenerator for the user and date" do
    described_class.perform_now(user.id, date.to_s)
    expect(Reporting::MonthlyReviewGenerator).to have_received(:new)
      .with(user: user, date: date)
    expect(service).to have_received(:call)
  end

  it "defaults to today when no date given" do
    travel_to(date) do
      described_class.perform_now(user.id)
      expect(Reporting::MonthlyReviewGenerator).to have_received(:new)
        .with(user: user, date: date)
    end
  end

  it "discards the job if user does not exist" do
    expect { described_class.perform_now(0) }.not_to raise_error
  end
end
