class User < BaseModel
  skip_default_columns
  table do
    primary_key id : Int64
    column is_bot : Bool = false
    column first_name : String
    column last_name : String?
    column username : String?
    column language_code : String
    has_many scores : Score
  end
end
