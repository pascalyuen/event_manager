require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode = zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phonenumber(phone_number)
  phone_number = phone_number.gsub(/\D/, '')
  phone_number = if phone_number.length < 10 || (phone_number.length == 11 && phone_number[0] != '1') || phone_number.length > 11
    'Bad Number'
  elsif phone_number.length == 11 && phone_number[0] == '1'
      phone_number.slice(1, 10)
  else
    phone_number
  end
end

def legislators_by_zipcodes(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'  

  begin
    legislators = civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

# def peak_registration_hours(time)

# end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output.thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized!'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

t_arr = []
contents.each do |row|
  id = row[0]
  name = row[:first_name]

  zipcode = clean_zipcode(row[:zipcode])

  phone_number = clean_phonenumber(row[:homephone])

  # peak_hour = peak_registration_hours(row[:regdate])
  peak_hour = t_arr.push(Time.strptime(row[:regdate], "%m/%d/%Y %R").hour)
  peak_hour = peak_hour.max_by(2) {|obj| t_arr.count(obj) }

  legislators = legislators_by_zipcodes(zipcode)

  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id,form_letter)


  puts "#{name} #{zipcode} #{phone_number}"
  puts "Peak registration hours: #{peak_hour}"
end
