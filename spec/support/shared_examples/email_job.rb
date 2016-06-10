require 'spec_helper'

shared_examples_for 'email job' do |ac_setting, scope|
  include ReservationHelper

  it 'sends emails' do
    mock_app_config(ac_setting)
    res = mock_reservation
    stub_collection_methods([res], scope)
    expect(UserMailer).to \
      receive_message_chain(:reservation_status_update, :deliver_now)
    described_class.perform_now
  end

  it 'gets the appropriate reservations' do
    mock_app_config(ac_setting)
    expect(Reservation).to receive(scope).and_return([])
    described_class.perform_now
  end

  it 'logs emails' do
    mock_app_config(ac_setting)
    res = mock_reservation
    stub_collection_methods([res], scope)
    expect(Rails.logger).to receive(:info).at_least(:once)
    described_class.perform_now
  end

  it "doesn't send emails when disabled" do
    expect(described_class).not_to receive(:run)
    described_class.perform_now
  end
end
