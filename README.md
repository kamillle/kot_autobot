# kot_autobot
KOT自動入力くん

# usage

.envというファイルを作り `KOT_LOGIN_ID` , `KOT_LOGIN_PASSWORD` という環境変数にそれぞれKOTのログインIDとパスワードを入れておいてください

```
KOT_LOGIN_ID=xxx
KOT_LOGIN_PASSWORD=yyy
```

その上で下記コマンドを実行するとKOTへ自動で勤怠を登録します

```
bundle exec ruby kot_autobot.rb
```
