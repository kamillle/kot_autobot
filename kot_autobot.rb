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

  def run(target_year, target_month)
    driver.navigate.to(KOT_LOGIN_URL)

    login_id_element = driver.find_element(id: 'login_id')
    login_id_element.send_keys(ENV['KOT_LOGIN_ID'])
    login_password_element = driver.find_element(id: 'login_password')
    login_password_element.send_keys(ENV['KOT_LOGIN_PASSWORD'])
    driver.action.click(driver.find_element(id: 'login_button')).perform

    # 指定された年と月の勤怠入力画面を開く
    # id='year', 'month' はhiddenなので、jsを実行して値を入れている
    driver.execute_script("return $('#year').val(#{target_year});")
    driver.execute_script("return $('#month').val(#{target_month});")
    driver.action.click(driver.find_element(id: 'display_button')).perform

    regist_attendances(target_year, target_month)

    driver.quit
  end

  private

  def driver_options
    options = Selenium::WebDriver::Chrome::Options.new

    options
  end

  def regist_attendances(target_year, target_month)
    attendance_registration_finished_days = []

    # 勤怠登録を終了した毎に `driver.find_elements(class: 'htBlock-selectOther')` をやり直さないと
    # Seleniumのエラーが出てしまうので、一回登録が済んだことに処理を頭からやり直すようにしている
    # 詳しくはわからないけど、勤怠登録をするごとにHTMLのなんかの要素が変わっていて、
    # 毎回新しくHTML要素を取得し直さないとSeleniumが動かないんだと思う
    loop do
      lists = driver.find_elements(class: 'htBlock-selectOther')

      lists.each.with_index(1) do |list, day|
        # すでに処理済みの日付であれば処理をスキップ
        next if attendance_registration_finished_days.include?(day)

        # 打刻しない日であれば、処理処理が終了した日とみなす
        next attendance_registration_finished_days << day unless work_day?(year: target_year, month: target_month, day: day)

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

        # 打刻登録できたらこの日付の勤怠登録処理が終了した日とみなす
        attendance_registration_finished_days << day

        # ここまで来たら繰り返しを終了する
        break
      end

      # 打刻可能な日数(lists.length)と、勤怠登録処理が終了した日数(attendance_registration_finished_days.length)が
      # 同じ数値になったらこの月の全ての勤怠登録処理が終了したとみなしてloopを終了する
      return if lists.length == attendance_registration_finished_days.length
    end
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
