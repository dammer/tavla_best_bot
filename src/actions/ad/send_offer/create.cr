class Ad::SendOffer::Create < ApiAction
  before fetch_game
  before detect_user

  getter active_game : ActiveGame?
  getter user : User?

  post "/ad/:user_id/send_offer/:active_game_id" do
    message = ""
    with_locale(user.try(&.language_code)) do
      message = I18n.t("adv_offer") % {first_name: user.try(&.first_name)}
    end
    # TelegramBot.bot.edit_message_text(
    #  inline_message: active_game.not_nil!.inline_message_id,
    #  text: message
    # )
    send_text_response(
      "document.querySelector('#ad_offer_send').replaceWith('#{message}');",
      "text/javascript",
      201)
  end

  private def fetch_game
    @active_game = ActiveGameQuery.new.id(active_game_id).first?
    continue_if(@active_game)
  end

  private def detect_user
    uid = user_id.to_i64
    if active_game.try(&.player_a) == uid || active_game.try(&.player_b) == uid
      @user = UserQuery.new.id(uid).first?
    end
    continue_if(@user)
  end
end
