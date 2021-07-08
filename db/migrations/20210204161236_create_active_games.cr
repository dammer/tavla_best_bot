class CreateActiveGames::V20210204161236 < Avram::Migrator::Migration::V1
  def migrate
    # Learn about migrations at: https://luckyframework.org/guides/database/migrations
    create table_for(ActiveGame) do
      primary_key id : Int64
      add_timestamps
      add player_a : Int64
      add callback_query_id : String, index: true
      add chat_instance : String
      add player_b : Int64?
      add game : String
      add version : Int32
      add started_at : Time?
    end
  end

  def rollback
    drop table_for(ActiveGame)
  end
end
