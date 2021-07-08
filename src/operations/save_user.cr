class SaveUser < User::SaveOperation
  permit_columns id, is_bot, first_name, last_name, username, language_code
end
