class CreateScores::V20210220084214 < Avram::Migrator::Migration::V1
  def migrate
    create table_for(Score) do
      primary_key id : Int64
      add user_id : Int64
      add chat_id : Int64
      add score : Int32, default: 0
      # add_timestamps
    end
  end

  def rollback
    drop table_for(Score)
  end
end
