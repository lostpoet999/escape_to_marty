extends Node

## NOTE: One child-down should use direct references.  Otherwise let's just use signalbus to make things easy.

## =============================================================================
## GAME STATE SIGNALS
## =============================================================================

## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: scenes_and_scripts/ui/escape_menu.gd -> show_menu
@warning_ignore("unused_signal")
signal game_state_paused

## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: scenes_and_scripts/ui/escape_menu.gd -> hide_menu, scenes_and_scripts/player_paddle/paddle.gd -> _on_game_state_playing
@warning_ignore("unused_signal")
signal game_state_playing

## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: None
@warning_ignore("unused_signal")
signal game_state_game_over

## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: None
@warning_ignore("unused_signal")
signal game_state_main_menu

## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: scenes_and_scripts/player_paddle/paddle.gd -> _on_game_state_click_mode
@warning_ignore("unused_signal")
signal game_state_click_mode

## =============================================================================
## LEVEL/GAMEPLAY SIGNALS
## =============================================================================

## Emits: scenes_and_scripts/levels/level_01.gd -> check_level_cleared()
## Connects: scenes_and_scripts/singletons/game_manager.gd -> load_next_level
@warning_ignore("unused_signal")
signal level_cleared

## Emits: scenes_and_scripts/bricks/blue_brick.gd -> _on_tween_finished()
## Connects: scenes_and_scripts/levels/level_01.gd -> update_stars_in_level
@warning_ignore("unused_signal")
signal star_spawned(amount: int)

## Emits: scenes_and_scripts/star_collectible/star_collectible.gd -> _on_area_entered(), _on_body_entered()
## Connects: scenes_and_scripts/levels/level_01.gd -> update_stars_in_level
@warning_ignore("unused_signal")
signal star_collected(amount: int)

## Emits: scenes_and_scripts/bricks/blue_brick.gd -> _on_tween_finished()
## Connects: scenes_and_scripts/levels/level_01.gd -> _on_brick_destroyed
@warning_ignore("unused_signal")
signal brick_destroyed

## =============================================================================
## PLAYER/UI SIGNALS
## =============================================================================

## Emits: scenes_and_scripts/singletons/player_data.gd -> change_player_stars(), scenes_and_scripts/levels/level_01.gd -> _ready() (initial sync)
## Connects: scenes_and_scripts/ui_main/main_ui.gd -> update_star_ui
@warning_ignore("unused_signal")
signal stars_updated

## Emits: scenes_and_scripts/singletons/player_data.gd -> update_player_score(), scenes_and_scripts/levels/level_01.gd -> _ready() (initial sync)
## Connects: scenes_and_scripts/ui_main/main_ui.gd -> update_score_ui
@warning_ignore("unused_signal")
signal score_updated

## Emits: scenes_and_scripts/singletons/player_data.gd -> accept_damage(), scenes_and_scripts/levels/level_01.gd -> _ready() (initial sync)
## Connects: scenes_and_scripts/ui_main/main_ui.gd -> update_player_health
@warning_ignore("unused_signal")
signal player_health_updated

## Emits: scenes_and_scripts/singletons/player_data.gd -> accept_damage()
## Connects: scenes_and_scripts/singletons/game_manager.gd -> _load_level_on_player_death
@warning_ignore("unused_signal")
signal player_died
