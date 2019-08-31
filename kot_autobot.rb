require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'

  gem 'selenium-webdriver'
  gem 'pry-byebug'
end

class Driver
  require "selenium-webdriver"

  KOT_LOGIN_URL = "https://s3.kingtime.jp/admin/gzuSQM3Pi3cSdfm7yCAwqmPjBPZrpS3U?page_id=/login/do_logout".freeze

  class << self
    def access_kot
      print 'enter kot id: '
      id = STDIN.gets.chomp.strip
      print 'enter kot password: '
      password = STDIN.gets.chomp.strip

      self.new.access_kot(id, password)
    end
  end

  attr_reader :driver

  def initialize
    @driver ||= Selenium::WebDriver.for :chrome, options: driver_options
  end

  # sample code
  def access_kot(id, password)
    driver.navigate.to(KOT_LOGIN_URL)

    login_id_element = driver.find_element(id: 'login_id')
    login_id_element.send_keys(id)
    login_password_element = driver.find_element(id: 'login_password')
    login_password_element.send_keys(password)
    driver.action.click(driver.find_element(id: 'login_button')).perform

    # 今8月でもう入力終わったので、翌月に飛ぶ
    driver.action.click(driver.find_element(id: 'button_next_month')).perform

    lists = driver.find_elements(class: 'htBlock-selectOther')

    lists.each do |list|
      # 各日付の打刻編集画面に飛ぶ
      Selenium::WebDriver::Support::Select.new(list).select_by(:text, '打刻編集')
    end

    driver.quit
  end

  private

  def driver_options
    options = Selenium::WebDriver::Chrome::Options.new

    options
  end
end

Driver.access_kot
