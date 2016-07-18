require 'spec_helper'
require 'concerns/linkable_spec.rb'

describe EquipmentItem, type: :model do
  include EquipmentItemMocker
  include UserMocker
  include ActiveSupport::Testing::TimeHelpers

  it_behaves_like 'linkable'

  describe 'basic validations' do
    subject(:item) { FactoryGirl.build(:equipment_item) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:equipment_model) }
  end

  describe 'serial' do
    it 'can be blank' do
      item = FactoryGirl.build_stubbed(:equipment_item, serial: '')
      expect(item.valid?).to be_truthy
    end
    it 'can be nil' do
      item = FactoryGirl.build_stubbed(:equipment_item, serial: nil)
      expect(item.valid?).to be_truthy
    end
    it 'cannot be the same as another item of the same model' do
      model = FactoryGirl.create(:equipment_model)
      FactoryGirl.create(:equipment_item, equipment_model: model, serial: 'a')
      item = FactoryGirl.build(:equipment_item, equipment_model: model,
                                                serial: 'a')
      expect(item.valid?).to be_falsey
    end
    it 'can be the same as another item of a different model' do
      FactoryGirl.create(:equipment_item, serial: 'a')
      item = FactoryGirl.build(:equipment_item, serial: 'a')
      expect(item.valid?).to be_truthy
    end
  end

  it 'saves an empty string value as nil for deleted_at field' do
    # this test passes even without the nilify_blanks call in the model, maybe
    # delete the call?
    item = FactoryGirl.build(:equipment_item)
    item.deleted_at = '   '
    item.save
    expect(item.deleted_at).to eq(nil)
  end

  describe '#active' do
    it 'returns active equipment items' do
      active = FactoryGirl.create(:equipment_item)
      FactoryGirl.create(:deactivated)
      expect(described_class.active).to match_array([active])
    end
  end

  describe '#for_eq_model' do
    it 'counts the number of items for the given model' do
      items = Array.new(2) { |i| mock_eq_item(equipment_model_id: i) }
      expect(described_class.for_eq_model(0, items)).to eq(1)
    end
  end

  describe '#status' do
    it "returns 'Deactivated' when deleted_at is set" do
      item = FactoryGirl.build_stubbed(:equipment_item,
                                       deleted_at: Time.zone.today)
      expect(item.status).to eq('Deactivated')
    end
    it "returns 'available' when active and not currently checked out" do
      item = FactoryGirl.build_stubbed(:equipment_item)
      expect(item.status).to eq('available')
    end
    it 'includes reservation information when checked out' do
      res = FactoryGirl.create(:checked_out_reservation)
      item = res.equipment_item
      expect(item.status).to include('checked out by')
    end
    it 'includes deactivation reason if it is set' do
      reason = 'because i can'
      item = FactoryGirl.build_stubbed(:equipment_item, 
                                       deleted_at: Time.zone.today,
                                       deactivation_reason: reason)
      expect(item.status).to include(reason)
    end
  end

  describe '#current_reservation' do
    it 'returns nil if no associated reservation' do
      item = FactoryGirl.build_stubbed(:equipment_item)
      expect(item.current_reservation).to be_nil
    end
    it 'returns the reservation that currently has the item checked out' do
      res = FactoryGirl.create(:checked_out_reservation)
      item = res.equipment_item
      expect(item.current_reservation).to eq(res)
    end
  end

  describe '#available?' do
    it 'returns true when the status is available' do
      item = FactoryGirl.create(:equipment_item)
      expect(item.available?).to be_truthy
    end
    it 'returns false if when the status is not available' do
      res = FactoryGirl.create(:checked_out_reservation)
      item = res.equipment_item
      expect(item.available?).to be_falsey
    end
  end

  describe '#deactivate' do
    let!(:user) { mock_user(:admin, md_link: 'md_link') }
    let!(:item) { FactoryGirl.build_stubbed(:equipment_item) }
    before do
      allow(item).to receive(:destroy)
      allow(item).to receive(:save!)
    end
    context 'with user and notes' do
      it 'saves the updated attributes' do
        item.deactivate(user: user, reason: 'reason')
        expect(item).to have_received(:save!)
      end
      it 'destroys the item' do
        item.deactivate(user: user, reason: 'reason')
        expect(item).to have_received(:destroy)
      end
      it 'prepends to the notes' do
        item.deactivate(user: user, reason: 'reason')
        expect(item.notes).to include('reason')
        expect(item.notes).to include(user.md_link)
      end
    end
    context 'without user' do
      it 'does nothing' do
        expect { item.deactivate(reason: 'reason') }.not_to change { item }
      end
    end
    context 'without notes' do
      it 'does nothing' do
        expect { item.deactivate(user: user) }.not_to change { item }
      end
    end
    context 'without parameters' do
      it 'does nothing' do
        expect { item.deactivate }.not_to change { item }
      end
    end
  end
end
