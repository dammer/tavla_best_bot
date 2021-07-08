class Score < BaseModel
  skip_default_columns
  table do
    primary_key id : Int64
    column user_id : Int64
    column inline_message_id : String
    column score : Int32
  end
end
