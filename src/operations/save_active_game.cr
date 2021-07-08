class SaveActiveGame < ActiveGame::SaveOperation
  attribute player_action : String
  attribute score : Int32
  attribute index : String
end
