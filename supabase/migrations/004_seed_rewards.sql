-- 004_seed_rewards.sql
-- Seed reward_definitions from MissionDatabase.gd.
-- The server owns what each mission pays out; the client never determines reward amounts.
-- NFT payloads are stored as jsonb so grant_for_source can reconstruct them.

insert into public.reward_definitions (source_id, tokens, xp, nft, repeatable) values

  ('pattern_power', 10, 25,
   '{"nft_id":"pattern_star_nft","name":"Factory Worker Badge","description":"Awarded for completing your first shift at the Password Factory!","rarity":"common","discovered_from":"First Shift at the Password Factory","tradeable":false,"token_value":5}',
   false),

  ('chess_knight_jump', 12, 30,
   '{"nft_id":"knight_star_nft","name":"Knight Star Badge","description":"Awarded for mastering the knight''s leap!","rarity":"common","discovered_from":"Knight''s Jump","tradeable":false,"token_value":6}',
   false),

  ('soccer_goal_kicker', 12, 30,
   '{"nft_id":"golden_cleats_nft","name":"Golden Cleats Badge","description":"Earned by scoring goals with style!","rarity":"common","discovered_from":"Goal Kicker","tradeable":false,"token_value":6}',
   false),

  ('art_rainbow_maker', 12, 30,
   '{"nft_id":"palette_badge_nft","name":"Palette Badge","description":"For artists with a true eye for color!","rarity":"common","discovered_from":"Rainbow Maker","tradeable":false,"token_value":6}',
   false),

  ('daisy_fetch_game', 15, 40,
   '{"nft_id":"best_friend_nft","name":"Best Friend Badge","description":"Daisy gave you this in return for so much fun together.","rarity":"uncommon","discovered_from":"Daisy''s Fetch Game","tradeable":false,"token_value":8}',
   false),

  ('daisy_dog_pit', 10, 50,
   '{"nft_id":"pit_champion_nft","name":"Pit Champion Badge","description":"Awarded for guiding Daisy through the dog pit bouts.","rarity":"uncommon","discovered_from":"Dog Pit Bouts","tradeable":false,"token_value":10}',
   false),

  ('daisy_obedience_course', 8, 40,
   '{"nft_id":"good_girl_nft","name":"Good Girl Badge","description":"Daisy completed the obedience course with flying colors.","rarity":"common","discovered_from":"Obedience Course","tradeable":false,"token_value":8}',
   false),

  ('aquarium_rescue_bear', 18, 50,
   '{"nft_id":"bear_rescue_nft","name":"Bear Rescuer Badge","description":"You outwitted the Riddler and freed a bear!","rarity":"uncommon","discovered_from":"Aquarium Bear Rescue","tradeable":false,"token_value":12}',
   false),

  ('aquarium_rescue_dog', 18, 50,
   '{"nft_id":"dog_rescue_nft","name":"Dog Rescuer Badge","description":"You freed a dog from the aquarium — what a hero!","rarity":"uncommon","discovered_from":"Aquarium Dog Rescue","tradeable":false,"token_value":12}',
   false),

  ('aquarium_rescue_cat', 18, 50,
   '{"nft_id":"cat_rescue_nft","name":"Cat Rescuer Badge","description":"A sneaky cat freed by an even sneakier you!","rarity":"uncommon","discovered_from":"Aquarium Cat Rescue","tradeable":false,"token_value":12}',
   false),

  ('aquarium_rescue_dolphin', 30, 80,
   '{"nft_id":"dolphin_rescue_nft","name":"Dolphin Hero Badge","description":"A VIP hero who freed a dolphin from captivity!","rarity":"rare","discovered_from":"Aquarium Dolphin Rescue","tradeable":false,"token_value":20}',
   false),

  ('aquarium_rescue_hellokitty', 30, 80,
   '{"nft_id":"hellokitty_rescue_nft","name":"Hello Kitty Hero Badge","description":"You rescued the legendary Hello Kitty herself!","rarity":"rare","discovered_from":"Aquarium Hello Kitty Rescue","tradeable":false,"token_value":25}',
   false),

  ('aquarium_rescue_goldenbear', 35, 100,
   '{"nft_id":"goldenbear_rescue_nft","name":"Golden Bear Legend Badge","description":"Only the bravest rescuer could free the legendary Golden Bear!","rarity":"legendary","discovered_from":"Aquarium Golden Bear Rescue","tradeable":false,"token_value":30}',
   false),

  ('road_to_boston', 25, 80,
   '{"nft_id":"zia_cookie_nft","name":"Zia''s Star Cookie","description":"A magical treat from your grandmother Zia in Boston.","rarity":"uncommon","discovered_from":"Road to Boston","tradeable":false,"token_value":15}',
   false)

on conflict (source_id) do update set
  tokens     = excluded.tokens,
  xp         = excluded.xp,
  nft        = excluded.nft,
  repeatable = excluded.repeatable;
