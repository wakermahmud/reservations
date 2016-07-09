require 'spec_helper'

describe CategoriesController, type: :controller do
  include CategoryMocker
  before(:each) { mock_app_config }

  it_behaves_like 'calendarable', Category

  describe 'GET index' do
    context 'user is admin' do
      before do
        mock_user_sign_in(mock_user(:admin))
        get :index
      end
      it_behaves_like 'successful request', :index
      it 'populates an array of active categories' do
        expect(Category).to receive(:active)
        get :index
      end
      context 'show_deleted' do
        it 'populates an array of all categories' do
          expect(Category).to receive(:all)
          get :index, show_deleted: true
        end
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        get :index
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET show' do
    context 'user is admin' do
      # NOTE: this may be a superfluous test; #show doesn't do much
      let!(:cat) { mock_category(traits: [:findable]) }
      before do
        mock_user_sign_in(mock_user(:admin))
        get :show, id: cat.id
      end
      it_behaves_like 'successful request', :show
      it 'sets category to the selected category' do
        expect(Category).to have_received(:find).with(cat.id.to_s)
          .at_least(:once)
        get :show, id: cat.id
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        get :show, id: 1
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'GET new' do
    context 'user is admin' do
      before do
        mock_user_sign_in(mock_user(:admin))
        get :new
      end
      it_behaves_like 'successful request', :new
      it 'assigns a new category to @category' do
        expect(assigns(:category)).to be_new_record
        expect(assigns(:category).is_a?(Category)).to be_truthy
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        get :new
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'POST create' do
    context 'user is admin' do
      before { mock_user_sign_in(mock_user(:admin)) }
      context 'successful save' do
        let!(:cat) { FactoryGirl.build_stubbed(:category) }
        before do
          allow(Category).to receive(:new).and_return(cat)
          allow(cat).to receive(:save).and_return(true)
          post :create, category: { name: 'Name' }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to(cat) }
      end
      context 'unsuccessful save' do
        let!(:cat) { mock_category }
        before do
          allow(Category).to receive(:new).and_return(cat)
          allow(cat).to receive(:save).and_return(false)
          post :create, category: { name: 'Name' }
        end
        it { is_expected.to set_flash[:error] }
        it { is_expected.to render_template(:new) }
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        post :create, category: { name: 'Name' }
      end
      it_behaves_like 'redirected request'
    end
  end

  describe 'PUT update' do
    context 'is admin' do
      before { mock_user_sign_in(mock_user(:admin)) }
      context 'successful update' do
        let!(:cat) { FactoryGirl.build_stubbed(:category) }
        before do
          allow(Category).to receive(:find).with(cat.id.to_s).and_return(cat)
          allow(cat).to receive(:update_attributes).and_return(true)
          put :update, id: cat.id, category: { id: 2 }
        end
        it { is_expected.to set_flash[:notice] }
        it { is_expected.to redirect_to(cat) }
      end
      context 'unsuccessful update' do
        let!(:cat) { mock_category(traits: [:findable]) }
        before do
          allow(cat).to receive(:update_attributes).and_return(false)
          put :update, id: cat.id, category: { id: 2 }
        end
        it { is_expected.to render_template(:edit) }
      end
    end
    context 'user is not admin' do
      before do
        mock_user_sign_in
        put :update, id: 1, category: { id: 2 }
      end
      it_behaves_like 'redirected request'
    end
  end
end
