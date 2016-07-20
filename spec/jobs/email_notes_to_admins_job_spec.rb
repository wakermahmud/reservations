require 'spec_helper'

describe EmailNotesToAdminsJob, type: :job do
  def stub_scope_chain(res, *chain)
    final = chain.pop
    chain.each do |scope|
      allow(Reservation).to receive(scope).and_return(Reservation)
    end
    allow(Reservation).to receive(final).and_return(res)
  end

  shared_examples 'admin email' do |*scopes|
    it 'sends emails' do
      res = spy('Array', empty?: false)
      stub_scope_chain(res, *scopes)
      allow(res).to receive(:update_all)
        .with(notes_unsent: false).and_return([])
      expect(AdminMailer).to \
        receive_message_chain(:notes_reservation_notification, :deliver_now)
      described_class.perform_now
    end
    it 'gets the appropriate reservations' do
      expect(Reservation).to receive_message_chain(*scopes).and_return([])
      described_class.perform_now
    end
    it 'unsets the notes_unsent flag' do
      res = spy('Array', empty?: false)
      stub_scope_chain(res, *scopes)
      allow(AdminMailer).to \
        receive_message_chain(:notes_reservation_notification, :deliver_now)
      expect(res).to receive(:update_all)
        .with(notes_unsent: false).at_least(:once)
      described_class.perform_now
    end
  end

  it_behaves_like 'admin email', :checked_out, :notes_unsent
  it_behaves_like 'admin email', :returned, :notes_unsent
end
