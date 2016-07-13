require 'spec_helper'

module CategoryMocker
  # traits are the private methods defined in this module
  # a findable cat is created with traits: [:findable]
  def mock_category(traits: [], **attrs)
    traits.map! { |trait, *args| ["category_#{trait}".to_sym, *args] }
    instance_spy('Category', **attrs).tap do |cat|
      traits.each { |trait, *args| send(trait, cat, *args) }
    end
  end

  def mock_categorys(count: 1, traits: [], **attrs)
    Array.new(count) { mock_eq_item(traits: traits, **attrs) }
  end

  def stub_category_collection_methods(cats)
    allow(Category).to receive(:all).and_return(cats)
  end

  private

  def category_findable(cat)
    id = FactoryGirl.generate(:unique_id)
    allow(cat).to receive(:id).and_return(id)
    allow(Category).to receive(:find).with(id).and_return(cat)
    allow(Category).to receive(:find).with(id.to_s).and_return(cat)
  end
end
