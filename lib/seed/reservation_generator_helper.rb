module ReservationGeneratorHelper
  include ActiveSupport::Testing::TimeHelpers

  def gen_res(random = false)
    r = Reservation.new(status: 'reserved', reserver_id: User.all.sample.id,
                        equipment_model: EquipmentModel.all.sample,
                        notes: FFaker::HipsterIpsum.paragraph(2),
                        start_date: Time.zone.today)
    len = r.equipment_model.maximum_checkout_length
    len -= random ? rand(len - 1) : 1
    r.due_date = r.start_date + len.days
    r
  end

  def make_checked_out(res, _ = false)
    res.status = 'checked_out'
    res.checked_out = res.start_date
    res.equipment_item = res.equipment_model.equipment_items.all.sample
    res.checkout_handler_id = User.where('role = ? OR role = ? OR role = ?',
                                         'checkout', 'admin',
                                         'superuser').all.sample.id
  end

  def make_returned(res, random = false)
    make_past(res, random)
    make_checked_out res
    r_date = if res.due_date > Time.zone.today
               random ? rand(res.start_date..Time.zone.today) : Time.zone.today
             else
               random ? rand(res.start_date..res.due_date) : res.due_date
             end
    check_in(res, r_date)
  end

  def make_overdue(res, random = false)
    make_past(res, random, true)
    make_checked_out res
    res.overdue = true
  end

  def make_returned_overdue(res, random = false)
    make_overdue(res, random)
    return_date = random ? rand(res.due_date..Time.zone.today) : Time.zone.today
    check_in(res, return_date)
  end

  def make_missed(res, random = false)
    make_past(res, random)
    res.status = 'missed'
  end

  def make_archived(res, random = false)
    make_past(res, random) if random && rand < 0.5
    res.status = 'archived'
  end

  def make_requested(res, random = false)
    make_future(res, random) if random && rand < 0.5
    res.status = 'requested'
    res.flag(:request)
  end

  def make_denied(res, random = false)
    make_requested(res, random)
    res.status = 'denied'
  end

  def check_in(res, date)
    res.status = 'returned'
    res.checked_in = date
    res.checkin_handler_id = User.where('role = ? OR role = ? OR role = ?',
                                        'checkout', 'admin',
                                        'superuser').all.sample.id
  end

  def make_past(res, random = false, overdue = false)
    start = overdue ? res.duration.days : 1.day
    past = random ? -rand(start..1.year) : -(start + 1.week)
    offset(res, past)
    # save on the start date so validations run properly
    travel_to(res.start_date) { res.save }
  end

  def make_future(res, random = false)
    # set the amount of time in the future
    future = random ? rand(1.day..3.months) : 2.weeks
    offset(res, future)
  end

  def offset(res, size)
    len = res.duration.days
    res.start_date = res.start_date.days_since(size)
    res.due_date = res.start_date + len
  end
end
