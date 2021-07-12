require "tourmaline/extra/routed_menu"

GAME_NAME = "tavla"
BOT_ID    = ENV["BOT_ID"].to_i64

module Tourmaline
  class LuckyPersistence < NilPersistence
    def initialize
      # TODO: bugreport
      # no trap!
    end

    def update_user(user : User) : User
      unless _user = UserQuery.new.id(user.id).first?
        params = Avram::Params.new(
          id: user.id,
          is_bot: user.is_bot,
          first_name: user.first_name,
          last_name: user.last_name,
          username: user.username,
          language_code: user.language_code
        )
        SaveUser.create!(params)
      end
      user
    end

    def handle_update(update : Update)
      update.users.each &->update_user(User)
    end
  end
end

class TelegramBot < Tourmaline::Client
  class_getter(bot) do
    TelegramBot.new(
      bot_token: ENV["BOT_TOKEN"],
      persistence: Tourmaline::LuckyPersistence.new
    )
  end

  # This is need for correct restart dev server
  # arter Tourmaline calls server not release
  # binded port an seems just no restart at all
  # def initialize(**options)
  #  super(**options)
  #  Signal::TERM.trap { exit }
  # end

  @[OnCallbackQuery(GAME_NAME)]
  def process_query(ctx)
    game = ActiveGame.process_update(ctx.query)
    game_url = game.user_route(ctx.query.from.id).url
    if Lucky::Env.production?
      answer_callback_query(ctx.query.id, url: game_url)
    else
      puts game.id
      puts game_url
    end
    user = ctx.query.from
    fp = "./public/#{user.id}.jpg"
    return if File.exists?(fp)
    profile_photos = get_user_profile_photos(user)
    return user unless profile_photos.total_count > 0
    file_id = profile_photos.photos[0][0].file_id
    download_file(file_id, fp)
  end

  @[OnInlineQuery(%r{.*})]
  def process_inline_query(ctx)
    answer_inline_query(
      ctx.query.id,
      InlineQueryResult.build(&.game(ans_id(ctx), GAME_NAME)))
  end

  START_TEXT = <<-TEXT
  Welcome! I can be used to play the Tavla game!).

  Just send me /help command for detais!
  TEXT

  # @[Command("start")]
  # def start_command(ctx)
  #   ctx.message.respond(START_TEXT, parse_mode: :markdown)
  # end

  # we will use only inline mode
  # @[Command("game")]
  # def start_command(ctx)
  #   send_game(ctx.message.chat.id, GAME_NAME)
  # end

  # TODO: translate
  MY_MENU = Tourmaline::RoutedMenu.build do
    route "/" do
      content START_TEXT
      buttons(columns: 2) do
        switch_to_chat_button("Play the game (other chat)", "play")
        switch_to_current_chat_button("Play in this chat", "play_that_chat")
        url_button "Support group", "https://t.me/tavla_game_telegram"
        route_button "Faq", to: "/faq"
        url_button "Rules", "https://bkgm.com/variants/Tavla.html"
      end
    end

    route "/faq" do
      content "Coming soon..."
      buttons do
        back_button "Back"
      end
    end
  end

  @[Command("help")]
  def start_command(ctx)
    ctx.message.respond_with_menu(MY_MENU)
  end

  private def ans_id(ctx, idx = 0)
    Digest::SHA1.hexdigest(
      "IQR_#{ctx.query.id}_#{Time.local.nanosecond}_#{idx}"
    )
  end
end
