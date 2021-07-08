class CreateChats::V20210220084203 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Chat) do
      primary_key id : Int64
      add type : String
      add title : String?
      add username : String?
      add first_name : String?
      add last_name : String?
      add description : String?
      # add_timestamps
    end
  end

  def rollback
    drop table_for(Chat)
  end
end
