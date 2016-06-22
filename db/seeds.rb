# This script is used to populate the database with preload data.
# It does not clear the database - mainly because that would mean deleting your
# admin login. All the numbers are pretty arbitrary, and can be changed to suit
# your needs, and how many records you want.
#
# As it stands, you'll need to follow the format and create a new seed
# generation block for each model you want to seed in the database, every time
# you create a model that isn't already here.
#
# There are a variety of options passable to the script through the use of
# environment variables, eg
# ```bundle exec rake db:seed semi=true no_pics=true```
#
# semi
#   autogenerates the first user and appconfig but prompts for all other fields
# minimal (or auto)
#   autogenerates all fields with sane defaults
# no_pics
#   does not assign pictures to equipment models, saving around 1 second
#   per equipment model generated
# fast
#   combines minimal and no_pics

require 'ruby-progressbar'

# rubocop:disable Rails/Output

#-------RESET PUBLIC DIR IF WE'VE RESET THE DATABASE
if EquipmentModel.all.empty?
  location_models = Rails.root.to_s + '/public/attachments/equipment_models'
  if File.directory?(location_models) # if the directory exists
    FileUtils.rm_r location_models # delete it and everything inside
  end
end

#-------GLOBAL VARIABLES

MINIMAL = ENV['minimal'].present? || ENV['fast'].present?
SEMI = ENV['semi'].present?
NO_PICS = ENV['no_pics'].present? || ENV['fast'].present?

DEFAULT_MSGS = File.join(Rails.root, 'db', 'default_messages')
TOS_TEXT = File.read(File.join(DEFAULT_MSGS, 'tos_text'))
UPCOMING_CHECKIN_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                                 'upcoming_checkin_email'))
UPCOMING_CHECKOUT_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                                  'upcoming_checkout_email'))
OVERDUE_RES_EMAIL_BODY = File.read(File.join(DEFAULT_MSGS, 'overdue_email'))
DELETED_MISSED_RES_EMAIL = File.read(File.join(DEFAULT_MSGS,
                                               'deleted_missed_email'))

IMAGES = Dir.glob(File.join(Rails.root, 'db', 'seed_images', '*'))

# Progress bar format string
PROGRESS_STR = '%t: [%B] %P%% | %c / %C | %E'.freeze

#-------METHODS

# Method for prompting the user for the number of records per model
# they want to seed into the database.
def ask_for_records(model)
  formatted_model = model.camelize

  puts "\nHow many #{formatted_model} records would you like to generate?" \
    '(please enter a number)'
  n = STDIN.gets.chomp
  # set n to 0 if blank, otherwise try to convert to an int.
  # if that fails re-prompt
  n = 0 if n == ''
  n = Integer(n) rescue nil # rubocop:disable RescueModifier
  if n.nil? || n < 0
    puts "Please enter a whole number\n"
    return ask_for_records(model)
  end
  n
end

def prompt_field(obj, field)
  puts field.to_s.split('_').collect(&:capitalize).join(' ') + ':'
  obj[field] = STDIN.gets.chomp
  begin
    obj.save!
  rescue ActiveRecord::RecordInvalid => e
    puts e.to_s
    prompt_field(obj, field)
  end
end

def prompt_password(user)
  puts 'Temp Password:'
  user.password = STDIN.noecho(&:gets).chomp
  user.password_confirmation = user.password
  begin
    user.save!
  rescue ActiveRecord::RecordInvalid => e
    puts e.to_s
    prompt_password(user)
  end
end

def generate_objs(obj, n)
  return if n == 0
  puts "Generating #{n} #{obj.camelize}...\n"
  progress = ProgressBar.create(format: PROGRESS_STR, total: n)
  n.times do
    Generator.send(obj)
    progress.increment
  end
end

# START SCRIPT
# ============
#

puts 'Minimal mode activated. Please wait...' if MINIMAL

t1 = Time.zone.now
display_login_msg = false
# check to see if a superuser exists
if User.where('role = ?', 'superuser').empty?
  display_login_msg = true
  User.destroy_all
  u = User.new
  u.first_name = 'Donny'
  u.last_name = 'Darko'
  u.phone = '6666666666'
  u.email = 'email@email.com'
  u.affiliation = 'Your Mother'
  u.role = 'superuser'
  u.view_mode = 'superuser'
  u.username = 'dummy'
  u.save

  if MINIMAL || SEMI
    if ENV['CAS_AUTH']
      prompt_field(u, :cas_login)
      u.username = u.cas_login
    else
      u.username = u.email
      u.password = 'passw0rd'
      u.password_confirmation = u.password
    end
    u.save
  else
    puts 'We need to create an account for you first.' \
      'Please enter the following info:'
    prompt_field(u, :first_name)
    prompt_field(u, :last_name)
    prompt_field(u, :phone)
    prompt_field(u, :email)
    prompt_field(u, :affiliation)
    if ENV['CAS_AUTH']
      prompt_field(u, :cas_login)
      u.username = u.cas_login
      u.save
    else
      u.username = u.email
      u.save
      prompt_password(u)
    end
  end

end

# AppConfig generation
# ============================================================================

if AppConfig.count == 0
  ac = AppConfig.new
  ac.terms_of_service = TOS_TEXT
  ac.reservation_confirmation_email_active = false
  ac.overdue_checkin_email_active = false
  ac.site_title = 'Reservations'
  ac.upcoming_checkin_email_active = false
  ac.notify_admin_on_create = false
  ac.admin_email = 'admin@admin.com'
  ac.department_name = 'Department'
  ac.contact_link_location = 'contact@admin.com'
  ac.home_link_text = 'home_link'
  ac.home_link_location = 'Canada'
  ac.deleted_missed_reservation_email_body = DELETED_MISSED_RES_EMAIL
  ac.default_per_cat_page = 10
  ac.request_text = ''
  ac.upcoming_checkin_email_body = UPCOMING_CHECKIN_RES_EMAIL
  ac.upcoming_checkout_email_body = UPCOMING_CHECKOUT_RES_EMAIL
  ac.overdue_checkin_email_body = OVERDUE_RES_EMAIL_BODY
  ac.save

  unless MINIMAL || SEMI
    puts 'We need to setup application settings:'
    prompt_field(ac, :admin_email)
    prompt_field(ac, :department_name)
    printf 'The contact form email - '
    prompt_field(ac, :contact_link_location)
    prompt_field(ac, :home_link_text)
    prompt_field(ac, :home_link_location)
    prompt_field(ac, :site_title)
  end
end

# User generation

n = MINIMAL ? 25 : ask_for_records('User')
generate_objs('user', n)

# Category generation
# ============================================================================

n = MINIMAL ? 10 : ask_for_records('Category')

generate_objs('category', n)

# EquipmentModel generation
# ============================================================================

unless Category.count == 0
  n = MINIMAL ? 25 : ask_for_records('EquipmentModel')
  puts "\nThis is going to take awhile...\n" unless NO_PICS
  generate_objs('equipment_model', n)
end

# Eqobj, Procedures, and Requirement generation
# ============================================================================

unless EquipmentModel.count == 0
  n = MINIMAL ? 50 : ask_for_records('EquipmentItem')
  generate_objs('equipment_item', n)

  n = MINIMAL ? 0 : ask_for_records('Requirement')
  generate_objs('requirement', n)

  n = MINIMAL ? 3 : ask_for_records('CheckinProcedure')
  generate_objs('checkin_procedure', n)

  n = MINIMAL ? 3 : ask_for_records('CheckoutProcedure')
  generate_objs('checkout_procedure', n)
end

# Blackout Date generation
# ============================================================================

n = MINIMAL ? 0 : ask_for_records('Blackout')
generate_objs('blackout', n)

# Reservation generation
# ============================================================================

unless EquipmentItem.count == 0
  if MINIMAL
    puts "\nGenerating reservations at each point in the lifecycle..."
    Generator.all_reservation_types
  end
  n = MINIMAL ? 5 : ask_for_records('Reservation')
  generate_objs('reservation', n)
end

puts "\n***Successfully seeded all records! (#{Time.zone.now - t1}s)***\n\n"
if !ENV['CAS_AUTH'] && MINIMAL && display_login_msg
  puts "You can log in using e-mail 'email@email.com' and password 'passw0rd'\n"
end
