module ProcedureGenerator
  def generate_checkin
    CheckinProcedure.create!(attributes)
  end

  def generate_checkout
    CheckoutProcedure.create!(attributes)
  end

  private

  def attributes
    { step: FFaker::HipsterIpsum.sentence,
      equipment_model_id: EquipmentModel.all.sample.id }
  end
end
