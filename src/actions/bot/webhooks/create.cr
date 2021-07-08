class Bot::Webhooks::Create < ApiAction
  BOT_SECURE_ID = "777"

  before require_right_bot_id

  post "/bot/:bot_id/webhooks" do
    update = Tourmaline::Update.from_json(body)
    puts update.to_pretty_json
    take_bot.handle_update(update)
    plain_text update.to_json
  rescue ex
    json({error: ex.to_s}, status: 500)
  end

  private def take_bot
    TelegramBot.bot
  end

  private def require_right_bot_id
    if bot_id != bot_secure_id
      head 404
    else
      continue
    end
  end

  private def bot_secure_id
    if Lucky::Env.production?
      ENV["BOT_TOKEN"].split(":").last
    else
      BOT_SECURE_ID
    end
  end

  private def body : String
    Lucky::RequestBodyReader.new(request).body
  end
end
