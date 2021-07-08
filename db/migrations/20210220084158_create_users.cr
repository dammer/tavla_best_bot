class CreateUsers::V20210220084158 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(User) do
      primary_key id : Int64
      add is_bot : Bool, default: false
      add first_name : String
      add last_name : String?
      add username : String?
      add language_code : String
      # add_timestamps
    end
  end

  def rollback
    drop table_for(User)
  end
end
