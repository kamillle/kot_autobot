# kot_autobot
KOT自動入力くん

指定した年月の勤怠を、指定した日数分入力できます

祝日には対応してないので、入力処理が終わったら祝日分は自分で消してください

# usage

.envというファイルを作り `KOT_LOGIN_ID` , `KOT_LOGIN_PASSWORD` という環境変数にそれぞれKOTのログインIDとパスワードを入れておいてください

```
KOT_LOGIN_ID=xxx
KOT_LOGIN_PASSWORD=yyy
```

その上で下記コマンドを実行するとKOTへ自動で勤怠を登録します

```
bundle install

bundle exec ruby kot_autobot.rb
```
