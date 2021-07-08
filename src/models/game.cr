class Game
  include JSON::Serializable
  VER = 1

  BOARD_SIZE  = 4 * 6
  BOARD_RANGE = 0..BOARD_SIZE - 1
  DIRS        = [1, -1]
  INTL_SET    = [
    2, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 5,
    0, 0, 0, 0, 3, 0,
    5, 0, 0, 0, 0, 0,
  ]

  getter version : Int32 = Game::VER
  getter dir : Int32
  getter board : Array(Array(Int32))
  getter dices : Array(Int32)
  getter turns : Array(Int32)
  getter turns_used : Array(Int32)

  getter killed_neg : Int32
  getter killed_pos : Int32

  getter dropped_neg : Int32
  getter dropped_pos : Int32

  getter last_turn : Tuple(Int32, Int32, Int32)?

  getter arb_pos_score : Int32?
  getter arb_neg_score : Int32?

  @[JSON::Field(ignore: true)]
  getter rand : Random::PCG32 = Random.new

  def initialize(@dir : Int32 = 0)
    @board = clean_board
    @dices = [] of Int32
    @turns = [] of Int32
    @turns_used = [] of Int32
    @killed_neg = 0
    @killed_pos = 0
    @dropped_neg = 0
    @dropped_pos = 0
    @arb_pos_score = nil
    @arb_neg_score = nil
    @last_turn = nil
  end

  # Tuple
  def save_state
    {
      @dir,
      @board,
      @dices,
      @turns,
      @turns_used,
      @killed_neg,
      @killed_pos,
      @dropped_neg,
      @dropped_pos,
      @arb_pos_score,
      @arb_neg_score,
      @last_turn,
    }.clone
  end

  # Tuple
  def load_state(data)
    @dir, @board, @dices, @turns, @turns_used, @killed_neg, @killed_pos, @dropped_neg, @dropped_pos, @arb_pos_score, @arb_neg_score, @last_turn = data.clone
  end

  def killed
    killed_for(dir)
  end

  def killed?
    killed > 0
  end

  def killed_for(direction)
    direction > 0 ? killed_pos : killed_neg
  end

  def dropped
    dropped_for(dir)
  end

  def dropped?
    dropped > 0
  end

  def dropped_for(direction)
    direction > 0 ? dropped_pos : dropped_neg
  end

  def kill_taret(direction = dir)
    direction > 0 ? -1 : 24
  end

  def drop_taret(direction = dir)
    direction > 0 ? 24 : -1
  end

  def drop_area(from, direction = dir)
    direction > 0 ? (18..(from - 1)) : ((from + 1)..5)
  end

  def can_drop?
    return false if killed?
    area = dir > 0 ? (0..17) : (6..23)
    board[area].find { |x| x[0] == dir }.nil?
  end

  def can_drop_this?(from, dest, score)
    return false unless can_drop?
    return true if dest == drop_taret
    # puts "#{drop_area(from)}, fr: #{from}, sc: #{score}"
    board[drop_area(from)].find { |x| x[0] == dir }.nil?
  end

  def setup_game(set = INTL_SET)
    @board = clean_board
    set_intl_cells(set)
  end

  # текущее направление игры
  # движение фишек
  # активная сторона итп
  def dir
    @dir
  end

  # оcтавшиеся ходы
  def turns_left
    _turns = turns.dup
    turns_used.map do |v|
      if idx = _turns.index(v)
        _turns.delete_at(idx)
      end
    end
    _turns
  end

  def state
    return :wait_arbitration if dir.zero?
    return :wait_dice_roll if dices.size.zero?
    if turns_left.size > 0
      if all_possible.size > 0
        return :wait_turn
      else
        return :wait_transfer_turn
      end
    end
    return :game_win if game_win?
  end

  private def bang(dest)
    board[dest] = [0, 0]
    if other_dir > 0
      @killed_pos += 1
    else
      @killed_neg += 1
    end
  end

  private def put_back
    if dir > 0
      @killed_pos -= 1
    else
      @killed_neg -= 1
    end
  end

  def drop(side = dir, qty = 1)
    if side > 0
      @dropped_pos += qty
    else
      @dropped_neg += qty
    end
  end

  def game_win?
    dropped > 14
  end

  def in_board?(dest : Int32)
    BOARD_RANGE.includes?(dest)
  end

  def game_clone
    game = Game.new
    game.load_state(save_state)
    game
  end

  # позы убитых
  def killed_idx(direction = dir)
    (direction > 0 ? BOARD_RANGE.begin : BOARD_RANGE.end) - direction
  end

  # куда идем
  def finish_idx
    (dir > 0 ? BOARD_RANGE.end : BOARD_RANGE.begin)
  end

  def distance_abs(first_idx, second_idx)
    arr = [first_idx, second_idx]
    arr.max - arr.min
  end

  # оценка позиции
  # мегамозг выбирает ход по этому критерию ;)
  def assess_position(game = self)
    single = 0
    multiple = 0
    BOARD_RANGE.each do |idx|
      next unless game.board[idx][0] == dir
      # дистанция от начала
      dist = distance_abs(idx, game.killed_idx)
      if game.board[idx][1] > 1
        cf = dist > 17 ? 1 : 0.9
        multiple += game.board[idx][1] * ([dist, 18].min * cf).to_i32
      elsif game.under_attack?(idx)
        single -= BOARD_SIZE + dist
      else
        multiple += (dist * 0.5).to_i32
      end
    end
    multiple += dropped * BOARD_SIZE
    (multiple + single) * (1 + killed_for(other_dir))
  end

  def self.other_dir(direction)
    direction * -1
  end

  # другая сторона
  def other_dir(direction = dir)
    direction * -1
  end

  # если межу финишем и позой есть враги то true
  def under_attack?(idx)
    return true if killed_for(other_dir) > 0
    range = ([idx, finish_idx].min)..([idx, finish_idx].max)
    board[range].find do |el|
      el[0] == other_dir
    end
  end

  def sim_mutate(game = self)
    result = [] of Tuple(Int32, Array(Tuple(Int32, Int32)))
    known_bad = Array(Array(Int32)).new
    # _skipped = 0
    mutate(game).each_with_index do |serie, i|
      next if known_bad.includes?(serie[0].not_nil!.to_a)
      g = game.game_clone
      path = Array(Tuple(Int32, Int32)).new
      serie.each_with_index do |turn, ii|
        from, sc = turn.not_nil!
        # ход не с доски и нет убитых
        break if from < 0 && !g.killed?
        # begin
        unless g.make_turn(from, sc, true) == sc
          known_bad << [from, sc] if ii == 0
          break
        end
        # rescue ex
        # puts "sim_turn #{i} #{ii} #{from}, #{sc}"
        # puts save_state
        # raise ex
        # end
        path << {from, sc}
      end
      # serie.size не годится
      # реально ходов может быть меньше поэтому 0
      if path.size > 0
        result << {g.assess_position(g), path}
      end
    end
    # puts "skipped #{_skipped}"
    result.sort_by { |x| x.first }
  end

  def mutate(game = self)
    # симуляция через make_turn поэтому -1 вместо killed_idx
    possible = [-1] * game.killed
    game.board.each_with_index do |(direction, qty), idx|
      next if direction != game.dir
      possible << idx
    end
    _turns = game.turns_left
    m_turns = _turns.permutations(_turns.size)
    m_pos = (possible * _turns.size).permutations(_turns.size).uniq
    vars = m_pos.map do |pos|
      m_turns.map do |tns|
        pos.zip(tns)
      end
    end
    vars.flatten.in_groups_of(_turns.size).uniq
  end

  def optimal_turn(game = self, log = false)
    ot = game.sim_mutate(game.game_clone)
    pp ot.reverse.uniq if log
    ot[-1][-1]
  end

  # все возможные ходы на доске
  def all_possible
    res = Hash(Int32, Array(Int32)).new
    turns_left.uniq.each_with_object(res) do |sc, obj|
      ppos = have_turn(sc)
      res[sc] = ppos if ppos.size > 0
    end
    res
  end

  def dests
    res = all_possible.map do |(sc, sources)|
      sources.map do |src|
        src + sc * dir
      end
    end
    res.flatten.uniq
  end

  def mars?(score)
    score > 14
  end

  def final_score
    distance_abs(dropped_pos, dropped_neg)
  end

  # есть ли ход на такую дистанцию(очки)
  def have_turn(score)
    possible = [] of Int32
    if killed?
      if game_clone.make_turn(killed_idx, score, true) == score
        possible << killed_idx
      end
      return possible
    end
    board.each_with_index do |(direction, qty), idx|
      next if direction != dir
      if game_clone.make_turn(idx, score, true) == score
        possible << idx
      end
    end
    possible
  end

  # логика и ограничения здесь
  def make_turn(from, score, sim = false)
    # ход который пытаются ходить
    # в списке доступных ходов
    return :b1 unless turns_left.includes?(score)
    # есть выбитые?
    if killed?
      # ходим не с доски, а c killed_neg | killed_pos
      return :b5 if in_board?(from)
    else
      # ячейка откуда ходим принадлежит тому чей ход
      return :b2 unless board[from][0] == dir
      # и в ней есть фишки ;)
      return :b3 unless board[from][1] > 0
      # нельзя ходить из убитых если их нет
      return :b7 unless in_board?(from)
    end
    # куда идём
    if in_board?(from)
      # ход с доски
      dest = from + (score * dir)
    else
      dest = score * dir
      # magic ;)
      dest -= 1 if dir > 0
    end

    # надо сбросить?
    if !in_board?(dest) && !killed?
      # все фишки дома?
      return :b6 unless can_drop?
      return :b6 unless can_drop_this?(from, dest, score)
      # сбрасываем
      drop
    else
      # занято чужими фишками?
      if board[dest][0] == other_dir
        # нельзя если чужих больше одной
        return :b4 if board[dest][1] > 1
        # убираем выбитую с доски
        bang(dest)
      end
      # ставим свою на новое место
      board[dest][0] = dir
      board[dest][1] += 1
    end

    # убираем фишку со старого места
    if in_board?(from)
      # c доски
      rest = board[from][1] -= 1
      # если на старом месте фишек не осталось,
      # чистим
      unless rest > 0
        board[from][0] = 0
      end
    else
      # из выбитых
      put_back
    end

    @turns_used << score

    return score if sim

    @last_turn = {dir, from, score}

    # сброшено меньше 15 фишек?
    if !game_win?
      # да, - игра не закончена
      transfer_turn if turns_left.size.zero?
    else
      # win!
      @turns_used = @turns
    end
    score
  end

  def transfer_turn
    # TODO: save history
    reset_turn
    @dir *= -1
  end

  def clean_last_turn
    @last_turn = nil
  end

  def reset_turn
    # clean_last_turn
    @turns.clear
    @turns_used.clear
    @dices.clear
  end

  def dice_roll(first = next_roll, second = next_roll)
    @dices << first
    @dices << second
    @turns = dices2turns
  end

  def double?
    # state == :wait_turn &&
    dices.size == 2 &&
      dices[0] == dices[1]
  end

  def my_turn?(player_dir)
    case state
    when :wait_arbitration
      arb_score_for(player_dir) == nil
    else
      player_dir == dir
    end
  end

  def player_action(player, game = self)
    # TODO: добавть стэйты для показа последнего
    # действия противника, хранить можно в game

    case game.state
    when :wait_arbitration
      if game.my_turn?(player)
        :roll_arb_dice
      else
        :wait_opp_arb_dice
      end
    when :wait_dice_roll
      if game.my_turn?(player)
        :roll_dices
      else
        :wait_opp_dices
      end
    when :wait_turn
      if game.my_turn?(player)
        :turn_made
      else
        :wait_opp_turn
      end
    when :wait_transfer_turn
      :no_movies_left
    when :game_win
      if game.dropped_for(player) > 14
        :winner
      else
        :loser
      end
    else
      :unknown_action
    end
  end

  def arb_score_for(player_dir)
    if player_dir > 0
      arb_pos_score
    else
      arb_neg_score
    end
  end

  # розыгрыш хода
  def arbitrate(direction : Int32, score : Int32)
    return unless state == :wait_arbitration
    if direction < 0
      return if arb_neg_score
      @arb_neg_score = score
    else
      return if arb_pos_score
      @arb_pos_score = score
    end
    if arb_pos_score && arb_neg_score
      diff = arb_pos_score.not_nil! <=> arb_neg_score.not_nil!
      if diff.zero?
        @arb_pos_score = nil
        @arb_neg_score = nil
      else
        @dir = diff
      end
    end
  end

  def next_roll
    rand.rand(1..6)
  end

  private def dices2turns
    return [] of Int32 if dices.size < 2
    if dices[0] == dices[1]
      dices * 2
    else
      dices
    end
  end

  private def clean_board
    (0..BOARD_SIZE - 1).map { [0, 0] }
  end

  private def set_intl_cells(set)
    @board = (0..BOARD_SIZE - 1).map { [0, 0] }
    DIRS.each do |direction|
      set = direction > 0 ? set : set.reverse
      @board.each_with_index do |cell, idx|
        if set[idx] > 0
          cell[0] = direction
          cell[1] = set[idx]
        end
      end
    end
  end
end
