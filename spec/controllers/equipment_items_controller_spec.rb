require 'spec_helper'

describe EquipmentItemsController, type: :controller do
  include EquipmentItemMocker

  before(:each) { mock_app_config }

  it_behaves_like 'calendarable', EquipmentItem

  describe 'GET index' do
    context 'with admin user' do
      before do
        mock_user_sign_in(mock_user(:admin))
      end

      describe 'basic function' do
        before do
          get :index
        end
        it_behaves_like 'successful request', :index
      end

      it 'defaults to all active equipment items' do
        items = mock_eq_items
        expect(EquipmentItem).to receive(:active).and_return(items)
        get :index
      end

      context '@equipment_model set' do
        it 'restricts to the model' do
          item = mock_eq_item(traits: [:with_model], id: 1)
          model = item.equipment_model
          expect(model).to receive(:equipment_items).and_return(item)
          allow(item).to receive(:active)
          get :index, equipment_model_id: model.id
        end
      end

      context 'show_deleted set' do
        it 'gets all equipment items' do
          items = mock_eq_items
          # SMELL; shouldn't have to return none first
          expect(EquipmentItem).to receive(:all).and_return(EquipmentItem.none,
                                                            items)
          get :index, show_deleted: true
        end
      end
    end
    context 'with checkout person user' do
      before do
        mock_user_sign_in(mock_user(:checkout_person))
        get :index
      end
      it_behaves_like 'successful request', :index
    end
    context 'with normal user' do
      before do
        mock_user_sign_in
        get :index
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET show' do
    context 'with admin user' do
      let!(:item) { mock_eq_item(traits: [:findable]) }
      before do
        mock_user_sign_in(mock_user(:admin))
        get :show, id: item.id
      end
      it_behaves_like 'successful request', :show
      it 'sets to correct equipment item' do
        expect(EquipmentItem).to have_received(:find).with(item.id.to_s)
          .at_least(:once)
      end
    end
    context 'with normal user' do
      before do
        mock_user_sign_in
        get :show, id: 1
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET new' do
    context 'with admin user' do
      before do
        mock_user_sign_in(mock_user(:admin))
        get :new
      end
      it_behaves_like 'successful request', :new
      it 'assigns a new equipment item to @equipment_item' do
        expect(assigns(:equipment_item)).to be_new_record
        expect(assigns(:equipment_item)).to be_kind_of(EquipmentItem)
      end
      it 'sets equipment_model when one is passed through params' do
        model = mock_eq_model(traits: [:findable])
        expect(EquipmentItem).to receive(:new).with(equipment_model: model)
        get :new, equipment_model_id: model.id
      end
    end
    context 'with normal user' do
      before do
        mock_user_sign_in
        get :new
      end
      it_behaves_like 'redirected request', :new
    end
  end

  describe 'POST create' do
    context 'with admin user' do
      # FIXME: somehow the mock of current_user isn't working
      before { mock_user_sign_in(mock_user(:admin)) }
      let!(:model) { FactoryGirl.build_stubbed(:equipment_model) }
      let!(:item) { mock_eq_item(traits: [[:with_model, model: model]]) }
      context 'successful save' do
        before do
          allow(EquipmentModel).to receive(:new).and_return(item)
          allow(EquipmentModel).to receive(:last).and_return(item)
          allow(item).to receive(:save).and_return(true)
          post :create, equipment_item: { id: 1 }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to(model) }
        it 'saves item with notes' do
          expect(item).to have_received(:notes=)
          expect(item).to have_received(:save)
        end
      end
      context 'unsuccessful save' do
        before do
          allow(EquipmentModel).to receive(:new).and_return(item)
          allow(item).to receive(:save).and_return(false)
          post :create, equipment_item: { id: 1 }
        end
        it { is_expected.not_to set_flash[:error] }
        it { is_expected.to render_template(:new) }
      end
    end

    context 'with normal user' do
      before do
        mock_user_sign_in
        post :create, equipment_item: { id: 1 }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT update' do
    context 'with admin user' do
      before { mock_user_sign_in(mock_user(:admin)) }
      let!(:item) { FactoryGirl.build_stubbed(:equipment_item) }
      context 'successful update' do
        before do
          allow(EquipmentItem).to receive(:find).with(item.id.to_s)
            .and_return(item)
          allow(item).to receive(:update)
          allow(item).to receive(:save).and_return(true)
          put :update, id: item.id, equipment_item: { id: 3 }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to(item) }
      end
      context 'unsuccessful update' do
        before do
          allow(EquipmentItem).to receive(:find).with(item.id.to_s)
            .and_return(item)
          allow(item).to receive(:update)
          allow(item).to receive(:save).and_return(false)
          put :update, id: item.id, equipment_item: { id: 3 }
        end
        it { is_expected.not_to set_flash }
        it { is_expected.to render_template(:edit) }
      end
    end
    context 'with normal user' do
      before do
        mock_user_sign_in
        put :update, id: 1, equipment_item: { id: 3 }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT deactivate' do
    context 'with admin user' do
      before { mock_user_sign_in(mock_user(:admin)) }
      shared_examples 'unsuccessful' do |flash_type, **opts|
        let!(:model) { FactoryGirl.build_stubbed(:equipment_model) }
        let!(:item) do
          mock_eq_item(traits: [:findable], equipment_model: model)
        end
        before { put :deactivate, id: item.id, **opts }
        it { is_expected.to set_flash[flash_type] }
        it { is_expected.to redirect_to(model) }
        it 'does not deactivate the item' do
          expect(item).not_to have_received(:deactivate)
        end
      end
      it_behaves_like 'unsuccessful', :notice, deactivation_cancelled: true
      it_behaves_like 'unsuccessful', :notice, deactivation_cancelled: true,
                                               deactivation_reason: 'reason'
      it_behaves_like 'unsuccessful', :error
      context 'successful' do
        let!(:item) { mock_eq_item(traits: [:findable]) }
        before do
          request.env['HTTP_REFERER'] = '/referrer'
          allow(item).to receive(:current_reservation).and_return(false)
          put :deactivate, id: item.id, deactivation_reason: 'reason'
        end
        it { is_expected.to redirect_to('/referrer') }
        it 'deactivates the item' do
          expect(item).to have_received(:deactivate).with(user: nil,
                                                          reason: 'reason')
        end
      end
      context 'with reservation' do
        let!(:item) { mock_eq_item(traits: [:findable]) }
        let!(:res) { instance_spy('reservation') }
        before do
          request.env['HTTP_REFERER'] = '/referrer'
          allow(item).to receive(:current_reservation).and_return(res)
          put :deactivate, id: item.id, deactivation_reason: 'reason'
        end
        it 'archives the reservation' do
          expect(res).to have_received(:archive)
        end
      end
    end
    context 'with normal user' do
      before do
        mock_user_sign_in
        put :deactivate, id: 1, deactivation_reason: 'reason'
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT activate' do
    # FIXME: somehow the mock of current_user isn't working
    context 'with admin user' do
      let!(:item) { mock_eq_item(traits: [:findable]) }
      before do
        mock_user_sign_in(mock_user(:admin))
        request.env['HTTP_REFERER'] = '/referrer'
        put :activate, id: item.id
      end
      it { is_expected.to redirect_to('/referrer') }
      it 'updates the deactivation reason and the notes' do
        expect(item).to have_received(:update_attributes)
          .with(hash_including(:deactivation_reason, :notes))
      end
    end
    context 'with normal user' do
      before do
        mock_user_sign_in
        put :activate, id: 1
      end
      it_behaves_like 'redirected request'
    end
  end
end
