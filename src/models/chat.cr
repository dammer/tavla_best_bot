class Chat < BaseModel
  skip_default_columns
  table do
    primary_key id : Int64
    column type : String
    column title : String?
    column username : String?
    column first_name : String?
    column last_name : String?
    column description : String?
  end
end
