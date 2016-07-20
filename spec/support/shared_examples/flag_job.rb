require 'spec_helper'

shared_examples_for 'flag job' do |attr, scope|
  it 'updates the reservations status' do
    res = ReservationMock.new
    allow(Reservation).to receive(scope).and_return([res])
    described_class.perform_now
    expect(res).to have_received(:update_attributes).with(attr)
  end
  it 'logs the update' do
    res = ReservationMock.new
    allow(Reservation).to receive(scope).and_return([res])
    expect(Rails.logger).to receive(:info).at_least(:once)
    described_class.perform_now
  end
  it 'collects the appropriate reservations' do
    expect(Reservation).to receive(scope).and_return([])
    described_class.perform_now
  end
end
