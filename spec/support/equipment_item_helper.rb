require 'spec_helper'

module EquipmentItemMocker
  def mock_eq_item(traits: [], **attrs)
    instance_spy('EquipmentItem', **attrs).tap do |item|
      traits.each { |trait, *args| send(trait, model, *args) }
    end
  end

  def stub_eq_item_collection_methods(items)
    allow(EquipmentItem).to receive(:all).and_return(items)
  end

  private

  def findable(item)
    id = FactoryGirl.generate(:unique_id)
    allow(item).to receive(:id).and_return(id)
    allow(EquipmentItem).to receive(:find).with(id).and_return(item)
    allow(EquipmentItem).to receive(:find).with(id.to_s).and_return(item)
  end

  def with_model(item, model: nil)
    model ||= EquipmentModelMocker.one
    allow(item).to receive(:equipment_model).and_return(model)
    items = if model.equipment_items.is_a? Array
               model.equipment_items << item
            else
              [item]
            end
    allow(model).to receive(:equipment_items).and_return(items)
  end
end
