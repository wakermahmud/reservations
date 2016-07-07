require 'spec_helper'

describe EquipmentItemsController, type: :controller do
  before(:each) { mock_app_config }
  let!(:item) { FactoryGirl.create(:equipment_item) }
  let!(:deactivated_item) { FactoryGirl.create(:deactivated) }

  it_behaves_like 'calendarable', EquipmentItem

  def map_args(value, *args)
    args.map { |a| [a, value] }.to_h
  end

  shared_examples 'success' do |role, action, template, *args|
    before do
      sign_in FactoryGirl.create(role)
      send(action, template, map_args(item, *args))
    end
    it { is_expected.to respond_with(:success) }
    it { is_expected.to render_template(template) }
    it { is_expected.not_to set_flash }
  end

  shared_examples 'redirect when not admin' do |action, template, *args|
    before do
      sign_in FactoryGirl.create(:user)
      send(action, template, map_args(item.attributes, *args))
    end
    it { is_expected.to redirect_to(root_url) }
  end

  describe 'GET index' do
    context 'with admin user' do
      let!(:other_cat_active) { FactoryGirl.create(:equipment_item) }
      let!(:same_cat_inactive) do
        FactoryGirl.create(:equipment_item,
                           equipment_model: item.equipment_model,
                           deleted_at: Time.zone.today)
      end
      before do
        sign_in FactoryGirl.create(:admin)
      end

      it_behaves_like 'success', :admin, :get, :index

      context 'without show deleted' do
        context 'with @equipment_model set' do
          it 'populates an array of all active model-type equipment items' do
            get :index, equipment_model_id: item.equipment_model
            expect(assigns(:equipment_items)).to eq([item])
          end
        end
        context 'without @equipment_model set' do
          it 'populates an array of all active equipment items' do
            get :index
            expect(assigns(:equipment_items)).to \
              match_array([item, other_cat_active])
          end
        end
      end
      context 'with show deleted' do
        context 'with @equipment_model set' do
          it 'populates an array of all model-type equipment items' do
            get :index, equipment_model_id: item.equipment_model,
                        show_deleted: true
            expect(assigns(:equipment_items)).to \
              match_array([item, same_cat_inactive])
          end
        end
        context 'without @equipment_model set' do
          it 'populates an array of all equipment items' do
            get :index, show_deleted: true
            expect(assigns(:equipment_items)).to \
              match_array([item, same_cat_inactive, deactivated_item,
                           other_cat_active])
          end
        end
      end
    end
    context 'with checkout person user' do
      it_behaves_like 'success', :checkout_person, :get, :index
    end
    it_behaves_like 'redirect when not admin', :get, :index
  end

  describe 'GET show' do
    context 'with admin user' do
      it_behaves_like 'success', :admin, :get, :show, :id
      it 'sets to correct equipment item' do
        sign_in FactoryGirl.create(:admin)
        get :show, id: item
        expect(assigns(:equipment_item)).to eq(item)
      end
    end
    it_behaves_like 'redirect when not admin', :get, :show, :id
  end

  describe 'GET new' do
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        get :new
      end
      it_behaves_like 'success', :admin, :get, :new
      it 'assigns a new equipment item to @equipment_item' do
        expect(assigns(:equipment_item)).to be_new_record
        expect(assigns(:equipment_item)).to be_kind_of(EquipmentItem)
      end
      it 'sets equipment_model to nil when no equipment model is specified' do
        expect(assigns(:equipment_item).equipment_model).to be_nil
      end
      it 'sets equipment_model when one is passed through params' do
        get :new, equipment_model_id: item.equipment_model
        expect(assigns(:equipment_item).equipment_model).to \
          eq(item.equipment_model)
      end
    end
    it_behaves_like 'redirect when not admin', :get, :new
  end

  describe 'POST create' do
    context 'with admin user' do
      before { sign_in FactoryGirl.create(:admin) }
      context 'with valid attributes' do
        before do
          post :create,
               equipment_item: FactoryGirl
                 .attributes_for(:equipment_item,
                                 serial: 'Enter serial # (optional)',
                                 equipment_model_id: item.equipment_model.id)
        end
        it { is_expected.to set_flash }
        it { is_expected.to redirect_to(EquipmentItem.last.equipment_model) }
        it 'saves item with notes' do
          expect do
            post :create, equipment_item: FactoryGirl.attributes_for(
              :equipment_item, equipment_model_id: item.equipment_model.id
            )
          end.to change(EquipmentItem, :count).by(1)
          expect(EquipmentItem.last.notes).not_to be_empty
        end
      end
      context 'without valid attributes' do
        before do
          post :create,
               equipment_item: FactoryGirl.attributes_for(:equipment_item,
                                                          name: nil)
        end
        it { is_expected.not_to set_flash }
        it { is_expected.to render_template(:new) }
        it 'does not save' do
          expect do
            post :create,
                 equipment_item: FactoryGirl.attributes_for(:equipment_item,
                                                            name: nil)
          end.not_to change(EquipmentItem, :count)
        end
      end
    end
    it_behaves_like 'redirect when not admin', :post, :create, :equipment_item
  end

  describe 'GET edit' do
    context 'with admin user' do
      it_behaves_like 'success', :admin, :get, :edit, :id
      it 'sets @equipment_item to selected item' do
        sign_in FactoryGirl.create(:admin)
        get :edit, id: item
        expect(assigns(:equipment_item)).to eq(item)
      end
    end
    it_behaves_like 'redirect when not admin', :get, :edit, :id
  end

  describe 'PUT update' do
    context 'with admin user' do
      before { sign_in FactoryGirl.create(:admin) }
      context 'with valid attributes' do
        before do
          put :update,
              id: item,
              equipment_item: FactoryGirl.attributes_for(:equipment_item,
                                                         name: 'Obj')
        end
        it { is_expected.to set_flash }
        it { is_expected.to redirect_to(item) }
        it 'sets @equipment_item to selected item' do
          expect(assigns(:equipment_item)).to eq(item)
        end
        it 'updates attributes' do
          item.reload
          expect(item.name).to eq('Obj')
        end
        it 'updates notes' do
          expect { item.reload }.to change(item, :notes)
        end
      end
      context 'without valid attributes' do
        before do
          put :update,
              id: item,
              equipment_item: FactoryGirl.attributes_for(:equipment_item,
                                                         name: nil)
        end
        it { is_expected.not_to set_flash }
        it { is_expected.to render_template(:edit) }
        it 'does not update attributes' do
          item.reload
          expect(item.name).not_to be_nil
        end
      end
    end
    it_behaves_like 'redirect when not admin', :put, :update, :id,
                    :equipment_item
  end

  describe 'PUT deactivate' do
    before { request.env['HTTP_REFERER'] = '/referrer' }
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        put :deactivate, id: item, deactivation_reason: 'Because I can'
        item.reload
      end
      it { expect(response).to be_redirect }
      it { expect(item.deactivation_reason).to eq('Because I can') }
      it { expect(item.deleted_at).not_to be_nil }
      it 'changes the notes' do
        new_item = FactoryGirl.create(:equipment_item)
        put :deactivate, id: new_item, deactivation_reason: 'reason'
        expect { new_item.reload }.to change(new_item, :notes)
      end
    end
    it_behaves_like 'redirect when not admin', :put, :deactivate, :id
  end

  describe 'PUT activate' do
    before { request.env['HTTP_REFERER'] = '/referrer' }
    context 'with admin user' do
      before do
        sign_in FactoryGirl.create(:admin)
        put :activate, id: deactivated_item
        deactivated_item.reload
      end

      it { expect(response).to be_redirect }
      it { expect(deactivated_item.deactivation_reason).to be_nil }

      it 'changes the notes' do
        new_item = FactoryGirl.create(:equipment_item)
        put :activate, id: new_item
        expect { new_item.reload }.to change(new_item, :notes)
      end
    end
    it_behaves_like 'redirect when not admin', :put, :activate, :id
  end
end
