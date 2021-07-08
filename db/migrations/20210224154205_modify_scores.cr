class ModifyScores::V20210224154205 < Avram::Migrator::Migration::V1
  def migrate
    alter table_for(Score) do
      remove :chat_id
      add inline_message_id : String, default: ""
    end
  end

  def rollback
    alter table_for(Score) do
      remove :inline_message_id
      add chat_id : Int64, fill_existing_with: :nothing
    end
  end
end
