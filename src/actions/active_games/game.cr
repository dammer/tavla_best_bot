class ActiveGames::Game < BrowserAction
  include Access::RequireActiveGame

  match :get, "/active_games/:game_key" do
    on_get
  end

  def on_get
    active_game.not_nil!
    game = active_game.to_game_model
    player = detect_player
    ws_key = make_ws_key(active_game, player)
    active_user = active_game.active_user(player)
    waiting_user = active_game.waiting_user(player)

    # if active_user
    #   I18n.locale = active_user.language_code
    # end

    puts "render on_get #{player} #{game.player_action(player)}"

    if Lucky::Env.development?
      sleep(0.8)
    end
    with_locale(active_user.try(&.language_code)) do
      html ActiveGames::GamePage,
        game: game,
        model: active_game,
        player: player,
        ws_key: ws_key,
        active_user: active_user,
        waiting_user: waiting_user
    end
  end

  delegate whose_key, make_ws_key, to: ActiveGame

  private def detect_player(signed_key = game_key)
    whose_key(signed_key)
  end
end
