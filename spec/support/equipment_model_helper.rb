require 'spec_helper'

module EquipmentModelHelper
  # traits are the private methods defined in this module
  # a findable model with a category is created with
  # traits: [:findable, [:with_category, cat: cat]]
  def mock_eq_model(traits: [], **attrs)
    instance_spy('EquipmentModel', **attrs).tap do |model|
      traits.each { |trait, *args| send(trait, model, *args) }
    end
  end

  def mock_eq_models(count: 1, traits: [], **attrs)
    Array.new(count) { mock_eq_model(traits: traits, **attrs) }
  end

  def stub_collection_methods(models)
    allow(EquipmentModel).to receive(:all).and_return(models)
  end

  def mock_category(**attrs)
    instance_spy('Category', **attrs).tap do |cat|
      allow(Category).to receive(:find).and_return(cat)
    end
  end

  private

  def findable(model)
    id = FactoryGirl.generate(:unique_id)
    allow(model).to receive(:id).and_return(id)
    allow(EquipmentModel).to receive(:find).with(id).and_return(model)
    allow(EquipmentModel).to receive(:find).with(id.to_s).and_return(model)
  end

  def with_category(model, cat: nil)
    cat ||= mock_category
    allow(model).to receive(:category).and_return(cat)
    models = if cat.equipment_models.is_a? Array
               cat.equipment_models << model
             else
               [model]
             end
    allow(cat).to receive(:equipment_models).and_return(models)
  end
end
