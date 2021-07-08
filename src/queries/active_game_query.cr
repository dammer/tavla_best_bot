class ActiveGameQuery < ActiveGame::BaseQuery
  delegate extact_sign, key_parts, gen_sign, to: ActiveGame

  def by_game_signed_key(signed_key) : ActiveGame?
    return unless sign_valid?(signed_key)
    parts = key_parts("#{signed_key}")[1..2]
    inline_message_id(parts[0]).player_a(parts[1]).first?
  end

  def message_games(query)
    inline_message_id(query.inline_message_id.not_nil!)
  end

  def im_player_a(query)
    player_a(query.from.id)
  end

  def im_player_b(query)
    player_b(query.from.id)
  end

  def not_started
    started_at.is_nil
  end

  def wo_player_b
    player_b.is_nil
  end

  private def sign_valid?(signed_key) : Bool
    ext_sign = extact_sign(signed_key)
    parts = key_parts(signed_key)[1..-1]
    gen_sign = gen_sign(parts.join(ActiveGame::KS))
    gen_sign == ext_sign
  end
end
