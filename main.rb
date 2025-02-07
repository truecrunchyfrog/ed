#!/usr/bin/env ruby

require 'json'
require 'mechanize'
require 'io/console'
require 'date'
require 'csv'

data = ENV['DATA'] || raise('Missing environment variable DATA: JSON list of employer data.')

$generation_expression = ENV['GENERATION_EXPRESSION'] || raise('Missing environment variable GENERATION_EXPRESSION: Ruby expression.')
$mail_send = ENV['MAIL_SEND'] || raise('Missing environment variable MAIL_SEND: Ruby expression.')
$entries_filename = ENV['ENTRIES'] || raise('Missing environment variable ENTRIES: CSV file name to write/read successful applications to/from.')
File.open($entries_filename, 'a') {}

def process_employer(name, email, company, website)
  puts 'Processing employer'
  puts '  Data'
  puts "    Name:\t#{name}"
  puts "    Email:\t#{email}"
  puts "    Company:\t#{company}"
  puts "    Website:\t#{website}"

  if CSV.read($entries_filename).any? { |row| row[2] == email }
    puts '    Mail already exists as entry in entry file. Skipping.'
    return
  end

  puts '  Research phase'
  puts "    Scraping website (#{website})"

  agent = Mechanize.new
  link = agent.get(website).links.find { |l| l.text =~ /Om oss|About us/i }
  if link
    puts '      Navigating to "About Us" page'
    link&.click
  else
    puts '      Cannot find "About Us" page, using home page instead'
  end

  company_info = agent.page.search('p').map { |p| p.inner_text.strip }.join("\n")

  puts '  Generation phase'

  data = {
    :name => name,
    :email => email,
    :company => company,
    :company_info => company_info,
  }

  def evaluate_message(data)
    puts '    Generating message...'

    data.merge!(eval($generation_expression))

    puts '    Generated!'
    puts "    Subject:\t#{data[:subject]}"
    puts "    Content:\t#{data[:content]}"

    puts "\n\n"

    def prompt(data)
      puts '[a]ccept [i]gnore [r]egenerate'
      print '> '

      action = STDIN.getch
      puts ''

      case action
      when 'a'
        puts '    Accepted!'

        puts '  Sending phase'
        puts "    Recipient: #{data[:email]}"
        puts '    Sending'

        begin
          status = eval($mail_send)
        rescue => error
          puts '    Failed to send email:'
          p error.message
        else
          puts '    Sent email!'
          puts '    Writing entry'

          CSV.open($entries_filename, 'a+') do |csv|
            csv << [
              data[:company],
              data[:name],
              data[:email],
              Date.today.to_s
            ]
          end
        end
      when 'i'
        puts '    Ignored!'
      when 'r'
        evaluate_message data
      else
        puts '    Unknown action. Retry.'
        prompt data
      end
    end

    prompt data
  end

  evaluate_message data

  puts '  Done!'
end

JSON.parse(data).each do |o|
  process_employer(*o.values_at('name', 'email', 'company', 'website'))
end
