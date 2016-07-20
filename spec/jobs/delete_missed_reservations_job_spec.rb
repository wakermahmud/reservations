require 'spec_helper'

describe DeleteMissedReservationsJob, type: :job do
  it 'deletes appropriate reservations' do
    mock_app_config(res_exp_time: 5)
    FactoryGirl.create(:missed_reservation,
                       start_date: Time.zone.today - 11.days,
                       due_date: Time.zone.today - 10.days)
    missed = FactoryGirl.create(:missed_reservation,
                                start_date: Time.zone.today - 4.days,
                                due_date: Time.zone.today - 3.days)
    valid = FactoryGirl.create(:valid_reservation)
    described_class.perform_now
    expect(Reservation.all).to match_array([missed, valid])
  end

  it "doesn't run when the res_exp_time parameter isn't set" do
    mock_app_config(res_exp_time: nil)
    expect(described_class).not_to receive(:run)
    described_class.perform_now
  end

  it 'collects the appropriate reservations' do
    mock_app_config(res_exp_time: 5)
    expect(Reservation).to receive(:deletable_missed).and_return([])
    described_class.perform_now
  end

  describe '#run' do
    it 'deletes reservations' do
      mock_app_config(res_exp_time: 5)
      res = ReservationMock.new
      allow(Reservation).to receive(:deletable_missed).and_return([res])
      described_class.perform_now
      expect(res).to have_received(:destroy)
    end

    it 'logs deletions' do
      mock_app_config(res_exp_time: 5)
      res = ReservationMock.new
      allow(Reservation).to receive(:deletable_missed).and_return([res])
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info)
        .with("Deleting reservation:\n #{res.inspect}").once
      described_class.perform_now
    end
  end
end
