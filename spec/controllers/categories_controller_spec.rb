require 'spec_helper'

describe CategoriesController, type: :controller do
  before(:each) { mock_app_config }
  let!(:cat) { FactoryGirl.create(:category) }

  it_behaves_like 'calendarable', Category

  shared_examples 'success' do |action, template, *args|
    before do
      sign_in FactoryGirl.create(:admin)
      options = args.map { |a| [a, cat] }.to_h
      send(action, template, **options)
    end
    it { is_expected.to respond_with(:success) }
    it { is_expected.to render_template(template) }
    it { is_expected.not_to set_flash }
  end

  shared_examples 'redirect' do |action, template, *args|
    before do
      sign_in FactoryGirl.create(:user)
      options = args.map { |a| [a, cat] }.to_h
      send(action, template, **options)
    end
    it { is_expected.to redirect_to(root_url) }
    it { is_expected.to set_flash }
  end

  describe 'GET index' do
    let!(:inactive_cat) do
      FactoryGirl.create(:category, deleted_at: Time.zone.today - 1)
    end
    context 'user is admin' do
      before { sign_in FactoryGirl.create(:admin) }
      it_behaves_like 'success', :get, :index
      it 'populates an array of active categories' do
        get :index
        expect(assigns(:categories)).to eq([cat])
      end
      context 'show_deleted' do
        it 'populates an array of all categories' do
          get :index, show_deleted: true
          expect(assigns(:categories)).to eq([cat, inactive_cat])
        end
      end
    end
    context 'user is not admin' do
      it_behaves_like 'redirect', :get, :index
    end
  end

  describe 'GET show' do
    context 'user is admin' do
      it_behaves_like 'success', :get, :show, :id
      it 'sets category to the selected category' do
        sign_in FactoryGirl.create(:admin)
        get :show, id: cat
        expect(assigns(:category)).to eq(cat)
      end
    end
    context 'user is not admin' do
      it_behaves_like 'redirect', :get, :show, :id
    end
  end

  describe 'GET new' do
    context 'is admin' do
      it_behaves_like 'success', :get, :new
      it 'assigns a new category to category' do
        sign_in FactoryGirl.create(:admin)
        get :new
        expect(assigns(:category)).to be_new_record
        expect(assigns(:category).is_a?(Category)).to be_truthy
      end
    end
    context 'not admin' do
      it_behaves_like 'redirect', :get, :new
    end
  end
  describe 'POST create' do
    context 'is admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end
      context 'with valid attributes' do
        before(:each) do
          post :create, category: FactoryGirl.attributes_for(:category)
        end
        it 'saves a new category to the database' do
          expect do
            post :create, category: FactoryGirl.attributes_for(:category)
          end.to change(Category, :count).by(1)
        end
        it { is_expected.to redirect_to(Category.last) }
        it { is_expected.to set_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          post :create,
               category: FactoryGirl.attributes_for(:category, name: nil)
        end
        it 'fails to save a new category' do
          expect do
            post :create,
                 category: FactoryGirl.attributes_for(:category, name: nil)
          end.not_to change(Category, :count)
        end
        it { is_expected.to set_flash }
        it { is_expected.to render_template(:new) }
      end
    end
    context 'not admin' do
      it 'redirects to root url' do
        sign_in FactoryGirl.create(:user)
        post :create, category: FactoryGirl.attributes_for(:category)
        expect(response).to redirect_to(root_url)
      end
    end
  end
  describe 'GET edit' do
    context 'is admin' do
      it_behaves_like 'success', :get, :edit, :id
      it 'sets category to the selected category' do
        sign_in FactoryGirl.create(:admin)
        get :edit, id: cat
        expect(assigns(:category)).to eq(cat)
      end
    end
    context 'not admin' do
      it_behaves_like 'redirect', :get, :edit, :id
    end
  end
  describe 'PUT update' do
    context 'is admin' do
      before(:each) do
        sign_in FactoryGirl.create(:admin)
      end
      context 'with valid attributes' do
        before(:each) do
          put :update,
              id: cat,
              category: FactoryGirl.attributes_for(:category, name: 'Updated')
        end
        it 'sets category to the correct category' do
          expect(assigns(:category)).to eq(cat)
        end
        it 'saves new attributes to the database' do
          cat.reload
          expect(cat.name).to eq('Updated')
        end
        it { is_expected.to redirect_to(cat) }
        it { is_expected.to set_flash }
      end
      context 'with invalid attributes' do
        before(:each) do
          put :update,
              id: cat,
              category: FactoryGirl.attributes_for(:category,
                                                   name: nil,
                                                   max_per_user: 10)
        end
        it 'does not update attributes of category in the database' do
          cat.reload
          expect(cat.name).not_to be_nil
          expect(cat.max_per_user).not_to eq(10)
        end
        it { is_expected.to render_template(:edit) }
        it { is_expected.not_to set_flash }
      end
    end
  end
end
