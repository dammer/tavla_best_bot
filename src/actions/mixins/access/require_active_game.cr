module Access::RequireActiveGame
  macro included
    before require_active_game
  end

  @active_game : ActiveGame?

  private def require_active_game
    if active_game?
      continue
    else
      head status: 404
      # redirect to: ""#Home::Index
    end
  end

  private def active_game : ActiveGame
    @active_game.not_nil!
  end

  private def active_game? : Bool
    @active_game = ActiveGameQuery.new.by_game_signed_key(game_key)
    @active_game.is_a?(ActiveGame)
  end
end
