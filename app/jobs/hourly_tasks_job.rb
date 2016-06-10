class HourlyTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    EmailNotesToAdminsJob.perform_later
  end
end
