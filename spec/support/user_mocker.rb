module UserMocker
  FIND_ACTIONS = [:find_by_id, :find].freeze

  def mock_user(role = :user, traits: [], **attrs)
    traits.map! { |trait, *args| ["user_#{trait}".to_sym, *args] }
    attrs = FactoryGirl.attributes_for(role).merge attrs if role
    instance_spy('user', **attrs).tap do |u|
      traits.each { |trait, *args| send(trait, u, *args) }
    end
  end


  def user_findable(user)
    FIND_ACTIONS.each do |a|
      allow(User).to receive(a).with(user.id).and_return(user)
      allow(User).to receive(a).with(user.id.to_s).and_return(user)
    end
  end
end
