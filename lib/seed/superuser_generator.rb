module SuperuserGenerator
  def self.generate
    User.create! do |u|
      u.first_name = 'Donny'
      u.last_name = 'Darko'
      u.phone = '6666666666'
      u.email = 'email@email.com'
      u.affiliation = 'Your Mother'
      u.role = 'superuser'
      u.view_mode = 'superuser'
      u.username = 'dummy'
    end
  end
end
