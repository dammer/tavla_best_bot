class SaveScore < Score::SaveOperation
  def update_user_scores(user_id : Int64, imi : String, score : Int32) : Int32
    query = ScoreQuery.new
    query = query.inline_message_id(imi).user_id(user_id)
    if record = query.first?
      SaveScore.update!(record, score: record.score + score)
    else
      SaveScore.create!(user_id: user_id, inline_message_id: imi, score: score)
    end
    query.first.score
  end
end
