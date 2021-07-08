class ActiveGames::GameUpdate < BrowserAction
  include Access::RequireActiveGame

  match :put, "/active_games/:game_key" do
    on_put
  end

  def on_put
    active_game.not_nil!
    game = active_game.to_game_model
    player = detect_player
    puts "render on_put #{player}"

    client_action = params.get("player_action")
    server_action = game.player_action(player).to_s
    if client_action != server_action
      puts "Inconsistent serv:#{server_action} cl:#{client_action}"
    end
    case server_action
    when "roll_arb_dice"
      if game.my_turn?(player)
        game.arbitrate(player, game.next_roll)
      end
    when "wait_opp_arb_dice"
      if game.my_turn?(player) || active_game.with_bot?
        game.arbitrate(game.other_dir(player), game.next_roll)
      end
    when "roll_dices"
      if game.my_turn?(player)
        game.clean_last_turn
        game.dice_roll
      end
    when "wait_opp_dices"
      if game.my_turn?(player) || active_game.with_bot?
        game.clean_last_turn
        game.dice_roll
      end
    when "turn_made"
      if game.my_turn?(player)
        idx = params.get("index").split("_")[1].to_i32
        sc = params.get("score").to_i32
        game.make_turn(idx, sc)
      end
    when "no_movies_left"
      game.clean_last_turn
      game.transfer_turn
    when "wait_opp_turn"
      if game.my_turn?(player) || active_game.with_bot?
        ap = game.all_possible
        if ap.size > 0
          game.optimal_turn[0..0].each do |turn|
            from, sc = turn
            puts "make_turn(from: #{from}, score:#{sc})"
            game.make_turn(from, sc)
          end
        else
          puts "no turns, transfer dir"
          game.transfer_turn
        end
      end
    when "loser"
      # Здесь ловим что бот победил
      # и начисляем ему очки
      if active_game.with_bot?
        user_id = BOT_ID
        game_scores = game.final_score
        imi = active_game.inline_message_id
        total_scores = SaveScore.new.update_user_scores(
          user_id,
          imi,
          game_scores
        )
        spawn TelegramBot.bot.set_game_score(
          user_id,
          total_scores,
          true,
          inline_message_id: imi)
      end
      game = ::Game.new
      game.setup_game
      game.arbitrate(player, 1)
      game.arbitrate(game.other_dir(player), 6)
    when "winner"
      if user_id = active_game.user_from_player(player)
      else
        user_id = BOT_ID
      end
      game_scores = game.final_score
      imi = active_game.inline_message_id
      total_scores = SaveScore.new.update_user_scores(
        user_id,
        imi,
        game_scores
      )
      spawn TelegramBot.bot.set_game_score(
        user_id,
        total_scores,
        true,
        inline_message_id: imi)
      game = ::Game.new
      game.setup_game
      game.arbitrate(player, 6)
      game.arbitrate(game.other_dir(player), 1)
    else
    end
    SaveActiveGame.update!(
      active_game,
      started_at: active_game.started_at || Time.local,
      game: game.to_json
    )
    puts "next_action #{game.player_action(player)}"
    ws_notify_update(active_game, game, player)
    redirect to: active_game.get_route(player)
  end

  delegate whose_key, make_ws_key, to: ActiveGame

  private def ws_notify_update(model, game, player)
    other_side = game.other_dir(player)
    ws_key = make_ws_key(model, other_side)
    AppServer::WsHolder.send_by(ws_key) do |ws|
      ws.send(
        [
          game.player_action(other_side),
          game.turns_used.size,
        ].join("_")
      )
    end
  end

  private def detect_player(signed_key = game_key)
    ActiveGame.whose_key(signed_key)
  end
end
