require 'spec_helper'

describe DeleteOldBlackoutsJob, type: :job do
  it 'deletes old blackouts' do
    mock_app_config(blackout_exp_time: 5)
    FactoryGirl.create(:blackout, start_date: Time.zone.today - 11.days,
                                  end_date: Time.zone.today - 10.days)
    valid = FactoryGirl.create(:blackout)
    described_class.perform_now
    expect(Blackout.all).to eq([valid])
  end

  it "doesn't run when the res_exp_time parameter isn't set" do
    mock_app_config(blackout_exp_time: nil)
    expect(described_class).not_to receive(:run)
    described_class.perform_now
  end

  describe '#run' do
    it 'deletes blackouts' do
      mock_app_config(blackout_exp_time: 5)
      blackout = instance_spy('blackout')
      allow(Blackout).to receive(:where).and_return([blackout])
      described_class.perform_now
      expect(blackout).to have_received(:destroy)
    end
    it 'logs deletions' do
      mock_app_config(blackout_exp_time: 5)
      blackout = instance_spy('blackout')
      allow(Blackout).to receive(:where).and_return([blackout])
      allow(Rails.logger).to receive(:info)
      expect(Rails.logger).to receive(:info)
        .with("Deleting old blackout:\n #{blackout.inspect}").once
      described_class.perform_now
    end
  end
end
