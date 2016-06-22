module UserGenerator
  def self.generate
    User.create do |u|
      u.first_name = FFaker::Name.first_name
      u.last_name = FFaker::Name.last_name
      u.nickname = FFaker::Name.first_name
      u.phone = FFaker::PhoneNumber.short_phone_number
      u.email = FFaker::Internet.email
      u.cas_login = FFaker::Internet.user_name if ENV['CAS_AUTH']
      u.affiliation = 'YC ' + %w(BK BR CC DC ES JE MC PC SM SY TC TD).sample +
        ' ' + rand(2012..2015).to_s
      u.role = %w(normal checkout).sample
      u.username = ENV['CAS_AUTH'] ? u.cas_login : u.email
    end
  end
end
