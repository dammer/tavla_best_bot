class AddInlineMessageIdToactiveGame::V20210216201445 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(ActiveGame) do
      # Add nullable column first
      add game_backup : String?
      add inline_message_id : String, default: ""
    end
  end

  def rollback
    alter table_for(ActiveGame) do
      remove :inline_message_id
      remove :game_backup
    end
  end
end
