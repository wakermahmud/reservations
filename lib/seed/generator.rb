module Generator
  require 'ffaker'

  def self.reservation
    ReservationGenerator.generate_random
  end

  def self.all_reservation_types
    ReservationGenerator.generate_all_types
  end

  def self.blackout
    BlackoutGenerator.generate
  end

  def self.user
    UserGenerator.generate
  end

  def self.category
    CategoryGenerator.generate
  end

  def self.equipment_model
    EquipmentModelGenerator.generate
  end

  def self.equipment_item
    EquipmentItemGenerator.generate
  end

  def self.requirement
    RequirementGenerator.generate
  end

  def self.checkin_procedure
    ProcedureGenerator.generate_checkin
  end

  def self.checkout_procedure
    ProcedureGenerator.generate_checkout
  end
end
