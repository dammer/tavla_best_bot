require "../../../../spec_helper"

describe Bot::Webhooks::Create do
  it "can callback_query updates" do
    ActiveGameQuery.new.select_count.should eq 0
    # created only one game for player a
    2.times do
      response = ApiClient.exec(Bot::Webhooks::Create.with(good_bot_id), raw_body: raw_cq_a)
      response.status_code.should eq(200)
      response.body.should eq raw_cq_a

      ActiveGameQuery.new.select_count.should eq 1
      ActiveGameQuery.last.callback_query_id.should eq "1300812705922653094"
    end
    game_a = ActiveGameQuery.last
    game_a.player_a.should eq 300000000
    game_a.started_at.should eq nil

    # player b try connect
    response = ApiClient.exec(Bot::Webhooks::Create.with(good_bot_id), raw_body: raw_cq_b)
    response.status_code.should eq(200)
    response.body.should eq raw_cq_b

    ActiveGameQuery.new.select_count.should eq 1
    ActiveGameQuery.last.callback_query_id.should eq "1300812705922653094"
    game_a_b = ActiveGameQuery.last

    game_a_b.player_a.should eq 300000000
    game_a_b.player_b.should eq 300000001
    game_a_b.started_at.should eq nil
  end

  it "drop request with 404 if wrong bot_id given" do
    response = ApiClient.exec(Bot::Webhooks::Create.with(wrong_bot_id), raw_body: raw_cq_a)
    response.status_code.should eq(404)
    response.body.should eq ""
  end
end

def good_bot_id
  "777"
end

def wrong_bot_id
  "666"
end

# клик на кнопку Играть в..
def raw_cq_a
  %({"update_id":150830513,"callback_query":{"id":"1300812705922653094","from":{"id":300000000,"is_bot":false,"first_name":"Name1","last_name":"Fam1","username":"user1","language_code":"ru"},"inline_message_id":"AgAAAF_cAQBDag0SVY8RMl0fw1Y","chat_instance":"3093194184663775563","game_short_name":"tavla"}})
end

def raw_cq_b
  %({"update_id":150830562,"callback_query":{"id":"1489028068356136775","from":{"id":300000001,"is_bot":false,"first_name":"Name2","last_name":"Fam2","username":"user2","language_code":"ru"},"inline_message_id":"AgAAAF_cAQBDag0SVY8RMl0fw1Y","chat_instance":"3093194184663775563","game_short_name":"tavla"}})
end
