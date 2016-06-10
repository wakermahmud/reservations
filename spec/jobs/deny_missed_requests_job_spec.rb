require 'spec_helper'

describe DenyMissedRequestsJob, type: :job do
  include ReservationHelper
  it_behaves_like 'email job', {}, :missed_requests
  it 'flags missed requests as denied and expired' do
    res = mock_reservation
    stub_collection_methods([res], :missed_requests)
    allow(UserMailer).to \
      receive_message_chain(:reservation_status_update, :deliver_now)
    described_class.perform_now
    expect(res).to have_received(:expire!)
  end
end
