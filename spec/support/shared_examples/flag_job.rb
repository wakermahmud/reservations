require 'spec_helper'

shared_examples_for 'flag job' do |attr, scope|
  include ReservationHelper
  it 'updates the reservations status' do
    res = mock_reservation
    stub_collection_methods([res], scope)
    described_class.perform_now
    expect(res).to have_received(:update_attributes).with(attr)
  end
  it 'logs the update' do
    res = mock_reservation
    stub_collection_methods([res], scope)
    expect(Rails.logger).to receive(:info).at_least(:once)
    described_class.perform_now
  end
  it 'collects the appropriate reservations' do
    expect(Reservation).to receive(scope).and_return([])
    described_class.perform_now
  end
end
