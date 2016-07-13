module UserMocker
  FIND_ACTIONS = [:find_by_id, :find]

  def mock_user(role = :user, traits: [], **attrs)
    traits.map! { |trait, *args| ["user_#{trait}".to_sym, *args] }
    attrs = FactoryGirl.attributes_for(role).merge attrs if role
    instance_spy('user', **attrs).tap do |u|
      traits.each { |trait, *args| send(trait, u, *args) }
    end
  end

  def mock_user_sign_in(user = mock_user)
    pass_app_setup_check
    user_findable(user)
    allow(request.env['warden']).to receive(:authenticate!).and_return(user)
    # necessary for permissions to work
    allow(ApplicationController).to receive(:current_user).and_return(user)
    allow(Ability).to receive(:new).and_return(Ability.new(user))
    allow_any_instance_of(described_class).to \
      receive(:current_user).and_return(user)
  end

  private

  def pass_app_setup_check
    allow(AppConfig).to receive(:first).and_return(true) unless AppConfig.first
    allow(User).to receive(:count).and_return(1) unless User.first
  end

  def user_findable(user)
    FIND_ACTIONS.each do |a|
      allow(User).to receive(a).with(user.id).and_return(user)
      allow(User).to receive(a).with(user.id.to_s).and_return(user)
    end
  end
end
