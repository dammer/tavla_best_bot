class RemoveCallbackQueryIdFromActiveGame::V20210224153723 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(ActiveGame) do
      remove :callback_query_id
    end
  end

  def rollback
    alter table_for(ActiveGame) do
      add callback_query_id : String, index: true, default: ""
    end
  end
end
