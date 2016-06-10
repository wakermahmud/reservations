class FlagOverdueJob < ReservationJob
  private

  def log_start
    super(type: 'newly overdue', task: 'flagging')
  end

  def new_overdue
    collection(:newly_overdue)
  end

  def prep_collection
    new_overdue
  end

  def run
    new_overdue.each do |res|
      log_flag res
      update res
    end
  end

  def log_flag(res)
    Rails.logger.info "Flagging reservation #{res.id} as overdue"
  end

  def update(res)
    res.update_attributes(overdue: true)
  end
end
