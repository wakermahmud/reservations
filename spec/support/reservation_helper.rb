require 'spec_helper'

module ReservationMocker
  def mock_reservation(factory: nil, traits: [], **attrs)
    traits.map! { |trait, *args| ["reservation_#{trait}".to_sym, *args] }
    attrs = FactoryGirl.attributes_for(factory).merge attrs if factory
    instance_spy('reservation', **attrs).tap do |res|
      traits.each { |trait, *args| send(trait, res, *args) }
    end
  end

  def stub_reservation_collection_methods(res, *scopes)
    allow(Reservation).to receive(:all).and_return(res)
    scopes.each { |s| allow(Reservation).to receive(s).and_return(res) }
  end

  private

  def reservation_for_user(res, user:)
    res_set = if user.reservations.is_a? Array
                user.reservations << res
              else
                [res]
              end
    allow(user).to receive(:reservations).and_return(res_set)
    allow(res).to receive(:reserver).and_return(user)
    # stub scopes ??
  end

  def reservation_findable(res)
    id = FactoryGirl.generate(:unique_id)
    allow(res).to receive(:id).and_return(id)
    allow(Reservation).to receive(:find).with(id).and_return(res)
    allow(Reservation).to receive(:find).with(id.to_s).and_return(res)
  end
end
