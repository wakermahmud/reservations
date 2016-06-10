class ReservationJob < ActiveJob::Base
  queue_as :default
  UNDEFINED_MESSAGE = 'JOB NOT DEFINED'.freeze

  def perform
    if enabled
      log_start
      run
      clean
      log_completion
    else
      log_disabled
    end
  end

  private

  def enabled
    true
  end

  def log_start(type: '', task: UNDEFINED_MESSAGE)
    prep_collection
    Rails.logger.info "Found #{collection.count} #{type} reservations, #{task}"
  end

  def log_disabled(task: UNDEFINED_MESSAGE)
    Rails.logger.info "Reservations is not configured to #{task}. "\
      'Please change the application settings if you wish to do so.'
  end

  def log_completion
    Rails.logger.info 'Done!'
  end

  def run
  end

  def prep_collection
  end

  def collection(scope = :all)
    @set ||= Reservation.send(scope)
  end

  def clean
    @set = nil
  end
end
