require 'rails_helper'

RSpec.describe InitialPlaidSyncJob do
  let(:user) { create(:user) }
  let(:plaid_item) { create(:plaid_item, user: user) }
  let(:sync_service) { instance_double(Plaid::SyncTransactions, call: nil) }

  before { allow(Plaid::SyncTransactions).to receive(:new).and_return(sync_service) }

  it "calls SyncTransactions for the PlaidItem" do
    described_class.perform_now(plaid_item.id)
    expect(Plaid::SyncTransactions).to have_received(:new).with(plaid_item)
    expect(sync_service).to have_received(:call)
  end

  it "discards the job if PlaidItem does not exist" do
    expect { described_class.perform_now(0) }.not_to raise_error
  end
end
