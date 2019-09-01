# frozen_string_literal: true

require "selenium-webdriver"
require 'dotenv/load'
require 'pry-byebug'

class KotAutobot
  KOT_LOGIN_URL = "https://s3.kingtime.jp/admin/gzuSQM3Pi3cSdfm7yCAwqmPjBPZrpS3U?page_id=/login/do_logout".freeze

  class << self
    def run
      print 'どの月の勤怠を入力するの？(例: 2019/09) '
      target_year_and_month = STDIN.gets.chomp.strip

      # 入力値が7桁でなかったらraiseする
      raise ArgumentError, '入力値がおかしいよ!!' if target_year_and_month.length != 7

      target_year = target_year_and_month.split(/\/|\-/)[0]
      target_month = target_year_and_month.split(/\/|\-/)[1]

      self.new.run(target_year, target_month)
    end
  end

  attr_reader :driver

  def initialize
    @driver ||= Selenium::WebDriver.for :chrome, options: driver_options
  end

  def run(target_year, target_month)
    driver.navigate.to(KOT_LOGIN_URL)

    login_kot

    open_target_attendance_registration_page(target_year, target_month)

    register_attendances(target_year, target_month)

    driver.quit
  end

  private

  def driver_options
    options = Selenium::WebDriver::Chrome::Options.new

    options
  end

  # .envに登録されたidとpasswordを使ってkotにログインする
  def login_kot
    driver.find_element(id: 'login_id').send_keys(ENV['KOT_LOGIN_ID'])
    driver.find_element(id: 'login_password').send_keys(ENV['KOT_LOGIN_PASSWORD'])

    driver.action.click(driver.find_element(id: 'login_button')).perform
  end

  # 指定された年と月の勤怠入力画面を開く
  def open_target_attendance_registration_page(target_year, target_month)
    # id='year', 'month' はhiddenなので、jsを実行して値を入れている
    driver.execute_script("return $('#year').val(#{target_year});")
    driver.execute_script("return $('#month').val(#{target_month});")

    driver.action.click(driver.find_element(id: 'display_button')).perform
  end

  def register_attendances(target_year, target_month)
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

        # 打刻しない日であれば、処理が終了した日とみなす
        next attendance_registration_finished_days << day unless weekdays?(year: target_year, month: target_month, day: day)

        # 各日付の打刻編集画面に飛ぶ
        Selenium::WebDriver::Support::Select.new(list).select_by(:text, '打刻編集')

        # 開いた日付に関して、すでに勤怠登録が1つでもされていれば勤怠登録処理が終了しているとみなしてloopの頭に戻る
        # recording_type_code というidが付与されたelementがある = 勤怠登録がされているとしている
        if driver.find_elements(id: 'recording_type_code').count.positive?
          attendance_registration_finished_days << day
          driver.navigate.back

          break
        end

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

  # 渡された年月日が平日かどうかを判断する
  def weekdays?(year:, month:, day:)
    # Date#cwday は月~金曜日(平日)を1 ~ 5として返す
    weekdays_number = (1..5)
    weekdays_number.include?(Date.new(year.to_i, month.to_i, day).cwday)
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
