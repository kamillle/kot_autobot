require "selenium-webdriver"
require 'dotenv/load'
require 'pry-byebug'

class KotAutobot
  KOT_LOGIN_URL = "https://s3.kingtime.jp/admin/gzuSQM3Pi3cSdfm7yCAwqmPjBPZrpS3U?page_id=/login/do_logout".freeze

  class << self
    def run
      print 'どの月の勤怠を入力するの？(2019/09) '
      target_month_with_year = STDIN.gets.chomp.strip

      target_year = target_month_with_year.split(/\/|\-/)[0]
      target_month = target_month_with_year.split(/\/|\-/)[1]

      self.new.run(target_year, target_month)
    end
  end

  attr_reader :driver

  def initialize
    @driver ||= Selenium::WebDriver.for :chrome, options: driver_options
  end

  # sample code
  def run(target_year, target_month)
    driver.navigate.to(KOT_LOGIN_URL)

    login_id_element = driver.find_element(id: 'login_id')
    login_id_element.send_keys(ENV['KOT_LOGIN_ID'])
    login_password_element = driver.find_element(id: 'login_password')
    login_password_element.send_keys(ENV['KOT_LOGIN_PASSWORD'])
    driver.action.click(driver.find_element(id: 'login_button')).perform

    # 今8月でもう入力終わったので、翌月に飛ぶ
    driver.action.click(driver.find_element(id: 'button_next_month')).perform

    lists = driver.find_elements(class: 'htBlock-selectOther')

    lists.each.with_index(1) do |list, day|
      binding.pry if day == 7
      next unless work_day?(year: target_year, month: target_month, day: day)

      # 各日付の打刻編集画面に飛ぶ
      Selenium::WebDriver::Support::Select.new(list).select_by(:text, '打刻編集')

      # 出社時間の入力
      Selenium::WebDriver::Support::Select.new(driver.find_element(id: 'recording_type_code_1')).select_by(:text, '出勤')
      driver.find_element(id: 'recording_timestamp_time_1').send_keys(time_in)

      # 退社時間の入力
      Selenium::WebDriver::Support::Select.new(driver.find_element(id: 'recording_type_code_2')).select_by(:text, '退勤')
      driver.find_element(id: 'recording_timestamp_time_2').send_keys(time_out)

      # 打刻登録
      driver.action.click(driver.find_element(id: 'button_01')).perform
    end

    driver.quit
  end

  private

  def driver_options
    options = Selenium::WebDriver::Chrome::Options.new

    options
  end

  def work_day?(year:, month:, day:)
    workday_number = (1..5)
    workday_number.include?(Date.new(year.to_i, month.to_i, day).cwday)
  end

  # 10:00~11:00の間のランダムな時間を出す
  def time_in
    Random.rand(Time.new(2019, 1, 1, 10)..Time.new(2019, 1, 1, 11)).strftime("%H%M")
  end

  # 20:00~21:00の間のランダムな時間を出す
  def time_out
    Random.rand(Time.new(2019, 1, 1, 20)..Time.new(2019, 1, 1, 21)).strftime("%H%M")
  end
end

KotAutobot.run
