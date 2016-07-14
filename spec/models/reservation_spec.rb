# All commented tests have never passed -- as far as we know the functionality
# works but more work is needed to ensure that we have test coverage.

require 'spec_helper'
require 'concerns/linkable_spec.rb'

describe Reservation, type: :model do
  include ReservationMocker
  include EquipmentModelMocker
  include UserMocker
  include ActiveSupport::Testing::TimeHelpers

  context 'class methods' do
    describe '#number_for' do
      it 'counts the number that overlap with today' do
        source =  Array.new(2) { mock_reservation }
        source.each do |r|
          allow(r).to receive(:overlaps_with).with(Time.zone.today)
            .and_return(true)
        end
        expect(Reservation.number_for(source)).to eq(2)
      end
      it 'counts the number that overlap with a given day' do
        date = Time.zone.today + 2.days
        source =  Array.new(2) { mock_reservation }
        allow(source.first).to receive(:overlaps_with).with(date).and_return(true)
        allow(source.last).to receive(:overlaps_with).with(date).and_return(false)
        expect(Reservation.number_for(source, date: date)).to eq(1)
      end
      it 'counts according to attribute hash' do
        attrs = { overdue: false }
        res = mock_reservation
        Reservation.number_for([res], **attrs)
        expect(res).to have_received(:attrs?).with(**attrs)
      end
    end

    describe '#number_for_date_range' do
      it 'counts the number of reservations over a date range' do
        date_range = Time.zone.today..(Time.zone.today + 2.days)
        source = []
        date_range.each do |date|
          expect(Reservation).to receive(:number_for).with(source, date: date)
        end
        Reservation.number_for_date_range(source, date_range)
      end
    end
  end

  context 'scopes' do
  end

  describe 'basic validations' do
    subject(:reservation) { FactoryGirl.build(:valid_reservation) }
    it { is_expected.to belong_to(:equipment_model) }
    it { is_expected.to belong_to(:reserver) }
    it { is_expected.to belong_to(:equipment_item) }
    it { is_expected.to belong_to(:checkout_handler) }
    it { is_expected.to belong_to(:checkin_handler) }
    it { is_expected.to validate_presence_of(:equipment_model) }
  end

  describe '#approved?' do
    it 'returns false if requested' do
      res = FactoryGirl.build_stubbed(:request)
      expect(res.approved?).to be_falsey
    end
    it 'returns false if denied' do
      res = FactoryGirl.build_stubbed(:request, status: 'denied')
      expect(res.approved?).to be_falsey
    end
    it 'returns true if approved' do
      res = FactoryGirl.build_stubbed(:request, status: 'reserved')
      expect(res.approved?).to be_truthy
    end
    it 'returns false if not a request' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      expect(res.approved?).to be_falsey
    end
  end

  describe '#flagged?' do
    let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
    it 'returns true when flagged' do
      res.flag(:request)
      expect(res.flagged?(:request)).to be_truthy
    end
    it 'returns false when not flagged' do
      expect(res.flagged?(:request)).to be_falsey
    end
    it 'returns false when the flag is undefined' do
      expect(res.flagged?(:garbage_flag)).to be_falsey
    end
  end

  describe '#attrs?' do
    it 'returns true when all attributes match' do
      attrs = { overdue: true, status: 'checked_out' }
      res = FactoryGirl.build_stubbed(:overdue_reservation)
      expect(res.attrs?(attrs)).to be_truthy
    end
    it 'returns false when one attribute does not match' do
      attrs = { overdue: true, status: 'checked_out' }
      res = FactoryGirl.build_stubbed(:checked_out_reservation)
      expect(res.attrs?(attrs)).to be_falsey
    end
  end

  describe '#overlaps_with' do
    let!(:res) do
     FactoryGirl.build_stubbed(:valid_reservation,
                               start_date: Time.zone.today,
                               due_date: Time.zone.today + 1.day)
    end
    it 'returns true when overlapping with date' do
      expect(res.overlaps_with(Time.zone.today)).to be_truthy
    end
    it 'returns false when not overlapping with date' do
      expect(res.overlaps_with(Time.zone.today - 1.day)).to be_falsey
    end
  end

  describe '#flag' do
    let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
    it 'flags the reservation' do
      expect { res.flag(:request) }.to \
        change{ res.flagged?(:request) }.from(false).to(true)
    end
    it 'does nothing if flag is undefined' do
      expect { res.flag(:garbage) }.not_to change{ res.flags }
    end
    it 'does nothing if flag is already set' do
      res.flag(:request)
      expect { res.flag(:request) }.not_to change{ res.flags }
    end
    it "doesn't save the reservation" do
      expect(res).not_to receive(:save)
      expect(res).not_to receive(:save!)
      res.flag(:request)
    end
  end

  describe '#unflag' do
    let!(:res) { FactoryGirl.build_stubbed(:valid_reservation) }
    it 'unflags the reservation' do
      res.flag(:request)
      expect { res.unflag(:request) }.to \
        change{ res.flagged?(:request) }.from(true).to(false)
    end
    it 'does nothing if flag is undefined' do
      expect { res.unflag(:garbage) }.not_to change{ res.flags }
    end
    it 'does nothing if not flagged' do
      expect { res.unflag(:request) }.not_to change{ res.flags }
    end
    it "doesn't save the reservation" do
      expect(res).not_to receive(:save)
      expect(res).not_to receive(:save!)
      res.flag(:request)
      res.unflag(:request)
    end
  end

  describe '#human_status' do 
    shared_examples 'returns the proper string' do |string, type, **attrs|
      it do
        res = FactoryGirl.build_stubbed(type, **attrs)
        expect(res.human_status).to eq(string)
      end
    end
    it_behaves_like 'returns the proper string', 'starts today',
                    :valid_reservation, start_date: Time.zone.today
    it_behaves_like 'returns the proper string', 'reserved',
                    :valid_reservation, start_date: Time.zone.today + 1.day
    it_behaves_like 'returns the proper string', 'due today',
                    :checked_out_reservation, due_date: Time.zone.today
    it_behaves_like 'returns the proper string', 'checked_out',
                    :checked_out_reservation, due_date: Time.zone.today + 1.day
    it_behaves_like 'returns the proper string', 'returned overdue',
                    :overdue_returned_reservation
    it_behaves_like 'returns the proper string', 'overdue', :overdue_reservation
    it_behaves_like 'returns the proper string', 'missed', :missed_reservation
    it_behaves_like 'returns the proper string', 'returned',
                    :checked_in_reservation
    it_behaves_like 'returns the proper string', 'requested', :request
    it_behaves_like 'returns the proper string', 'denied', :request,
                    status: 'denied'
  end

  describe '#end_date' do
    context 'if checked in' do
      it 'returns the checkin date' do
        res = FactoryGirl.build_stubbed(:checked_in_reservation)
        expect(res.end_date).to eq(res.checked_in)
      end
      it 'does not care if overdue' do
        res = FactoryGirl.build_stubbed(:overdue_returned_reservation)
        expect(res.end_date).to eq(res.checked_in)
      end
    end
    it 'returns today if actively overdue' do
      res = FactoryGirl.build_stubbed(:overdue_reservation)
      expect(res.end_date).to eq(Time.zone.today)
    end
    it 'returns due date for request' do
      res = FactoryGirl.build_stubbed(:request)
      expect(res.end_date).to eq(res.due_date)
    end
    it 'returns due date for reserved' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      expect(res.end_date).to eq(res.due_date)
    end
  end

  describe '#duration' do
    it 'returns the length of the reservation' do
      res = FactoryGirl.build_stubbed(:valid_reservation,
                                      start_date: Time.zone.today,
                                      due_date: Time.zone.today + 1.day)
      length = 2
      expect(res.duration).to eq(length)
    end
  end

  describe '#time_checked_out' do
    it 'returns the length of the checkout for returned reservations' do
      res = FactoryGirl.build_stubbed(:checked_in_reservation,
                                      start_date: Time.zone.today - 3.days,
                                      due_date: Time.zone.today - 1.day,
                                      checked_out: Time.zone.today - 3.days,
                                      checked_in: Time.zone.today - 2.days)
      length = 2
      expect(res.time_checked_out).to eq(length)
    end
  end

  describe '#late_fee' do
    it 'returns the correct late fee' do
      fee_per_day = 5
      days = 3
      expected = fee_per_day * days
      model = FactoryGirl.build_stubbed(:equipment_model, late_fee: fee_per_day)
      res = FactoryGirl.build_stubbed(:overdue_reservation,
                                      equipment_model: model,
                                      due_date: Time.zone.today - days.days)
      expect(res.late_fee).to eq(expected)
    end

    it 'returns 0 if not overdue' do
      res = FactoryGirl.build_stubbed(:checked_out_reservation)
      expect(res.late_fee).to eq(0)
    end

    it 'returns the cap if a cap is set' do
      fee_per_day = 5
      days = 3
      cap = 10
      model = FactoryGirl.build_stubbed(:equipment_model,
                                        late_fee: fee_per_day,
                                        late_fee_max: cap)
      res = FactoryGirl.build_stubbed(:overdue_reservation,
                                      equipment_model: model,
                                      due_date: Time.zone.today - days.days)
      expect(res.late_fee).to eq(model.late_fee_max)
    end
  end

  describe '#reserver' do
    it 'returns the associated user' do
      user = FactoryGirl.create(:user)
      res = FactoryGirl.build_stubbed(:valid_reservation, reserver_id: user.id)
      expect(res.reserver).to eq(user)
    end
    it "returns a dummy user if there isn't one" do
      res = FactoryGirl.build_stubbed(:valid_reservation, reserver_id: nil)
      expect(res.reserver).to be_new_record
    end
  end

  describe '#find_renewal_length' do
    let!(:length) { 5 }
    let!(:model) do 
      FactoryGirl.create(:equipment_model_with_item, max_renewal_length: length)
    end
    let!(:res) do 
      FactoryGirl.build_stubbed(:valid_reservation,
                                reserver: FactoryGirl.create(:user),
                                equipment_model: model)
    end
    it 'sets the correct renewal length' do
      expect(res.find_renewal_date).to eq(res.due_date + length.days)
    end
    context 'with a blackout date overlapping with the max renewal length' do
      it 'sets the correct renewal length' do
        FactoryGirl.create(:blackout,
                           start_date: res.due_date + 2.days,
                           end_date: res.due_date + length.days + 1.day)
        expect(res.find_renewal_date).to eq(res.due_date + 1.day)
      end
    end
    context 'with a blackout date going right up to the max renewal length' do
      it 'sets a length of 0' do
        FactoryGirl.create(:blackout,
                           start_date: res.due_date + 1.day,
                           end_date: res.due_date + length.days + 1.day)
        expect(res.find_renewal_date).to eq(res.due_date)
      end
    end
    context 'with a future reservation on the same model' do
      it 'sets the correct renewal length' do
        FactoryGirl.create(:reservation,
                           equipment_model: model,
                           start_date: res.due_date + 3.days,
                           due_date: res.due_date + length.days + 1.day)
        expect(res.find_renewal_date).to eq(res.due_date + 2.days)
      end
    end
  end

  describe '#eligible_for_renew?' do
    shared_examples 'not checked out' do |type|
      it 'returns false' do
        expect(FactoryGirl.build_stubbed(type).eligible_for_renew?).to be_falsey
      end
    end
    [:valid_reservation, :checked_in_reservation, :request].each do |type|
      it_behaves_like 'not checked out', type
    end
    it 'returns false when overdue' do
      res = FactoryGirl.build_stubbed(:overdue_reservation)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false when the reserver is banned' do
      user = FactoryGirl.create(:banned)
      res = FactoryGirl.build_stubbed(:checked_out_reservation, reserver: user)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false when the model cannot be renewed' do
      model = FactoryGirl.build_stubbed(:equipment_model,
                                        max_renewal_length: 0)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false when there are no items available' do
      model = FactoryGirl.build_stubbed(:equipment_model)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model)
      allow(model).to receive(:num_available_on).with(res.due_date + 1.day)
        .and_return(0)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false when renewed more than the max allowed times' do
      model = FactoryGirl.build_stubbed(:equipment_model)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model,
                                      times_renewed: 1)
      allow(model).to receive(:num_available_on).with(res.due_date + 1.day)
        .and_return(1)
      allow(model).to receive(:maximum_renewal_times).and_return(1)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns false before the eligibile period' do
      model = FactoryGirl.build_stubbed(:equipment_model)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model,
                                      due_date: Time.zone.today + 2.days)
      allow(model).to receive(:num_available_on).with(res.due_date + 1.day)
        .and_return(1)
      allow(model).to receive(:maximum_renewal_times).and_return(1)
      allow(model).to receive(:maximum_renewal_days_before_due).and_return(1)
      expect(res.eligible_for_renew?).to be_falsey
    end
    it 'returns true when eligible' do
      model = FactoryGirl.build_stubbed(:equipment_model)
      res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                      equipment_model: model,
                                      due_date: Time.zone.today + 2.days)
      allow(model).to receive(:num_available_on).with(res.due_date + 1.day)
        .and_return(1)
      allow(model).to receive(:maximum_renewal_times).and_return(1)
      allow(model).to receive(:maximum_renewal_days_before_due).and_return(3)
      expect(res.eligible_for_renew?).to be_truthy
    end
  end

  describe '#to_cart' do 
    it 'returns a new cart object corresponding to the reservation' do
      res = FactoryGirl.build_stubbed(:valid_reservation,
                                      reserver: FactoryGirl.create(:user))
      cart = res.to_cart
      expect(cart).to be_kind_of(Cart)
      expect(cart.start_date).to eq(res.start_date)
      expect(cart.due_date).to eq(res.due_date)
      expect(cart.reserver_id).to eq(res.reserver.id)
      expect(cart.items).to eq({ res.equipment_model_id => 1})
    end
  end

  describe '#renew' do
    let!(:user) { FactoryGirl.build_stubbed(:user) }
    it "doesn't renew if ineligible" do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      allow(res).to receive(:eligible_for_renew?).and_return(false)
      expect(res.renew(user)).to match(/not eligible/)
    end
    context 'eligible for renew' do
      let!(:res) do
        FactoryGirl.build_stubbed(:valid_reservation,
                                  times_renewed: 0,
                                  notes: '')
      end
      let!(:new_date) { Time.zone.today + 5.days }
      before do
        allow(res).to receive(:eligible_for_renew?).and_return(true)
        allow(res).to receive(:find_renewal_date).and_return(new_date)
        allow(res).to receive(:save)
      end
      it 'updates the due date' do
        old_date = res.due_date
        expect { res.renew(user) }.to change{ res.due_date }
          .from(old_date).to(new_date)
      end
      it 'increments times_renewed' do
        expect { res.renew(user) }.to change{ res.times_renewed }.by(1)
      end
      it 'updates the notes' do 
        time_string = Time.zone.now.to_s(:long)
        due_date_string = new_date.to_s(:long)
        allow(user).to receive(:md_link).and_return('md link')
        res.renew(user)
        expect(res.notes).to match(time_string)
        expect(res.notes).to match(due_date_string)
        expect(res.notes).to match(/md link/)
        expect(res.notes).to match(/Renewed/)
      end
      it 'returns nil when successful' do
        allow(res).to receive(:save).and_return(true)
        expect(res.renew(user)).to be_nil
      end
      it 'returns error if unsuccessful' do
        allow(res).to receive(:save).and_return(false)
        expect(res.renew(user)).to be_kind_of(String)
      end
    end
  end

  describe '#checkin' do
    let!(:handler) { FactoryGirl.build_stubbed(:checkout_person) }
    context 'no procedures' do
      let!(:res) { FactoryGirl.build_stubbed(:checked_out_reservation) }
      it 'sets the checkin handler' do
        expect { res.checkin(handler, {}, '') }.to \
          change { res.checkin_handler }.from(nil).to(handler)
      end
      it 'sets the checked in time' do
        # travel in order to freeze the time
        travel(-1.day) do
          expect { res.checkin(handler, {}, '') }.to \
            change { res.checked_in }.from(nil).to(Time.zone.now)
        end
      end
      it 'sets the status to returned' do
        expect { res.checkin(handler, {}, '') }.to \
          change { res.status }.from('checked_out').to('returned')
      end
      it 'updates the notes' do
        # FIXME:
        # might fall under overtesting by way of testing messages sent to self
        # but notes handling will be handled by a separate module in the future
        # alternatively just test that the notes change?
        # also applies to the next two tests
        new_notes = ''
        procedures = {}
        expect(res).to receive(:make_notes)
          .with('Checked in', new_notes, [], handler)
        res.checkin(handler, procedures, new_notes)
      end
      it 'returns the reservation' do
        expect(res.checkin(handler, {}, '')).to eq(res)
      end
    end
    context 'with completed procedures' do
      it 'sends no procedures to the notes' do
        # FIXME: this part of the method is really in need of refactoring
        procedure = FactoryGirl.create(:checkin_procedure)
        model = EquipmentModel.find(procedure.equipment_model.id)
        res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                        equipment_model: model)
        procedures = { procedure.id.to_s => '1' }
        expect(res).to receive(:make_notes).with('Checked in', '', [], handler)
        res.checkin(handler, procedures, '')
      end
    end
    context 'with incomplete procedures' do
      it 'sends the incomplete procedures to the notes' do
        # FIXME: this part of the method is really in need of refactoring
        procedure = FactoryGirl.create(:checkin_procedure)
        model = EquipmentModel.find(procedure.equipment_model.id)
        res = FactoryGirl.build_stubbed(:checked_out_reservation,
                                        equipment_model: model)
        incomplete = [procedure.step]
        expect(res).to receive(:make_notes)
          .with('Checked in', '', incomplete, handler)
        res.checkin(handler, {}, '')
      end
    end
    context 'overdue' do
      let!(:res) { FactoryGirl.create(:overdue_reservation) }
      before do
        ActionMailer::Base.perform_deliveries = false
        mock_app_config(admin_email: 'admin@email.com',
                        disable_user_emails: false)
      end
      it 'sends the admins an email' do
        expect(AdminMailer).to \
          receive_message_chain(:overdue_checked_in_fine_admin, :deliver_now)
        res.checkin(handler, {}, '')
      end
      it 'sends the user an email' do
        expect(UserMailer).to \
          receive_message_chain(:reservation_status_update, :deliver_now)
        res.checkin(handler, {}, '')
      end
    end
  end

  describe '#checkout' do
    let!(:handler) { FactoryGirl.build_stubbed(:checkout_person) }
    context 'no procedures' do
      let!(:model) { FactoryGirl.build_stubbed(:equipment_model) }
      let!(:item) do
        FactoryGirl.build_stubbed(:equipment_item, equipment_model: model)
      end
      let!(:res) do
        FactoryGirl.build_stubbed(:valid_reservation, equipment_model: model)
      end
      it 'sets the checkout handler' do
        expect { res.checkout(item, handler, {}, '') }.to \
          change { res.checkout_handler }.from(nil).to(handler)
      end
      it 'sets the checked out time' do
        # travel in order to freeze the time
        travel(-1.day) do
          expect { res.checkout(item, handler, {}, '') }.to \
            change { res.checked_out }.from(nil).to(Time.zone.now)
        end
      end
      it 'sets the status to checked_out' do
        expect { res.checkout(item, handler, {}, '') }.to \
          change { res.status }.from('reserved').to('checked_out')
      end
      it 'assigns the item' do
        # FIXME: fails
        expect { res.checkout(item, handler, {}, '') }.to \
          change { res.equipment_item_id }.from(nil).to(item.id)
      end
      it 'updates the notes' do
        # FIXME:
        # might fall under overtesting by way of testing messages sent to self
        # but notes handling will be handled by a separate module in the future
        # alternatively just test that the notes change?
        # also applies to the next two tests
        new_notes = ''
        procedures = {}
        expect(res).to receive(:make_notes)
          .with('Checked out', new_notes, [], handler)
        res.checkout(item, handler, procedures, new_notes)
      end
      it 'returns the reservation' do
        expect(res.checkout(item, handler, {}, '')).to eq(res)
      end
    end
    context 'with completed procedures' do
      it 'sends no procedures to the notes' do
        # FIXME: this part of the method is really in need of refactoring
        procedure = FactoryGirl.create(:checkout_procedure)
        model = EquipmentModel.find(procedure.equipment_model.id)
        item = FactoryGirl.build_stubbed(:equipment_item,
                                         equipment_model: model)
        res = FactoryGirl.build_stubbed(:valid_reservation,
                                        equipment_model: model)
        procedures = { procedure.id.to_s => '1' }
        expect(res).to receive(:make_notes).with('Checked out', '', [], handler)
        res.checkout(item, handler, procedures, '')
      end
    end
    context 'with incomplete procedures' do
      it 'sends the incomplete procedures to the notes' do
        # FIXME: this part of the method is really in need of refactoring
        procedure = FactoryGirl.create(:checkout_procedure)
        model = EquipmentModel.find(procedure.equipment_model.id)
        item = FactoryGirl.build_stubbed(:equipment_item,
                                         equipment_model: model)
        res = FactoryGirl.build_stubbed(:valid_reservation,
                                        equipment_model: model)
        incomplete = [procedure.step]
        expect(res).to receive(:make_notes)
          .with('Checked out', '', incomplete, handler)
        res.checkout(item, handler, {}, '')
      end
    end
  end

  describe '#archive' do
    let!(:archiver) { FactoryGirl.build_stubbed(:user) }
    it 'returns the reservation' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      expect(res.archive(archiver, '')).to eq(res)
    end
    context 'not checked in' do
      context 'not checked out' do
        it 'sets checked_out to now' do
          travel(-1.day) do
            res = FactoryGirl.build_stubbed(:valid_reservation)
            expect { res.archive(archiver, '') }.to change { res.checked_out }
              .from(nil).to(Time.zone.now)
          end
        end
      end
      it 'sets checked_in to now' do
        travel(-1.day) do
          res = FactoryGirl.build_stubbed(:checked_out_reservation)
          expect { res.archive(archiver, '') }.to change { res.checked_in }
            .from(nil).to(Time.zone.now)
        end
      end
      it 'updates the notes' do
        travel(-1.day) do
          res = FactoryGirl.build_stubbed(:checked_out_reservation)
          allow(archiver).to receive(:md_link).and_return('md link')
          note = 'note'
          archive_time = Time.zone.now.to_s(:long)
          res.archive(archiver, note)
          expect(res.notes).to include(note)
          expect(res.notes).to include('md link')
          expect(res.notes).to include(archive_time)
        end
      end
      it 'sets the status to archived' do
        res = FactoryGirl.build_stubbed(:checked_out_reservation)
        expect { res.archive(archiver, '') }.to change { res.status }
          .from('checked_out').to('archived')
      end
    end
    context 'checked in' do
      it 'does nothing' do
        res = FactoryGirl.build_stubbed(:checked_in_reservation)
        expect { res.archive(archiver, '') }.not_to change { res.status }
      end
    end
  end

  describe '#update' do
    let!(:user) { FactoryGirl.build_stubbed(:user) }
    it 'does nothing when no changes and no new notes' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      expect { res.update(user, {}, '') }.not_to change { res.notes }
    end
    it 'updates with given notes' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      res.update(user, {}, 'test_note') 
      expect(res.notes).to include('test_note')
    end
    it 'notes the editing user' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      allow(user).to receive(:md_link).and_return('md link')
      res.update(user, {}, 'test_note') 
      expect(res.notes).to include('md link')
    end
    shared_examples 'notes change with md link' do |factory, attr|
      it do
        old = FactoryGirl.create(factory)
        new = FactoryGirl.create(factory)
        res = FactoryGirl.build_stubbed(:valid_reservation, attr => old.id)
        res.update(user, { attr => new.id }, '')
        expect(res.notes).to include(old.md_link)
        expect(res.notes).to include(new.md_link)
      end
    end
    it_behaves_like 'notes change with md link', :user, :reserver_id
    it_behaves_like 'notes change with md link', :equipment_item,
                    :equipment_item_id
    shared_examples 'notes changed date' do |attr|
      it do
        old = Time.zone.today + 3.days
        new = Time.zone.today + 2.days
        res = FactoryGirl.build_stubbed(:valid_reservation, attr => old)
        res.update(user, { attr => new }, '')
        expect(res.notes).to include(old.to_s(:long))
        expect(res.notes).to include(new.to_s(:long))
      end
    end
    it_behaves_like 'notes changed date', :start_date
    it_behaves_like 'notes changed date', :due_date
    context 'changed to not overdue' do
      it 'notes the change' do
        res = FactoryGirl.build_stubbed(:overdue_reservation)
        new_date = Time.zone.today + 1.day
        res.update(user, { due_date: new_date }, '')
        expect(res.notes).to include('marked as not overdue')
      end
    end
    context 'changed to overdue' do
      it 'notes the change' do
        res = FactoryGirl.build_stubbed(:checked_out_reservation)
        new_date = Time.zone.today - 1.day
        res.update(user, { due_date: new_date }, '')
        expect(res.notes).not_to include('marked as not overdue')
        expect(res.notes).to include('marked as overdue')
      end
    end
  end

  describe '#make_notes' do
    let!(:user) { FactoryGirl.build_stubbed(:user) }
    it 'notes the user' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      allow(user).to receive(:md_link).and_return('md link')
      res.make_notes('', '', [], user)
      expect(res.notes).to include('md link')
    end
    it 'notes the type of action' do
      res = FactoryGirl.build_stubbed(:valid_reservation)
      res.make_notes('procedure', '', [], user)
      expect(res.notes).to include('procedure')
    end
    context 'no new notes or incomplete procedures' do
      it 'sets notes_unsent to false' do
        res = FactoryGirl.build_stubbed(:valid_reservation)
        res.make_notes('', '', [], user)
        expect(res.notes_unsent).to be_falsey
      end
      it 'notes that all procedures were completed' do
        res = FactoryGirl.build_stubbed(:valid_reservation)
        res.make_notes('', '', [], user)
        expect(res.notes).to include('All procedures were performed')
      end
    end
    context 'new notes' do
      it 'adds them' do
        res = FactoryGirl.build_stubbed(:valid_reservation)
        res.make_notes('', 'test_note', [], user)
        expect(res.notes).to include('test_note')
      end
    end
    context 'incomplete procedures' do
      it 'adds them' do
        res = FactoryGirl.build_stubbed(:valid_reservation)
        res.make_notes('', '', ['incomplete'], user)
        expect(res.notes).to include('procedures were not performed')
        expect(res.notes).to include('incomplete')
      end
    end
  end

  #context 'when valid' do
  #  it { is_expected.to be_valid }
  #  it 'should have a valid reserver' do
  #    expect(reservation.reserver).not_to be_nil
  #    expect(reservation.reserver.first_name).not_to eq('Deleted')
  #    expect(reservation.reserver.role).not_to eq('Banned')
  #  end
  #  it { expect(reservation.equipment_model).to_not be_nil }
  #  it { expect(reservation.start_date).to_not be_nil }
  #  it { expect(reservation.due_date).to_not be_nil }
  #  it 'should save' do
  #    expect(reservation.save).to be_truthy
  #    expect(Reservation.all.size).to eq(1)
  #    expect(Reservation.all.first).to eq(reservation)
  #  end
  #  it 'can be updated' do
  #    reservation.due_date = Time.zone.today + 2.days
  #    expect(reservation.save).to be_truthy
  #  end
  #  it 'passes custom validations' do
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.matched_item_and_model).to be_nil
  #    expect(reservation.available).to be_nil
  #    expect(reservation.check_banned).to be_nil
  #    expect(reservation.validate).to eq([])
  #  end
  #  it { is_expected.to respond_to(:fake_reserver_id) }
  #  it { is_expected.to respond_to(:late_fee) }
  #  it { is_expected.to respond_to(:find_renewal_date) }
  #end

  #context 'when not checked out' do
  #  it { expect(reservation.reserved?).to be_truthy }
  #  # currently returns true; doesn't check for checked out
  #  it { expect(reservation).to_not be_eligible_for_renew }
  #end

  #context 'when checked out' do
  #  subject(:reservation) { FactoryGirl.build(:checked_out_reservation) }

  #  it { expect(reservation.checked_out?).to be_truthy }
  #  it { is_expected.to be_eligible_for_renew }
  #end

  #context 'when checked in' do
  #  subject(:reservation) { FactoryGirl.build(:checked_in_reservation) }

  #  it { expect(reservation.returned?).to be_truthy }
  #  it { is_expected.not_to be_eligible_for_renew }
  #end

  #context 'when overdue' do
  #  subject(:reservation) { FactoryGirl.build(:overdue_reservation) }

  #  it { expect(reservation.overdue).to be_truthy }
  #  it { is_expected.not_to be_eligible_for_renew }
  #end

  #context 'when missed' do
  #  subject(:reservation) { FactoryGirl.build(:missed_reservation) }

  #  it { expect(reservation.missed?).to be_truthy }
  #  it { is_expected.not_to be_eligible_for_renew }
  #end

  #context 'when there is no availability on the next day' do
  #  before do
  #    mod = FactoryGirl.create :equipment_model_with_item
  #    @res = FactoryGirl.create :checked_out_reservation, equipment_model: mod
  #    FactoryGirl.create :reservation, equipment_model: mod,
  #                                     start_date: @res.due_date + 1.day,
  #                                     due_date: @res.due_date + 2.days
  #  end

  #  subject(:reservation) { @res }

  #  it { is_expected.not_to be_eligible_for_renew }
  #end

  #context 'when the reserver is banned' do
  #  before do
  #    user = FactoryGirl.create :user
  #    @res = FactoryGirl.create :checked_out_reservation, reserver: user
  #    user.update_attributes(role: 'banned', view_mode: 'banned')
  #  end

  #  subject(:reservation) { @res }

  #  it { is_expected.not_to be_eligible_for_renew }
  #end

  #context 'when empty' do
  #  subject(:reservation) do
  #    FactoryGirl.build(:reservation, equipment_model: nil)
  #  end

  #  it { is_expected.not_to be_valid }
  #  it 'should not save' do
  #    expect(reservation.save).to be_falsey
  #    expect(Reservation.all.size).to eq(0)
  #  end
  #  it 'cannot be updated' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_falsey
  #  end
  #  # it 'fails appropriate validations' do
  #  #   reservation.should_not be_not_empty
  #  #   Reservation.validate_set(reservation.reserver,
  #  #                            [] << reservation).should_not == [] #fails
  #  # end
  #  # it 'passes other custom validations' do
  #  #   reservation.should be_no_overdue_reservations
  #  #   reservation.should be_start_date_before_due_date
  #  #   reservation.should be_not_in_past
  #  #   reservation.should be_matched_item_and_model
  #  #   reservation.should be_duration_allowed # fails: tries to run
  #  # validations on nil
  #  #   reservation.should be_start_date_is_not_blackout
  #  #   reservation.should be_due_date_is_not_blackout
  #  #   reservation.should be_available #fails: tries to run validations on nil
  #  #   reservation.should be_quantity_eq_model_allowed # fails: tries to run
  #  # validations on nil
  #  #   reservation.should be_quantity_cat_allowed # fails: tries to run
  #  # validations on nil
  #  # end
  #  it 'updates with equipment model' do
  #    reservation.equipment_model = FactoryGirl.create(:equipment_model)
  #    FactoryGirl.create(:equipment_item,
  #                       equipment_model: reservation.equipment_model)
  #    expect(reservation.save).to be_truthy
  #    expect(reservation).to be_valid
  #    expect(Reservation.all.size).to eq(1)
  #  end
  #end

  #context 'editing the due date' do
  #  context 'while not checked out' do
  #    shared_examples_for 'does not affect the overdue status' do |res_type|
  #      subject(:reservation) do
  #        r = FactoryGirl.build(res_type)
  #        r.save(validate: false)
  #        r
  #      end

  #      it 'regardless of date' do
  #        reservation.due_date = Time.zone.today - 1.day
  #        expect { reservation.save }.not_to change { reservation.overdue }
  #        reservation.due_date = Time.zone.today + 1.day
  #        expect { reservation.save }.not_to change { reservation.overdue }
  #      end
  #    end

  #    statuses = [:valid_reservation, :checked_in_reservation, :request,
  #                :missed_reservation]
  #    statuses.each do |type|
  #      it_behaves_like 'does not affect the overdue status', type
  #    end
  #  end

  #  context 'while checked out and not overdue' do
  #    subject(:reservation) do
  #      r = FactoryGirl.build(:checked_out_reservation,
  #                            start_date: Time.zone.today - 2.days)
  #      r.save(validate: false)
  #      r
  #    end

  #    it { expect(reservation.overdue).to be_falsey }

  #    it 'changes overdue attribute if due date is in past' do
  #      reservation.update_attributes(due_date: Time.zone.today - 1.day)
  #      expect(reservation.overdue).to be_truthy
  #    end

  #    it 'does not change overdue attribute if due date is not in past' do
  #      reservation.update_attributes(due_date: Time.zone.today + 2.days)
  #      expect(reservation.overdue).to be_falsey
  #    end
  #  end

  #  context 'while checked out and overdue' do
  #    subject(:reservation) do
  #      r = FactoryGirl.build(:overdue_reservation,
  #                            start_date: Time.zone.today - 2.days)
  #      r.save(validate: false)
  #      r
  #    end

  #    it { expect(reservation.overdue).to be_truthy }

  #    it 'does not change overdue attribute if due date is in past' do
  #      reservation.update_attributes(due_date: Time.zone.today - 1.day)
  #      expect(reservation.overdue).to be_truthy
  #    end

  #    it 'changes overdue attribute if due date is not in past' do
  #      reservation.update_attributes(due_date: Time.zone.today + 2.days)
  #      expect(reservation.overdue).to be_falsey
  #    end
  #  end
  #end

  #context 'with past due date' do
  #  subject(:reservation) do
  #    FactoryGirl.build(:valid_reservation, due_date: Time.zone.today - 1.day)
  #  end

  #  it { is_expected.not_to be_valid }
  #  it 'should not save' do
  #    expect(reservation.save).to be_falsey
  #    expect(Reservation.all.size).to eq(0)
  #  end
  #  it 'cannot be updated' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_falsey
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.start_date_before_due_date).not_to be_nil
  #    expect(reservation.not_in_past).not_to be_nil
  #  end
  #  it 'passes other custom validations' do
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.matched_item_and_model).to be_nil
  #    expect(reservation.available).to be_nil
  #    expect(reservation.check_banned).to be_nil
  #    expect(reservation.validate).to eq([])
  #  end
  #  it 'updates with fixed date' do
  #    reservation.due_date = Time.zone.today + 2.days
  #    expect(reservation.save).to be_truthy
  #    expect(reservation).to be_valid
  #    expect(Reservation.all.size).to eq(1)
  #  end
  #end

  #context 'with blacked out start date' do
  #  let!(:blackout) do
  #    FactoryGirl.create(:blackout,
  #                       start_date: reservation.start_date,
  #                       end_date: reservation.due_date)
  #  end

  #  it { is_expected.to be_valid }
  #  it 'should save' do
  #    expect(reservation.save).to be_truthy
  #    expect(Reservation.all.size).to eq(1)
  #  end
  #  it 'can be updated' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_truthy
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.validate).not_to eq([])
  #  end
  #  it 'passes other custom validations' do
  #    expect(reservation.not_in_past).to be_nil
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.matched_item_and_model).to be_nil
  #    expect(reservation.available).to be_nil
  #    expect(reservation.check_banned).to be_nil
  #  end
  #end

  #context 'with no user' do
  #  subject(:reservation) do
  #    FactoryGirl.build(:valid_reservation, reserver: nil)
  #  end

  #  it 'should have a deleted user' do
  #    expect(reservation.reserver).not_to be_nil
  #    expect(reservation.reserver.first_name).to eq('Deleted')
  #  end
  #  it { is_expected.to be_valid }
  #end

  #context 'when user has overdue reservation' do
  #  subject(:reservation) { FactoryGirl.build(:valid_reservation) }
  #  let(:overdue_reserver) { reservation.reserver }
  #  let!(:overdue) do
  #    o = FactoryGirl.build(:overdue_reservation, reserver: overdue_reserver)
  #    o.save(validate: false)
  #    o
  #  end

  #  it { is_expected.to be_valid }
  #  it 'should not save' do
  #    expect(reservation.save).to be_truthy
  #    expect(Reservation.all.size).to eq(2)
  #    expect(Reservation.all.first).to eq(overdue)
  #  end
  #  it 'can be updated' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_truthy
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.validate).not_to eq([])
  #  end
  #  it 'passes other custom validations' do
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.matched_item_and_model).to be_nil
  #    expect(reservation.available).to be_nil
  #    expect(reservation.not_in_past).to be_nil
  #    expect(reservation.check_banned).to be_nil
  #  end
  #end

  #context 'with banned user' do
  #  let(:banned) { FactoryGirl.create(:banned) }
  #  subject(:reservation) do
  #    FactoryGirl.build(:valid_reservation, reserver_id: banned.id)
  #  end

  #  it { is_expected.not_to be_valid }
  #  it 'should not save' do
  #    expect(reservation.save).to be_falsey
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.validate).not_to eq([])
  #  end
  #  it 'passes other custom validations' do
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.matched_item_and_model).to be_nil
  #    expect(reservation.available).to be_nil
  #    expect(reservation.not_in_past).to be_nil
  #  end
  #end

  #context 'with equipment item available problems' do
  #  before(:each) do
  #    FactoryGirl.create(:checked_out_reservation,
  #                       equipment_model: reservation.equipment_model,
  #                       start_date: reservation.start_date,
  #                       due_date: reservation.due_date,
  #                       equipment_item: reservation.equipment_model
  #                         .equipment_items.first)
  #  end

  #  it { is_expected.not_to be_valid }
  #  it 'should not save' do
  #    expect(reservation.save).to be_falsey
  #    expect(Reservation.all.size).to eq(1)
  #  end
  #  it 'cannot be updated' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_falsey
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.available).not_to eq([])
  #    expect(reservation).not_to be_valid
  #  end

  #  it 'passes other custom validations' do
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.not_in_past).to be_nil
  #  end
  #end

  #context 'with equipment item/model matching problems' do
  #  subject(:reservation) do
  #    r = FactoryGirl.build(:valid_reservation)
  #    r.equipment_item = FactoryGirl.create(:equipment_item)
  #    r
  #  end

  #  it { is_expected.not_to be_valid }
  #  it 'should not save' do
  #    expect(reservation.save).to be_falsey
  #    expect(Reservation.all.size).to eq(0)
  #  end
  #  it 'cannot be updated' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_falsey
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.matched_item_and_model).not_to be_nil
  #  end
  #  it 'passes other custom validations' do
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.not_in_past).to be_nil
  #    expect(reservation.check_banned).to be_nil
  #    expect(reservation.validate).to eq([])
  #  end
  #end

  #context 'with duration problems' do
  #  subject(:reservation) do
  #    r = FactoryGirl.build(:valid_reservation)
  #    r.equipment_model.category.max_checkout_length = 1
  #    r.equipment_model.category.save
  #    r.due_date = Time.zone.today + 3.days
  #    r
  #  end

  #  it { is_expected.to be_valid }
  #  it 'should save' do
  #    expect(reservation.save).to be_truthy
  #    expect(Reservation.all.size).to eq(1)
  #  end
  #  it 'can update' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_truthy
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.validate).not_to eq([])
  #  end
  #  it 'passes other custom validations' do
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.matched_item_and_model).to be_nil
  #    expect(reservation.available).to be_nil
  #    expect(reservation.not_in_past).to be_nil
  #    expect(reservation.check_banned).to be_nil
  #  end
  #end

  #context 'with category quantity problems' do
  #  subject(:reservation) do
  #    r = FactoryGirl.create(:valid_reservation)
  #    r.equipment_model.category.max_per_user = 1
  #    r.equipment_model.max_per_user = 2
  #    r.equipment_model.save
  #    r.equipment_model.category.save
  #    FactoryGirl.create(:equipment_item, equipment_model: r.equipment_model)
  #    FactoryGirl.create(:equipment_item, equipment_model: r.equipment_model)
  #    FactoryGirl.create(:reservation,
  #                       equipment_model: r.equipment_model,
  #                       reserver: r.reserver)
  #    r
  #  end

  #  it { is_expected.to be_valid }
  #  it 'should save' do
  #    expect(reservation.save).to be_truthy
  #    expect(Reservation.all.size).to eq(2)
  #  end
  #  it 'can be updated' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_truthy
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.validate).not_to eq([])
  #  end
  #  it 'passes other custom validations' do
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.matched_item_and_model).to be_nil
  #    expect(reservation.available).to be_nil
  #    expect(reservation.not_in_past).to be_nil
  #    expect(reservation.check_banned).to be_nil
  #  end
  #end

  #context 'with equipment model quantity problems' do
  #  subject(:reservation) do
  #    r = FactoryGirl.create(:valid_reservation)
  #    r.equipment_model.category.max_per_user = 1
  #    r.equipment_model.max_per_user = 1
  #    r.equipment_model.save
  #    r.equipment_model.category.save
  #    FactoryGirl.create(:equipment_item, equipment_model: r.equipment_model)
  #    FactoryGirl.create(:equipment_item, equipment_model: r.equipment_model)
  #    FactoryGirl.create(:valid_reservation,
  #                       equipment_model: r.equipment_model,
  #                       reserver: r.reserver)
  #    r
  #  end

  #  it { is_expected.to be_valid }
  #  it 'should save' do
  #    expect(reservation.save).to be_truthy
  #    expect(Reservation.all.size).to eq(2)
  #  end
  #  it 'can be updated' do
  #    reservation.start_date = Time.zone.today + 1.day
  #    expect(reservation.save).to be_truthy
  #  end
  #  it 'fails appropriate validations' do
  #    expect(reservation.validate).not_to eq([])
  #  end
  #  it 'passes other custom validations' do
  #    expect(reservation.start_date_before_due_date).to be_nil
  #    expect(reservation.not_empty).to be_nil
  #    expect(reservation.matched_item_and_model).to be_nil
  #    expect(reservation.available).to be_nil
  #    expect(reservation.not_in_past).to be_nil
  #    expect(reservation.check_banned).to be_nil
  #  end
  #end

  #context 'when in a final status' do
  #  subject(:reservation) do
  #    FactoryGirl.create(:valid_reservation)
  #  end
  #  it 'the status should not be able to be changed if denied' do
  #    reservation.update_attributes(status: 'denied')
  #    reservation.status = 'reserved'
  #    expect { reservation.save! }.to raise_error ActiveRecord::RecordInvalid
  #  end
  #  it 'the status should not be able to be changed if missed' do
  #    reservation.update_attributes(
  #      FactoryGirl.attributes_for(:missed_reservation)
  #    )
  #    reservation.status = 'reserved'
  #    expect { reservation.save! }.to raise_error ActiveRecord::RecordInvalid
  #  end
  #  it 'the status should not be able to be changed if returned' do
  #    reservation.update_attributes(
  #      FactoryGirl.attributes_for(:checked_in_reservation)
  #    )
  #    reservation.status = 'reserved'
  #    expect { reservation.save! }.to raise_error ActiveRecord::RecordInvalid
  #  end
  #end

  it_behaves_like 'linkable'
end
