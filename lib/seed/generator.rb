module Generator
  require 'ffaker'

  def reservation
    ReservationGenerator.generate_random
  end

  def all_reservation_types
    ReservationGenerator.generate_all_types
  end

  def blackout
    BlackoutGenerator.generate
  end

  def user
    UserGenerator.generate
  end

  def category
    CategoryGenerator.generate
  end

  def equipment_model
    EquipmentModelGenerator.generate
  end

  def equipment_item
    EquipmentItemGenerator.generate
  end

  def requirement
    RequirementGenerator.generate
  end

  def checkin_procedure
    ProcedureGenerator.generate_checkin
  end

  def checkout_procedure
    ProcedureGenerator.generate_checkout
  end
end
