require 'spec_helper'
require Rails.root.join('spec/support/equipment_model_helper')

module EquipmentItemMocker
  include EquipmentModelMocker
  def mock_eq_item(traits: [], **attrs)
    traits.map! { |trait, *args| ["eq_item_#{trait}".to_sym, *args] }
    instance_spy('EquipmentItem', **attrs).tap do |item|
      traits.each { |trait, *args| send(trait, item, *args) }
    end
  end

  def mock_eq_items(count: 1, traits: [], **attrs)
    Array.new(count) { mock_eq_item(traits: traits, **attrs) }
  end

  def stub_eq_item_collection_methods(items)
    allow(EquipmentItem).to receive(:all).and_return(items)
  end

  private

  def eq_item_findable(item)
    id = FactoryGirl.generate(:unique_id)
    allow(item).to receive(:id).and_return(id)
    allow(EquipmentItem).to receive(:find).with(id).and_return(item)
    allow(EquipmentItem).to receive(:find).with(id.to_s).and_return(item)
  end

  def eq_item_with_model(item, model: nil)
    model ||= mock_eq_model(traits: [:findable])
    allow(item).to receive(:equipment_model).and_return(model)
    items = if model.equipment_items.is_a? Array
              model.equipment_items << item
            else
              [item]
            end
    allow(model).to receive(:equipment_items).and_return(items)
  end
end
