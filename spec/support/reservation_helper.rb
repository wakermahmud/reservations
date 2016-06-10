require 'spec_helper'

module ReservationHelper
  def mock_reservation(factory: nil, **attrs)
    attrs = FactoryGirl.attributes_for(factory).merge attrs if factory
    instance_spy('reservation', **attrs)
  end

  def stub_collection_methods(res, *scopes)
    allow(Reservation).to receive(:all).and_return(res)
    scopes.each { |s| allow(Reservation).to receive(s).and_return(res) }
  end
end
