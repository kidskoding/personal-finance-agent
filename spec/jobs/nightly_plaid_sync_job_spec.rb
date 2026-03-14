require 'rails_helper'

RSpec.describe NightlyPlaidSyncJob do
  let(:user) { create(:user) }

  before { allow(SyncTransactionsJob).to receive(:perform_later) }

  it "enqueues SyncTransactionsJob for each PlaidItem" do
    items = create_list(:plaid_item, 3, user: user)
    described_class.perform_now
    items.each do |item|
      expect(SyncTransactionsJob).to have_received(:perform_later).with(item.id)
    end
  end

  it "does nothing when there are no PlaidItems" do
    expect { described_class.perform_now }.not_to raise_error
    expect(SyncTransactionsJob).not_to have_received(:perform_later)
  end
end
