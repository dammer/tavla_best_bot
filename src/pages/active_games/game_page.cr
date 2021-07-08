class ActiveGames::GamePage < MainLayout
  needs game : ::Game
  needs model : ActiveGame
  needs player : Int32
  needs cw : Bool = player < 0
  needs with_bot : Bool = model.with_bot?
  needs ap : Hash(Int32, Array(Int32)) = (game.my_turn?(player) ? game.all_possible : Hash(Int32, Array(Int32)).new)
  needs assess : Int32 = game.assess_position
  needs prev_turn : Tuple(Int32, Int32, Int32)? = game.last_turn
  needs dests : Array(Int32) = (game.my_turn?(player) ? game.dests : Array(Int32).new)
  needs player_action : String = game.player_action(player).to_s
  needs ws_endpoint : URI = URI.parse(Home::Index.route.url).tap(&.scheme = Lucky::Env.production? ? "wss" : "ws")
  needs ws_key : String
  # id, is_bot, first_name, last_name, username, language_code
  needs active_user : User?
  needs waiting_user : User?

  delegate t, to: I18n

  def content
    render_players
    svg do
      render_board
      render_cells
      render_dices
      case game.player_action(player)
      when :roll_arb_dice
        render_message("roll_arb_dice")
      when :wait_opp_arb_dice
        render_arbitration_dices
        render_message("wait_opp_arb_roll")
      when :roll_dices
        render_message("roll_dices")
      when :wait_opp_dices
        render_message("wait_opp_roll")
      when :turn_made
      when :no_movies_left
        render_message("turn_lost_no_movies")
      when :wait_opp_turn
        render_message("wait_opp_turn")
      when :winner
        sc = game.final_score
        render_message("you_win", score: sc)
      when :loser
        sc = game.final_score
        render_message("you_lose", score: sc)
      else
        render_message("unknown action")
      end
    end
    render_js_data
    render_action_link
    div id: "loader"
  end

  def svg
    tag "svg",
      id: "svg",
      class: "box_main",
      # width: "100%",
      # height: "100%",
      version: "1.1",
      viewBox: "0 -25 210 260",
      xmlns: "http://www.w3.org/2000/svg",
      "xmlns:xlink": "http://www.w3.org/1999/xlink" do
      render_defs
      yield
    end
  end

  def render_defs
    tag "defs" do
      tag "filter",
        height: "1.1717216",
        id: "gauss",
        # width: "1.0449015", x: "-0.022450774", y: "-0.085860815",
        style: "color-interpolation-filters:sRGB" do
        tag "feGaussianBlur",
          id: "feGaussianBlur1116",
          stddeviation: "9"
      end
    end
  end

  def render_players
    dop_class = cw? ? " cw" : ""
    div class: "box_a#{dop_class}" do
      player_info(active_user)
    end

    div class: "box_b#{dop_class}" do
      player_info(waiting_user)
    end
  end

  PATH_PREFIX = "./public"

  def have_pic?(path : String) : Bool
    File.exists?(PATH_PREFIX + path)
  end

  def user_dir(user : User?) : Int32
    return -1 unless user
    user.id == model.player_a ? 1 : -1
  end

  def player_info(user : User?, safe_pic = asset("images/nophoto.png"), safe_name = "Incognito")
    if with_bot? && user.nil?
      safe_pic = asset("images/bot.png")
      safe_name = "A.Bot"
      user_id = BOT_ID
    else
      user_id = user.try(&.id).not_nil!
    end
    path = "/#{user.try(&.id)}.jpg"
    pulse = game.dir == user_dir(user) ? " pulse" : ""
    div style: "--bg: url(#{have_pic?(path) ? path : safe_pic}", class: "avatar#{pulse}"
      div class: "user_info" do
        div class: "user_color"
        div class: "user_score" do
          text get_user_score(user_id).to_s
        end
      end
      span class: "user_name" do
        strong user.try(&.first_name) || safe_name
      end
  end

  def get_user_score(user_id : Int64) : Int32
    user_score = get_all_game_players_score(model.inline_message_id).find do |record|
      record.user_id == user_id
    end
    user_score ? user_score.score : 0
  end

  memoize def get_all_game_players_score(imi : String) : Array(Score)
    ScoreQuery.new.inline_message_id(imi).to_a
  end

  private def render_action_link
    link to: model.update_route(player),
      id: "update_form",
      data_remote: "true",
      data_method: "put",
      data_params: "player_action=#{player_action}" do
      text "#{player_action}"
    end
  end

  private def render_js_data
    script do
      raw "var state = '#{game.state}';\n"
      raw "var player_action = '#{player_action}';\n"
      raw "var game = #{game.to_json};\n"
      raw "var player = #{player};\n"
      raw "var submit_count = 0;\n"
      raw "var dests = #{dests};\n"
      raw "//ap = #{ap};\n"
      raw "var ws_game_id = '#{model.id}::#{player}';\n"
      raw "var player_last_action='#{player_action}_#{game.turns_used.size}';\n"
      raw "var ws=#{!game.my_turn?(player) && !with_bot?};\n"
      raw "var turn=#{game.my_turn?(player)};\n"
      raw "var period=#{7000};\n"
      raw "var ws_endpoint='#{ws_endpoint}#{ws_key}'\n"
      raw "var with_bot = #{with_bot?};\n"
      raw "var first_turn = #{game.my_turn?(player) && game.turns_used.size == 0};\n"
    end
  end

  def render_extra_qtty_label(cnt, subclass = "", point_x = 191, point_y = 16)
    tag "g", class: ["qtl", subclass].join(" ") do
      tag "text", class: "over-text", x: "#{point_x - 1}", y: "#{point_y + 1}", winner: "15.35", height: "15.35" do
        tag "tspan", "+", x: "#{point_x}", y: "#{point_y}"
        tag "tspan", "#{cnt}", x: "#{point_x + 6}", y: "#{point_y + 0.5}"
      end
    end
  end

  private def render_message(message = "", **substs)
    tag "g", id: "layer4" do
      tag "g", id: "message_form", style: "transform-origin: center;" do
        tag "rect", id: "message_rect", height: "20",
          width: "190", x: "10", y: "125" do
          tag "animate",
            attributeName: "fill-opacity",
            attributeType: "CSS",
            from: "0",
            to: "0.3",
            begin: "0s",
            dur: "0.5s",
            fill: "freeze",
            repeatCount: "0"
        end
        tag "text" do
          tag "tspan", id: "message_text", x: "72.9", y: "139.4" do
            text "#{t(message) % substs}"
            tag "animate",
              attributeName: "fill-opacity",
              attributeType: "CSS",
              from: "0.1",
              to: "0.6",
              begin: "0s",
              dur: "1s",
              fill: "freeze",
              repeatCount: "0"
          end
        end
      end
    end
  end

  # размер кости
  DWH = 18.0

  private def dice_rect
    tag "rect",
      class: "dice_rect",
      width: "#{DWH}",
      height: "#{DWH}",
      rx: "4.2",
      x: "#{DOX - DWH / 2}",
      y: "#{DOY - DWH / 2}"
  end

  private def dice_dot(cx = DOX, cy = DOY, dx = 0.0, dy = 0.0)
    tag "circle",
      cx: "#{cx + (dx * DICE_OFS)}",
      cy: "#{cy + (dy * DICE_OFS)}",
      r: "1.1",
      class: "dice_dot"
  end

  # dice origin
  DOX = 157.5
  DOY = 105.0

  # dice dots offset
  DICE_OFS = 4.76

  DICE_COORS = [
    {0.0, 0.0, [1, 3, 5]},
    {1.0, -1.0, [2, 3, 4, 5, 6]},
    {-1.0, 1.0, [2, 3, 4, 5, 6]},
    {-1.0, -1.0, [4, 5, 6]},
    {1.0, 1.0, [4, 5, 6]},
    {-1.0, 0.0, [6]},
    {1.0, 0.0, [6]},
  ]

  def dice_dots(val : Int32)
    DICE_COORS.each do |(x, y, numbers)|
      dice_dot(dx: x, dy: y) if numbers.includes?(val)
    end
  end

  def rand_angle
    game.rand.rand(0..90)
  end

  def rand_dist
    game.rand.rand(12..35)
  end

  def rand_vdist
    game.rand.rand(-5..5)
  end

  # TODO: сохранять положение костей между ходами
  def render_dice(value, n = 1, _class = "")
    direction = n.even? ? "" : "-"
    tag "g",
      id: "dice#{n}", data_value: "#{value}",
      class: ["dice", _class].join(" "),
      transform: "translate(#{direction}#{rand_dist}.0,#{rand_vdist}.0)" do
      tag "g", transform: "rotate(#{rand_angle},#{DOX},#{DOY})" do
        dice_rect
        dice_dots(value)
      end
    end
  end

  def render_dices
    tag "g", id: "layer3" do
      tag "g", transform: game.dir != player ? BOARD_CW_OP : "" do
        game.turns_used.each_with_index do |dice_score, idx|
          render_dice(dice_score, idx + 1, "used_dice")
        end
        offset = game.turns_used.size
        game.turns_left.each_with_index do |dice_score, idx|
          render_dice(dice_score, offset + idx + 1)
        end
      end
    end
  end

  # кости, бросок на розыгрыш хода
  def render_arbitration_dices
    tag "g", id: "layer3" do
      if game.arb_pos_score
        render_dice(game.arb_pos_score.not_nil!)
      end
      if game.arb_neg_score
        tag "g", transform: BOARD_CW_OP do
          render_dice(game.arb_neg_score.not_nil!)
        end
      end
    end
  end

  def group_quantity(idx)
    case idx
    when -1
      game.killed_pos
    when 24
      game.killed_neg
    when -2
      game.dropped_neg
    when 25
      game.dropped_pos
    else
      game.board[idx][1]
    end
  end

  def cell_group_class(idx)
    quantity = group_quantity(idx)
    case idx
    when -1
      "black_#{quantity} killed"
    when 24
      "white_#{quantity} killed"
    when -2
      "white_#{quantity} dropped"
    when 25
      "black_#{quantity} dropped"
    else
      if quantity > 0
        game.board[idx][0] > 0 ? "black_#{quantity}" : "white_#{quantity}"
      else
        ""
      end
    end
  end

  # центр X`
  BCX = 105
  # центр Y
  BCY = BCX
  # повернуть на 180 вокруг центра доски
  BOARD_CW_OP = "rotate(180,#{BCX},#{BCY})"

  private def render_cells(ops = CELLS_OPS, offset = -2)
    transform = cw? ? BOARD_CW_OP : ""
    options = calc_turn_animation_path(*prev_turn.not_nil!) if prev_turn
    tag "g", id: "cells", style: "display:inline", transform: transform do
      ops.each_with_index do |op, index|
        idx = index + offset
        tag "g",
          id: "cell_#{idx}",
          class: cell_group_class(idx),
          data_idx: idx,
          transform: op do
          render_cell(idx) do |index|
            if options && idx == options[:data_to_row_idx] && index == options[:data_to_col_idx]
              tag "animateMotion",
                dur: options[:time] || "1s",
                repeatCount: "0",
                path: options[:d]
            end
          end
        end
      end
    end
  end

  def dropped?(id)
    id == -2 || id == 25
  end

  def cell_class(id, index)
    res = ["cell"]
    res << "dest" if dest?(id)
    if dropped?(id)
      res << "drop"
    else
      res << "can_move" if can_move?(id, index)
    end
    res.compact.join(" ")
  end

  CELL_Y = ["12.5", "27.5", "42.5", "57.5", "72.5", "87.5"]

  private def render_cell(id, in_board = game.in_board?(id))
    source = in_board ? CELL_Y : CELL_Y.reverse
    source.each_with_index do |cy, index|
      tag "circle",
        r: "7.5",
        id: "cell_#{id}_#{index}",
        cx: in_board ? "197.5" : cy,
        cy: in_board ? cy : "197.5",
        class: cell_class(id, index) do
        yield index
      end
    end
    quantity = group_quantity(id)
    return unless quantity > 6
    if in_board
      render_extra_qtty_label(quantity - 6, rotate_helper(id > 11))
    else
      render_extra_qtty_label(quantity - 6, rotate_helper(false), 81, 201)
    end
  end

  def rotate_helper(cond)
    if cw?
      !cond ? "rotate180" : ""
    else
      cond ? "rotate180" : ""
    end
  end

  def dest?(idx)
    return unless game.my_turn?(player)
    return if idx == game.drop_taret
    dests.includes?(idx) || idx == game.drop_taret + game.dir
  end

  private def can_move?(idx, vpos)
    return unless game.my_turn?(player)
    return unless ap.values.flatten.includes?(idx)
    if idx < 0
      return game.killed_pos == vpos + 1
    elsif idx > 23
      return game.killed_neg == vpos + 1
    end
    return unless game.board[idx][0] == player
    game.board[idx][1] == vpos + 1 ||
      (game.board[idx][1] > 6 && vpos + 1 == 6)
  end

  def render_turn_animaion_path(turn)
    params = calc_turn_animation_path(*turn)
    tag "path", **params
    params
  end

  def calc_turn_animation_path(dir, at, distance) : NamedTuple(
    id: String,
    class: String,
    d: String,
    time: String,
    data_to_row_idx: Int32,
    data_to_col_idx: Int32)
    # ход сохраняетя через make_turn поэтому всегла -1 вместо killed_idx
    at = game.killed_idx(dir) if at == -1

    to = at + distance * dir
    # puts "dir at distance to, #{dir} #{at} #{distance} #{to}"

    # puts ">> at"
    at_type = game.in_board?(at) ? :board : :kill
    at_row_idx = row_index(dir, at_type, at)
    # -1 потому что фишка уже в этой позиции
    at_col_idx = [head_index(dir, at_type, at), 5].min
    at_point = get_point(at_row_idx, at_col_idx)
    # puts ">> to"
    to_type = game.in_board?(to) ? :board : :drop
    to_row_idx = row_index(dir, to_type, to)
    to_col_idx = [head_index(dir, to_type, to) - 1, 5].min
    to_point = get_point(to_row_idx, to_col_idx)
    # puts "======\n"
    # путь должен быть в относительных координатах
    d = to_path_values(
      [to_row_idx, to_col_idx],
      [at_row_idx, at_col_idx]
    )
    {
      id:              "path_#{to_row_idx}_#{to_col_idx}",
      class:           "turn_path",
      time:            adjust_time(at_row_idx, to_row_idx, at_row_idx, to_col_idx),
      data_to_row_idx: to_row_idx,
      data_to_col_idx: to_col_idx,
      d:               d,
    }
  end

  def adjust_time(at_row_idx, to_row_idx, at_col_idx, to_col_idx)
    res = 0.4
    x1, y1 = get_point(to_row_idx, to_col_idx)
    x2, y2 = get_point(at_row_idx, at_col_idx)
    dx = game.distance_abs(x1, x2)
    dy = game.distance_abs(y1, y2)
    res += ((dx + dy) / 2) / 120
    "#{[res, 0.5].max}s"
  end

  def row_index(dir, type, value)
    case type
    when :kill
      game.kill_taret(dir)
    when :drop
      # фактически это смещения в таюлице координат
      # 25 и -2 хранят сброшеные
      # -1 и 24 убитых
      game.drop_taret(dir) + dir
    else # board
      value
    end
  end

  def head_index(dir, type, value)
    case type
    when :kill
      game.killed_for(dir)
    when :drop
      game.dropped_for(dir)
    else
      # board
      game.board[value][1]
    end
  end

  def get_point(row, col = 0)
    CCOORDS[row][[col, 5].min]
  end

  def to_path_values(to, at)
    to_x, to_y = get_point(to[0], to[1])
    at_x, at_y = get_point(at[0], at[1])

    to_m_x, to_m_y = get_point(to[0], 5)
    at_m_x, at_m_y = get_point(at[0], 5)

    if to[0] == 25
      dx = at_x - to_x
      dy = at_y - to_y
      delta = to_m_x - at_m_x
    elsif to[0] > 11
      dx = to_x - at_x
      dy = to_y - at_y
      delta = to_y - at_m_y
    else
      dx = at_x - to_x
      dy = at_y - to_y
      delta = at_m_y - to_y
    end

    "M#{dx},#{dy} C#{dx},#{delta} #{0},#{delta} 0,0"
  end

  CELLS_OPS = [
    # neg dropped
    "translate(0,-209)", # -2
    # pos_killed
    "translate(109,-209)", # 1
    "",
    "translate(-16)",
    "translate(-32)",
    "translate(-48)",
    "translate(-64)",
    "translate(-80)",
    "translate(-105)",
    "translate(-121)",
    "translate(-137)",
    "translate(-153)",
    "translate(-169)",
    "translate(-185)",
    "rotate(180,105,105)",
    "rotate(180,113,105)",
    "rotate(180,121,105)",
    "rotate(180,129,105)",
    "rotate(180,137,105)",
    "rotate(180,145,105)",
    "rotate(180,157.5,105)",
    "rotate(180,165.5,105)",
    "rotate(180,173.5,105)",
    "rotate(180,181.5,105)",
    "rotate(180,189.5,105)",
    "rotate(180,197.5,105)",
    # neg_killed
    "translate(109,22)", # 24
    # pos dropped
    "translate(0,23)", # 25
  ]

  CCOORDS = [
    [[190, 30], [190, 45], [190, 60], [190, 75], [190, 90], [190, 105]],
    [[174, 30], [174, 45], [174, 60], [174, 75], [174, 90], [174, 105]],
    [[158, 30], [158, 45], [158, 60], [158, 75], [158, 90], [158, 105]],
    [[142, 30], [142, 45], [142, 60], [142, 75], [142, 90], [142, 105]],
    [[126, 30], [126, 45], [126, 60], [126, 75], [126, 90], [126, 105]],
    [[110, 30], [110, 45], [110, 60], [110, 75], [110, 90], [110, 105]],
    [[85, 30], [85, 45], [85, 60], [85, 75], [85, 90], [85, 105]],
    [[69, 30], [69, 45], [69, 60], [69, 75], [69, 90], [69, 105]],
    [[53, 30], [53, 45], [53, 60], [53, 75], [53, 90], [53, 105]],
    [[37, 30], [37, 45], [37, 60], [37, 75], [37, 90], [37, 105]],
    [[21, 30], [21, 45], [21, 60], [21, 75], [21, 90], [21, 105]],
    [[5, 30], [5, 45], [5, 60], [5, 75], [5, 90], [5, 105]],
    [[5, 215], [5, 200], [5, 185], [5, 170], [5, 155], [5, 140]],
    [[21, 215], [21, 200], [21, 185], [21, 170], [21, 155], [21, 140]],
    [[37, 215], [37, 200], [37, 185], [37, 170], [37, 155], [37, 140]],
    [[53, 215], [53, 200], [53, 185], [53, 170], [53, 155], [53, 140]],
    [[69, 215], [69, 200], [69, 185], [69, 170], [69, 155], [69, 140]],
    [[85, 215], [85, 200], [85, 185], [85, 170], [85, 155], [85, 140]],
    [[110, 215], [110, 200], [110, 185], [110, 170], [110, 155], [110, 140]],
    [[126, 215], [126, 200], [126, 185], [126, 170], [126, 155], [126, 140]],
    [[142, 215], [142, 200], [142, 185], [142, 170], [142, 155], [142, 140]],
    [[158, 215], [158, 200], [158, 185], [158, 170], [158, 155], [158, 140]],
    [[174, 215], [174, 200], [174, 185], [174, 170], [174, 155], [174, 140]],
    [[190, 215], [190, 200], [190, 185], [190, 170], [190, 155], [190, 140]],
    # 24  killed_neg
    [[189, 235], [174, 235], [159, 235], [144, 235], [129, 235], [114, 235]],
    # 25+ dropped_pos
    [[80, 235], [65, 235], [50, 235], [35, 235], [20, 235], [5, 235]],
    # -2 dropped_neg
    [[80, 6], [65, 6], [50, 6], [35, 6], [20, 6], [5, 6]],
    # -1  killed_pos
    [[189, 6], [174, 6], [159, 6], [144, 6], [129, 6], [114, 6]],
  ]

  TRIANGLES = [
    "M 77.90147,5 85.401473,72.5 93.401476,5 Z",
    "m 62.1,5 7.5,67.5 8,-67.5 z",
    "m 46.3,5 7.5,67.5 8,-67.5 z",
    "m 30.5,5 7.5,67.5 8,-67.5 z",
    "m 14.7,5 7.5,67.5 8,-67.5 z",
    "m -1.0846927,5 7.5,67.5 L 14.415307,5 Z"
  ]

  private def triangle(path, idx)
    tag "path", d: path, class: "triangle"
    tag "path", d: path, data_triangle: idx, class: "triangle-over"
  end

  private def triangles(offs = 0)
    TRIANGLES.each_with_index do |path, idx|
      triangle(path, offs + idx)
    end
  end

  TRG_OPS = ["translate(6.5)", "rotate(180,49.4,105.0)"]

  def render_side(offs = 0)
    tag "rect", height: "200", class: "half_board_bg", width: "96", x: "4.5", y: "5"
    TRG_OPS.each_with_index do |op, idx|
      num_corr = [6, 12, 0, 18]
      tag "g", class: "triangles", transform: op do
        triangles(num_corr[offs * 2 + idx])
      end
    end
  end

  SIDE_OPS = ["", "translate(105)"]

  private def render_board
    transform = cw? ? BOARD_CW_OP : ""

    tag "g", id: "layer0", style: "display:inline", transform: transform do
      tag "rect", height: "210", class: "board_bg", width: "210", x: "0", y: "0"
      SIDE_OPS.each_with_index do |op, idx|
        tag "g", transform: op do
          render_side(idx)
        end
      end
    end
  end
end
