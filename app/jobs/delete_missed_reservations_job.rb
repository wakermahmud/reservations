class DeleteMissedReservationsJob < ReservationJob
  private

  def enabled
    !AppConfig.check(:res_exp_time, '').blank?
  end

  def log_start
    super(type: 'old missed', task: 'deleting')
  end

  def log_disabled
    super(task: 'delete old missed reservations')
  end

  def run
    old_missed_reservations.each do |missed_reservation|
      log_deletion missed_reservation
      missed_reservation.destroy
    end
  end

  def old_missed_reservations
    collection(:deletable_missed)
  end

  def prep_collection
    old_missed_reservations
  end

  def log_deletion(res)
    Rails.logger.info "Deleting reservation:\n #{res.inspect}"
  end
end
