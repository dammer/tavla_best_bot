require "digest/sha1"

class ActiveGame < BaseModel
  # include JSON::Serializable

  table do
    column player_a : Int64
    column inline_message_id : String
    column chat_instance : String
    column player_b : Int64?
    column game : String
    column version : Int32
    column started_at : Time?
    column game_backup : String?
  end

  GAME_KEY_SECRET = ENV["GAME_KEY_SECRET"]
  KS = "--"

  def self.make_ws_key(model, player)
    extact_sign(
      lock(
        [model.id, model.user_from_player(player)]
          .join(KS)
      )
    )
  end

  def self.on_ws_message(message)
    game_id, player_s = message.split("::")
    model = ActiveGameQuery.new.find(game_id)
    player = Int32.new(player_s)
    game = model.to_game_model
    "#{game.player_action(player)}_#{game.turns_used.size}"
  end

  def self.detect(query)
    mg = ActiveGameQuery.new.message_games(query)
    return create_new_where_im_player_a(query) if mg.select_count == 0
    im_a = mg.im_player_a(query).first?
    return im_a if im_a
    im_b = mg.im_player_b(query).first?
    return im_b if im_b
    im_wait_for_b = mg.not_started.wo_player_b.first?
    if im_wait_for_b
      SaveActiveGame.update!(im_wait_for_b, player_b: query.from.id)
      # TODO: notify other side. Need ws switch on by default when game start
    else
      create_new_where_im_player_a(query)
    end
  end

  def self.create_new_where_im_player_a(query)
    SaveActiveGame.create!(
      player_a: query.from.id,
      inline_message_id: query.inline_message_id || "",
      chat_instance: query.chat_instance || "",
      game: new_game.to_json,
      version: get_game_version
    )
  end

  def self.process_update(callback_query : Tourmaline::CallbackQuery)
    detect(callback_query)
  end

  def with_bot?
    player_b.nil?
  end

  def active_user(player)
    get_user(user_from_player(player))
  end

  def waiting_user(active_player)
    active_user(Game.other_dir(active_player))
  end

  def get_user(id)
    UserQuery.new.id(id).first? if id
  end

  def user_route(user_id)
    if player_a == user_id
      player_a_route
    elsif player_b == user_id
      player_b_route
    else
      raise "Not user:#{user_id} game:#{id}!"
    end
  end

  def self.gen_sign(key)
    Digest::SHA1.hexdigest(
      [GAME_KEY_SECRET, key_parts(key).join].join
    )
  end

  def self.extact_sign(signed_key)
    key_parts(signed_key).shift
  end

  def self.lock(key)
    [gen_sign(key), key].join(KS)
  end

  # TODO: замиксить в кеш active_game_id
  # чтобы урл был уникальным для каждой игры
  # может быть проблема с проверкой сначала найти
  # потом проверить
  def lock(key)
    self.class.lock(key)
  end

  ##KRX = %r{\A((?<sign>[[:xdigit:]]{40})-)?(?<imi>[\w-]{27})?(-(?<uia>[\d]+))?(-(?<uib>[\d]+))?}

  def self.key_parts(key)
    return "#{key}".split(KS)
  # if m = KRX.match("#{key}")
  #   [m["sign"]?, m["imi"]?, m["uia"]?, m["uib"]?].compact
  # else
  #  [key]
  # end
  end

  def game_key_a
    "#{inline_message_id}#{KS}#{player_a}"
  end

  def game_key_b
    [game_key_a, player_b].join(KS)
  end

  def self.whose_key(signed_key)
    if key_parts(signed_key).size > 3
      -1
    else
      1
    end
  end

  def user_from_player(player)
    if player > 0
      player_a
    else
      player_b
    end
  end

  def player_route(player)
    if player > 0
      player_a_route
    else
      player_b_route
    end
  end

  def player_a_route(action = ActiveGames::Game)
    action.with(lock(game_key_a))
  end

  def player_b_route(action = ActiveGames::Game)
    action.with(lock(game_key_b))
  end

  def update_route(player)
    if player > 0
      player_a_route(ActiveGames::GameUpdate)
    else
      player_b_route(ActiveGames::GameUpdate)
    end
  end

  def get_route(player)
    if player > 0
      player_a_route(ActiveGames::Game)
    else
      player_b_route(ActiveGames::Game)
    end
  end

  def self.new_game
    new_game = Game.new
    new_game.setup_game
    new_game
  end

  def self.get_game_version
    Game::VER
  end

  def to_game_model : Game
    Game.from_json(game)
  end

  def game=(game_instance : Game)
    game = game_instance.to_json
  end
end
