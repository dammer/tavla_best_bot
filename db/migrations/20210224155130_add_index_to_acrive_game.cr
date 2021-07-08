class AddIndexToAcriveGame::V20210224155130 < Avram::Migrator::Migration::V1
  def migrate
    create_index :active_games, [:inline_message_id], unique: false
    create_index :scores, [:inline_message_id, :user_id], unique: true
  end

  def rollback
    drop_index :ascores, [:inline_message_id, :user_id]
    drop_index :active_games, [:inline_message_id]
  end
end
