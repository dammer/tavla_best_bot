require "json"
require "spec"
require "../src/models/game"

describe Game do
  describe "complex test" do
    it "setup, start, play, kills" do
      game = Game.new
      game.setup_game

      game.board[0].should eq [1, 2]
      game.board[11].should eq [1, 5]
      game.board[16].should eq [1, 3]
      game.board[18].should eq [1, 5]
      game.board[5].should eq [-1, 5]
      game.board[7].should eq [-1, 3]
      game.board[12].should eq [-1, 5]
      game.board[23].should eq [-1, 2]

      game.board.map { |(d, v)| v }.sum.should eq 30
      game.board.map { |(d, v)| d }.sum.should eq 0

      game.arb_pos_score.should be_nil
      game.arb_neg_score.should be_nil
      game.state.should eq :wait_arbitration
      game.dir.should eq 0

      # game.pointed_state( 1) :waiting_a_roll
      # game.pointed_state(-1) :waiting_a_roll

      game.arbitrate(-1, 5)
      game.arb_neg_score.should eq 5
      game.state.should eq :wait_arbitration
      # game.pointed_state(1) :waiting_a_roll
      # game.pointed_state(-1) :waiting_opponent_a_roll

      game.arbitrate(1, 5)
      game.arb_pos_score.should be_nil
      game.arb_neg_score.should be_nil

      game.arbitrate(1, 5)
      game.arb_pos_score.should eq 5
      game.state.should eq :wait_arbitration
      game.dir.should eq 0

      # game.pointed_state( 1) :waiting_opponent_a_roll
      # game.pointed_state(-1) :waiting_a_roll

      game.arbitrate(-1, 3)
      game.arb_neg_score.should eq 3

      game.state.should eq :wait_dice_roll

      game.dir.should eq 1

      game.dices.size.should eq 0

      game.dice_roll
      game.dices.size.should eq 2

      (1..6).should contain(game.dices[0])
      (1..6).should contain(game.dices[1])

      game.turns.size.should be > 0
      game.turns_left.size.should be > 0

      game.turns_left.size.should eq game.turns.size

      game.state.should eq :wait_turn

      game.reset_turn
      game.dices.size.should eq 0
      game.turns.size.should eq 0
      game.turns_used.size.should eq 0
      game.turns_left.size.should eq 0
      game.double?.should be_false
      game.state.should eq :wait_dice_roll

      game.dice_roll(4, 4)
      game.dices.size.should eq 2
      game.double?.should be_true

      game.dices.should eq [4, 4]
      game.turns.should eq [4, 4, 4, 4]
      game.turns_left.should eq [4, 4, 4, 4]
      game.state.should eq :wait_turn

      game.dropped?.should be_false
      game.killed?.should be_false

      # нельзя чужой фишкой
      game.make_turn(23, 4).should eq :b2 # be_nil
      # нельзя c пустой ячейки
      game.make_turn(1, 4).should eq :b2 # be_nil
      # нельзя не выпашим
      game.make_turn(0, 1).should eq :b1 # be_nil

      game.make_turn(0, 4).should eq 4

      game.turns_used.should eq [4]
      game.turns_left.should eq [4, 4, 4]
      game.turns.should eq [4, 4, 4, 4]
      game.dropped?.should be_false
      game.killed?.should be_false
      game.state.should eq :wait_turn
      game.last_turn.should eq Tuple.new(1, 0, 4)

      # puts game.board
      game.board[0].should eq [1, 1]
      game.board[4].should eq [1, 1]

      game.make_turn(0, 4).should eq 4

      game.turns_used.should eq [4, 4]
      game.turns_left.should eq [4, 4]
      game.turns.should eq [4, 4, 4, 4]
      game.dropped?.should be_false
      game.killed?.should be_false
      game.state.should eq :wait_turn

      # puts game.board
      game.board[0].should eq [0, 0]
      game.board[4].should eq [1, 2]

      game.make_turn(4, 4).should eq 4
      game.make_turn(18, 4).should eq 4

      # puts game.board

      game.dir.should eq -1
      game.dices.size.should eq 0
      game.turns.size.should eq 0
      game.turns_used.size.should eq 0
      game.turns_left.size.should eq 0
      game.double?.should be_false

      game.state.should eq :wait_dice_roll

      # game.last_turn.should be_nil

      game.dice_roll(5, 1)

      game.dices.should eq [5, 1]
      game.double?.should be_false

      game.turns.should eq [5, 1]
      game.turns_left.should eq [5, 1]
      game.state.should eq :wait_turn

      game.make_turn(23, 1).should eq 1
      game.board[23].should eq [-1, 1]
      game.board[22].should eq [-1, 1]

      # puts game.board

      game.turns.should eq [5, 1]
      game.turns_used.should eq [1]
      game.turns_left.should eq [5]

      game.killed_neg.should eq 0
      game.killed_pos.should eq 1

      game.state.should eq :wait_turn

      game.make_turn(12, 5).should eq 5
      game.board[12].should eq [-1, 4]
      game.board[7].should eq [-1, 4]

      # puts game.board

      game.dir.should eq 1
      game.dices.size.should eq 0
      game.turns.size.should eq 0
      game.turns_used.size.should eq 0
      game.turns_left.size.should eq 0
      game.double?.should be_false

      game.killed_neg.should eq 0
      game.killed_pos.should eq 1

      game.state.should eq :wait_dice_roll

      # puts game.board

      game.dice_roll(2, 6)

      game.double?.should be_false

      game.turns.should eq [2, 6]
      game.turns_left.should eq [2, 6]
      game.state.should eq :wait_turn

      game.make_turn(4, 2).should eq :b5

      game.killed_neg.should eq 0
      game.killed_pos.should eq 1

      game.turns.should eq [2, 6]
      game.turns_left.should eq [2, 6]

      game.state.should eq :wait_turn

      game.make_turn(-1, 2).should eq 2

      game.turns.should eq [2, 6]
      game.turns_used.should eq [2]
      game.turns_left.should eq [6]

      # puts game.board

      game.killed_neg.should eq 0
      game.killed_pos.should eq 0

      game.board[1].should eq [1, 1]
      game.state.should eq :wait_turn

      game.make_turn(16, 6).should eq 6

      # puts game.board

      game.killed_neg.should eq 1
      game.killed_pos.should eq 0

      game.board[22].should eq [1, 1]
      game.state.should eq :wait_dice_roll

      game.dice_roll(2, 6)

      game.double?.should be_false

      game.turns.should eq [2, 6]
      game.turns_left.should eq [2, 6]
      game.state.should eq :wait_turn

      game.make_turn(23, 2).should eq :b5

      game.turns.should eq [2, 6]
      game.turns_left.should eq [2, 6]

      game.killed_neg.should eq 1
      game.killed_pos.should eq 0

      # puts game.board
      game.make_turn(-1, 2).should eq 2

      game.turns.should eq [2, 6]
      game.turns_used.should eq [2]
      game.turns_left.should eq [6]

      # puts game.board

      game.killed_neg.should eq 0
      game.killed_pos.should eq 1

      game.board[22].should eq [-1, 1]
      game.state.should eq :wait_turn
      game.can_drop?.should be_false
    end

    it "drop" do
      game = Game.new(1)
      drop_set = [
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 5, 5, 5,
      ]
      game.setup_game(drop_set)
      # puts game.board
      game.state.should eq :wait_dice_roll
      game.can_drop?.should be_true
      game.dropped.should eq 0
      game.dice_roll(2, 6)
      game.make_turn(21, 6).should eq 6
      game.board[21].should eq [1, 4]
      game.dropped.should eq 1
      # puts game.board
    end

    it "win!" do
      game = Game.new(1)
      drop_set = [
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 3,
      ]
      game.setup_game(drop_set)
      # puts game.board
      game.drop(1, 12)
      game.drop(-1, 12)

      game.dropped.should eq 12

      game.state.should eq :wait_dice_roll
      game.can_drop?.should be_true

      game.dice_roll(1, 4)
      game.state.should eq :wait_turn

      game.make_turn(23, 1).should eq 1

      game.dropped.should eq 13

      game.make_turn(23, 4).should eq 4
      game.dropped_pos.should eq 14
      game.state.should eq :wait_dice_roll

      game.dice_roll(1, 1)
      game.state.should eq :wait_turn
      game.dropped.should eq 12

      game.make_turn(0, 1).should eq 1
      game.dropped.should eq 13
      game.state.should eq :wait_turn

      game.make_turn(0, 1).should eq 1
      game.dropped.should eq 14
      game.state.should eq :wait_turn

      game.make_turn(0, 1).should eq 1
      game.dropped.should eq 15
      game.state.should eq :game_win
    end

    it "save state" do
      data = Tuple.new(
        1,
        [
          [1, 2], [0, 0], [0, 0], [0, 0], [0, 0], [-1, 5],
          [0, 0], [-1, 3], [0, 0], [0, 0], [0, 0], [1, 5],
          [-1, 5], [0, 0], [0, 0], [0, 0], [1, 3], [0, 0],
          [1, 5], [0, 0], [0, 0], [0, 0], [0, 0], [-1, 2],
        ],
        [] of Int32,
        [] of Int32,
        [] of Int32,
        0,
        0,
        0,
        0,
        nil,
        nil,
        nil
      )
      game = Game.new(1)
      game.setup_game
      game.save_state.should eq data

      game = Game.new
      game.load_state(data)
      game.save_state.should eq data
    end

    it "have dir" do
      data = Tuple.new(
        1,
        [
          [1, 2], [0, 0], [0, 0], [0, 0], [0, 0], [-1, 5],
          [0, 0], [-1, 3], [0, 0], [0, 0], [0, 0], [1, 5],
          [-1, 5], [0, 0], [0, 0], [0, 0], [1, 3], [0, 0],
          [1, 5], [0, 0], [0, 0], [0, 0], [0, 0], [-1, 2],
        ],
        [5, 1] of Int32,
        [5, 1] of Int32,
        [] of Int32,
        0,
        0,
        0,
        0,
        2,
        1,
        nil
      )
      game = Game.new
      game.load_state(data)

      game.dices.should eq [5, 1]
      game.double?.should be_false

      game.turns.should eq [5, 1]
      game.turns_left.should eq [5, 1]
      game.state.should eq :wait_turn
      game.have_turn(5).should eq [11, 16]
      game.save_state.should eq data
      game.have_turn(1).should eq [0, 16, 18]
      game.save_state.should eq data
    end

    it "no put_back if not killed" do
      game = Game.new
      game.load_state Tuple.new(1, [[-1, 4], [-1, 3], [0, 0], [-1, 2], [0, 0], [-1, 3], [1, 1], [-1, 1], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [-1, 2], [0, 0], [0, 0], [1, 6], [0, 0], [0, 0], [1, 4], [1, 3]], [5, 5], [5, 5, 5, 5], [] of Int32, 0, 1, 0, 0, 5, 6, nil)
      game.make_turn(-1, 5).should eq 5
      game.killed_pos.should eq 0
      game.killed_neg.should eq 0
      game.make_turn(-1, 5).should eq :b7
    end

    1.times do
      # pending "let's game!)" do
      it "let's game!)" do
        game = Game.new
        game.setup_game
        step = 0
        last_state = :no
        while game.state != :game_win
          if last_state != (st = game.state)
            puts "#{game.state}, #{game.dir}, k:#{game.killed} d: #{game.dropped}"
            last_state = st
          end
          case game.state
          when :wait_arbitration
            game.arbitrate(1, game.next_roll)
            game.arbitrate(-1, game.next_roll)
          when :wait_dice_roll
            game.dice_roll
            puts "#{game.dices}, step: #{step += 1}"
          when :wait_transfer_turn
            game.transfer_turn
          when :wait_turn
            ap = game.all_possible
            if ap.size > 0
              game.optimal_turn.each do |turn|
                from, sc = turn
                puts "make_turn(from: #{from}, score:#{sc})"
                game.make_turn(from, sc).should eq sc
              end
            else
              puts "no turns, transfer dir"
              game.transfer_turn
            end
          end
        end

        puts "#{game.state}, #{game.dir}, k:#{game.killed} d: #{game.dropped}"
      end
    end

    it "save && load state JSON" do
      game = Game.new
      game.setup_game

      saved = game.save_state
      puts json = game.to_json
      restored = Game.from_json(json)

      restored.save_state.should eq saved
    end

    it "out of index" do
      game = Game.new
      game.setup_game
      game.state.should eq :wait_arbitration
      game.arbitrate(1, 1)
      game.arbitrate(-1, 6)
      game.dir.should eq -1
      game.state.should eq :wait_dice_roll
      copy = game.game_clone
      game.dice_roll(6, 6)
      # puts game.board
      game.optimal_turn.sort.should eq [{23, 6}, {23, 6}, {12, 6}, {12, 6}].sort
      game.make_turn(23, 6).should eq 6
      game.make_turn(23, 6).should eq 6
      game.make_turn(12, 6).should eq 6
      game.make_turn(12, 6).should eq 6
      game.state.should eq :wait_dice_roll
      game.dice_roll(6, 6)
      game.optimal_turn.sort.should eq [{16, 6}, {16, 6}, {16, 6}].sort
    end

    it "strange behavior check" do
      data = Tuple.new(
        -1,
        [
          [0, 0], [0, 0], [0, 0], [0, 0], [0, 0], [-1, 5],
          [0, 0], [-1, 5], [0, 0], [0, 0], [0, 0], [0, 0],
          [-1, 1], [-1, 1], [-1, 1], [0, 0], [0, 0], [-1, 1],
          [0, 0], [0, 0], [1, 4], [1, 7], [-1, 1], [1, 4],
        ],
        [] of Int32,
        [] of Int32,
        [] of Int32,
        0,
        0,
        0,
        0,
        2,
        1,
        nil
      )

      game = Game.new
      game.load_state(data)
      game.state.should eq :wait_dice_roll
      game.dice_roll(3, 3)

      game.turns.should eq [3, 3, 3, 3]
      game.turns_left.should eq [3, 3, 3, 3]

      game.have_turn(3).should eq [5, 7, 12, 13, 14, 17, 22]
    end

    it "brain pos" do
      game = Game.new
      game.setup_game
      game.state.should eq :wait_arbitration
      game.arbitrate(1, 6)
      game.arbitrate(-1, 1)
      game.dir.should eq 1
      game.state.should eq :wait_dice_roll
      copy = game.game_clone
      game.dice_roll(3, 1)
      # puts game.board
      game.optimal_turn.sort.should eq [{16, 3}, {18, 1}].sort
      game = copy.game_clone
      game.dice_roll(3, 5)
      game.optimal_turn.sort.should eq [{18, 3}, {16, 5}].sort
    end

    it "brain neg" do
      game = Game.new
      game.setup_game
      game.state.should eq :wait_arbitration
      game.arbitrate(1, 1)
      game.arbitrate(-1, 6)
      game.dir.should eq -1
      game.state.should eq :wait_dice_roll
      game.dice_roll(3, 1)
      game.optimal_turn.sort.should eq [{7, 3}, {5, 1}].sort
    end

    it "mutate" do
      game = Game.new
      game.setup_game
      game.state.should eq :wait_arbitration
      game.arbitrate(1, 6)
      game.arbitrate(-1, 1)
      game.dir.should eq 1
      game.state.should eq :wait_dice_roll
      copy = game.game_clone
      game.dice_roll(3, 5)
      # game.dice_roll(2, 2)
      # pp game.mutate
      game.sim_mutate.last.last.should eq [{18, 3}, {16, 5}]
    end

    it "bug 0" do
      game = Game.new
      game.setup_game
      game.state.should eq :wait_arbitration
      game.arbitrate(-1, 1)
      game.arbitrate(1, 6)
      game.state.should eq :wait_dice_roll
      game.dice_roll(6, 5)
      game.state.should eq :wait_turn
      game.make_turn(0, 6)
      game.make_turn(6, 5)
      game.state.should eq :wait_dice_roll
      game.dice_roll(1, 1)
      game.state.should eq :wait_turn
      game.make_turn(23, 1)
      game.make_turn(5, 1)
      game.make_turn(4, 1)
      game.make_turn(23, 1)
      game.state.should eq :wait_dice_roll
      game.dice_roll(5, 1)
      game.state.should eq :wait_turn
      game.make_turn(11, 5)
      game.make_turn(0, 1)
      game.state.should eq :wait_dice_roll
      game.dice_roll(3, 3)
      game.state.should eq :wait_turn
      game.make_turn(12, 3)
      game.make_turn(3, 3)
      game.make_turn(5, 3)
      game.make_turn(12, 3)
      game.state.should eq :wait_dice_roll
      game.dice_roll(5, 4)
      game.state.should eq :wait_turn
      game.make_turn(1, 5)
      game.make_turn(6, 4)
      game.state.should eq :wait_dice_roll
      game.dice_roll(5, 2)
      game.state.should eq :wait_turn
      game.make_turn(2, 2)
      game.make_turn(12, 5)
      game.state.should eq :wait_dice_roll
      game.dice_roll(2, 2)
      game.state.should eq :wait_turn
      game.make_turn(18, 2)
      game.make_turn(11, 2)
      game.make_turn(11, 2)
      game.make_turn(18, 2)
      game.state.should eq :wait_dice_roll
      game.dice_roll(1, 4)
      game.state.should eq :wait_turn
      game.make_turn(5, 1)
      game.make_turn(4, 4)
      game.state.should eq :wait_dice_roll
      game.dice_roll(2, 2)
      game.state.should eq :wait_turn
      game.make_turn(18, 2)
      game.make_turn(11, 2)
      game.make_turn(11, 2)
      game.make_turn(18, 2)
      game.state.should eq :wait_dice_roll
      game.dice_roll(5, 3)
      game.state.should eq :wait_turn
      game.make_turn(12, 5)
      game.make_turn(12, 3)
      game.state.should eq :wait_dice_roll
      game.dice_roll(2, 2)
      # puts game.save_state
      game.state.should eq :wait_turn
      game.optimal_turn(game).sort.should eq [{16, 2}, {18, 2}, {11, 2}, {16, 2}].sort
      game.make_turn(16, 2)
      game.make_turn(18, 2)
      game.make_turn(11, 2)
      game.make_turn(16, 2).should eq 2
    end

    it "turn" do
      game = Game.from_json(%({"version":1,"dir":1,"board":[[-1,3],[-1,6],[-1,4],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[1,3],[1,2],[0,0],[1,3],[1,4],[1,3],[-1,2]],"dices":[6,2],"turns":[6,2],"turns_used":[2],"killed_neg":0,"killed_pos":0,"dropped_neg":0,"dropped_pos":0,"arb_pos_score":1,"arb_neg_score":5}))
      game.state.should eq :wait_transfer_turn
      game.all_possible.size.should eq 0
    end

    it "drop error" do
      game = Game.from_json(%({"version":1,"dir":1,"board":[[-1,6],[-1,2],[-1,4],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[-1,3],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[1,2],[1,1],[1,2],[1,2]],"dices":[3,6],"turns":[3,6],"turns_used":[],"killed_neg":0,"killed_pos":0,"dropped_neg":0,"dropped_pos":8,"arb_pos_score":6,"arb_neg_score":1}))
      clone = game.game_clone
      game.all_possible.should eq Hash.zip([3, 6], [[20, 21], [20]])
    end

    it "brain bug 1" do
      game = Game.from_json(%({"version":1,"dir":-1,"board":[[1,1],[0,0],[0,0],[0,0],[0,0],[-1,8],[-1,2],[-1,2],[0,0],[0,0],[0,0],[1,3],[-1,1],[0,0],[0,0],[0,0],[1,3],[1,1],[1,4],[0,0],[1,3],[0,0],[0,0],[-1,2]],"dices":[3,3],"turns":[3,3,3,3],"turns_used":[],"killed_neg":0,"killed_pos":0,"dropped_neg":0,"dropped_pos":0,"arb_pos_score":6,"arb_neg_score":1}))
      game.sim_mutate.last[1].should eq [{7, 3}, {7, 3}, {6, 3}, {6, 3}]
    end

    it "brain bug 2" do
      game = Game.from_json(%({"version":1,"dir":-1,"board":[[-1,10],[0,0],[0,0],[-1,3],[0,0],[0,0],[-1,1],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[1,1],[0,0],[-1,1],[1,7],[1,4],[1,3]],"dices":[3,2],"turns":[3,2],"turns_used":[],"killed_neg":0,"killed_pos":0,"dropped_neg":0,"dropped_pos":0,"arb_pos_score":6,"arb_neg_score":1}))
      game.sim_mutate.last.last.should eq [{6, 3}, {20, 2}]
    end

    it "brain bug 3" do
      game = Game.from_json(%({"version":1,"dir":-1,"board":[[-1,8],[-1,3],[0,0],[-1,2],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[0,0],[-1,1],[0,0],[1,3],[1,3],[1,1],[0,0],[-1,1]],"dices":[4,2],"turns":[4,2],"turns_used":[],"killed_neg":0,"killed_pos":0,"dropped_neg":0,"dropped_pos":8,"arb_pos_score":6,"arb_neg_score":1}))
      game.sim_mutate.last.last.should eq [{23, 2}]
    end

    it "launch bug" do
      game = Game.from_json(%({"version":1,"dir":0,"board":[[1,2],[0,0],[0,0],[0,0],[0,0],[-1,5],[0,0],[-1,3],[0,0],[0,0],[0,0],[1,5],[-1,5],[0,0],[0,0],[0,0],[1,3],[0,0],[1,5],[0,0],[0,0],[0,0],[0,0],[-1,2]],"dices":[],"turns":[],"turns_used":[],"killed_neg":0,"killed_pos":0,"dropped_neg":0,"dropped_pos":0,"arb_pos_score":6}))
      game.state.should eq :wait_arbitration
      game.arb_pos_score.should eq 6
      game.arb_score_for(1).should eq 6
      game.arb_score_for(-1).should be_nil
      game.my_turn?(1).should be_false
      game.my_turn?(-1).should be_true
    end
  end

  describe "#dir" do
    it "sh be 0 on new" do
      game = Game.new
      game.dir.should eq 0
    end
  end

  describe "#board" do
    it "sh be have a right size" do
      game = Game.new
      game.board.size.should eq 24
    end

    it "sh be a blank" do
      game = Game.new
      (0..23).each do |i|
        data = game.board[i]
        data.should eq [0, 0]
      end
    end
  end

  describe "#dices" do
    it "sh be a blank" do
      game = Game.new
      game.dices.size.should eq(0)
    end
  end
end
