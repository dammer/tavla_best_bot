# Tavla is a Turkish Backammon game for Telegram

This code partially described in my [topic on Habr](https://habr.com/ru/post/567064/) (russian lang)

This is a project written using [Lucky](https://luckyframework.org). Enjoy!

### Setting up the project

1. [Install required dependencies](https://luckyframework.org/guides/getting-started/installing#install-required-dependencies)
2. Update database settings in `config/database.cr`
3. Run `script/setup`
4. Run `lucky dev` to start the app

### Create .env file

After creating you own bot and adding game to him make .env file in root foler of project.
```yaml
DB_USERNAME="tavls"
GAME_KEY_SECRET="Ahcahth0"
BOT_ID=YOU_BOT_ID
BOT_TOKEN="YOU_BOT_TOKEN"
```
If you use different game name, not "tavla" change [constant GAME_NAME](https://github.com/dammer/tavla_best_bot/blob/2333cc80e2b60db73e4ce2c4005bd84b8dec0db8/src/bot.cr#L3) or move it to .env same as BOT_ID

### Setup Heroku deploy

Use [this Lucky Guide](https://luckyframework.org/guides/deploying/heroku) for setup deploy on Heroku.

### Register Webhook

After deploy app on Heroku set Webhook for getting updates from Telegram api server using [setwebhook](https://core.telegram.org/bots/api#setwebhook) api method or use Tourmaline [method](https://github.com/protoncr/tourmaline/blob/master/src/tourmaline/client/webhook_methods.cr) for that action.

### Learning Lucky

Lucky uses the [Crystal](https://crystal-lang.org) programming language. You can learn about Lucky from the [Lucky Guides](https://luckyframework.org/guides/getting-started/why-lucky).
