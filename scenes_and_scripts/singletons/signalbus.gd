extends Node

## NOTE: One child-down should use direct references.  Otherwise let's just use signalbus to make things easy.

## =============================================================================
## GAME STATE SIGNALS
## =============================================================================

## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: scenes_and_scripts/ui_menus/escape_menu.gd -> _on_game_state_pause_changed, scenes_and_scripts/actors/player/click_mode_cursor.gd -> _on_game_state_pause_changed, scenes_and_scripts/actors/player/mouse_gestures.gd -> _on_game_state_pause_changed
@warning_ignore("unused_signal")
signal game_state_pause_changed(paused: bool)

## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: scenes_and_scripts/ui_menus/escape_menu.gd -> hide_menu, scenes_and_scripts/player/paddle.gd -> _on_game_state_playing
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
## Connects: scenes_and_scripts/player/paddle.gd -> _on_game_state_click_mode
@warning_ignore("unused_signal")
signal game_state_click_mode


## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: scenes_and_scripts/ball/ball.gd -> remove_ball, scenes_and_scripts/player/paddle.gd -> _on_game_state_click_mode
@warning_ignore("unused_signal")
signal game_state_special_room

## Emits: scenes_and_scripts/db_panel/db_panel.gd -> _input()
## Connects: scenes_and_scripts/ball/ball.gd -> repopulate_effects_from_inventory, scenes_and_scripts/item_spawning/shop.gd -> populate_shop_panel
@warning_ignore("unused_signal")
signal db_panel_closed

## =============================================================================
## LEVEL/GAMEPLAY SIGNALS
## =============================================================================

## Emits: scenes_and_scripts/levels/room_base.gd -> _ready(), check_level_cleared(), scenes_and_scripts/levels/encounter_room_base.gd -> clear_encounter(), scenes_and_scripts/levels/common_rooms/memory room/memory_flame.gd -> close_memory(), scenes_and_scripts/db_panel/db_panel.gd -> _on_enable_exits_btn_pressed()
## Connects: scenes_and_scripts/singletons/game_manager.gd -> set_state_to_cleared, scenes_and_scripts/ball/ball.gd -> remove_ball, scenes_and_scripts/exits/exits.gd -> enable_exits, scenes_and_scripts/actors/player/paddle.gd -> _release_web, scenes_and_scripts/dialog/dialog_director.gd -> _on_level_cleared
@warning_ignore("unused_signal")
signal level_cleared

## Emits: scenes_and_scripts/actors/enemies/specific_enemies/boss_1_denial/boss_deon.gd -> accept_damage(); scenes_and_scripts/levels/floor_2_the_arena/rage_blob_king.gd -> _die(); scenes_and_scripts/actors/enemies/specific_enemies/the_collector/collector.gd -> _die()
## Connects: scenes_and_scripts/levels/deon_encounter_room.gd -> _ready() -> clear_encounter
@warning_ignore("unused_signal")
signal boss_defeated

## Emits: scenes_and_scripts/actors/enemies/specific_enemies/boss_1_denial/boss_deon_cage.gd -> _ready(), _on_seal_cleared(); boss_deon.gd -> _emit_progress(); scenes_and_scripts/levels/floor_2_the_arena/rage_blob_king.gd -> _finish_intro(), accept_damage(); scenes_and_scripts/levels/spider_encounter_room.gd -> _ready(), _emit_progress(); scenes_and_scripts/levels/statue_encounter_room.gd -> _ready(), _emit_progress(); scenes_and_scripts/actors/enemies/specific_enemies/the_collector/collector.gd -> _finish_intro(), _on_coffin_cleared(), _drop_bubble(), accept_damage()
## Connects: scenes_and_scripts/ui_menus/encounter_progress_bar.gd -> _on_encounter_progress
@warning_ignore("unused_signal")
signal encounter_progress(stage: int, stage_count: int, stage_remaining: float, stage_max: float)

## Emits: scenes_and_scripts/bricks/base_seal.gd -> _on_tween_finished(); money_thief_spider.gd -> _on_death(); repayment_spider.gd -> _spit_coin(), _on_death(); the_collector/collector.gd -> _toss_coin()
## Connects: scenes_and_scripts/levels/room_base.gd -> update_gold_in_level
@warning_ignore("unused_signal")
signal gold_spawned(amount: int)

## Emits: scenes_and_scripts/collectibles/bonus_drop.gd -> _on_area_entered(), collect(); money_thief_spider.gd -> _eat(); repayment_spider/spit_coin.gd -> _process(), _on_area_entered(), _resolve_hurt_miss()
## Connects: scenes_and_scripts/levels/room_base.gd -> update_gold_in_level
@warning_ignore("unused_signal")
signal gold_collected(amount: int)

## Emits: scenes_and_scripts/bricks/base_seal.gd -> _on_tween_finished()
## Connects: scenes_and_scripts/levels/room_base.gd -> _on_brick_destroyed
@warning_ignore("unused_signal")
signal brick_destroyed

## Emits: scenes_and_scripts/bricks/base_seal.gd -> _on_tween_finished()
## Connects: scenes_and_scripts/levels/room_base.gd -> _on_enemy_requested()
@warning_ignore("unused_signal")
signal enemy_requested(spawn_from: Area2D)

## Emits: scenes_and_scripts/ball/ball.gd -> spawn_collision_feedback(), scenes_and_scripts/powerups_and_behaviors/paddle_active_powerups/projectile_base.gd -> _on_area_entered()
## Connects: scenes_and_scripts/actors/enemies/wall_walker.gd -> _on_wall_hit, scenes_and_scripts/exits/exits.gd -> _on_wall_hit
@warning_ignore("unused_signal")
signal wall_hit(source: Node2D, wall: Node2D, damage: float, dmg_types: Array)

## Emits: scenes_and_scripts/actors/enemies/wall_walker.gd -> die(), _finish_escape()
## Connects: scenes_and_scripts/levels/room_base.gd -> _on_wall_walker_removed (spider_encounter_room.gd overrides the handler and rides this connection — do NOT re-connect in subclasses)
@warning_ignore("unused_signal")
signal wall_walker_removed(walker: Node2D)

## Emits: scenes_and_scripts/exits/floor_portal.gd -> handle_gesture_click()
## Connects: scenes_and_scripts/singletons/game_manager.gd -> floor_cleared
@warning_ignore("unused_signal")
signal floor_cleared

## Emits: scenes_and_scripts/bricks/practice_seal.gd -> _begin_practice_linger()
## Connects: scenes_and_scripts/levels/room_base.gd -> _on_practice_seal_cleared
@warning_ignore("unused_signal")
signal practice_seal_cleared

## Emits: scenes_and_scripts/exits/exits.gd -> _on_exit_clicked()
## Connects: scenes_and_scripts/levels/room_base.gd -> _on_practice_exit_blocked
@warning_ignore("unused_signal")
signal practice_exit_blocked

## =============================================================================
## PLAYER/UI SIGNALS
## =============================================================================

## Emits: scenes_and_scripts/singletons/player_data.gd -> change_player_gold(), scenes_and_scripts/levels/room_base.gd -> _ready() (initial sync)
## Connects: scenes_and_scripts/ui_level/main_ui.gd -> update_gold_ui
@warning_ignore("unused_signal")
signal gold_updated

## Emits: scenes_and_scripts/singletons/player_data.gd -> update_player_score(), scenes_and_scripts/levels/room_base.gd -> _ready() (initial sync)
## Connects: scenes_and_scripts/ui_level/main_ui.gd -> update_score_ui
@warning_ignore("unused_signal")
signal score_updated

## Emits: scenes_and_scripts/singletons/player_data.gd -> change_player_health(), scenes_and_scripts/levels/room_base.gd -> _ready() (initial sync)
## Connects: scenes_and_scripts/ui_level/main_ui.gd -> update_player_health
@warning_ignore("unused_signal")
signal player_health_updated

## Emits: scenes_and_scripts/singletons/player_data.gd -> accept_damage()
## Connects: scenes_and_scripts/singletons/game_manager.gd -> _cancel_click_mode_on_death (autoload connects first so click mode is exited before the paddle's cinematic starts), scenes_and_scripts/actors/player/paddle.gd -> _run_death_sequence
@warning_ignore("unused_signal")
signal player_died

## Emits: scenes_and_scripts/actors/player/paddle.gd -> _run_death_sequence() (after the death cinematic)
## Connects: scenes_and_scripts/singletons/game_manager.gd -> _load_level_on_player_death
@warning_ignore("unused_signal")
signal death_sequence_finished

## Emits: scenes_and_scripts/bricks/base_seal.gd -> _resolve_undercut() (GOLD on deal)
## Connects: scenes_and_scripts/levels/room_base.gd -> flash_play_area
@warning_ignore("unused_signal")
signal screen_flash(color: Color)

## Emits: scenes_and_scripts/singletons/player_data.gd -> accept_damage()
## Connects: scenes_and_scripts/levels/room_base.gd -> _on_player_damaged, scenes_and_scripts/actors/player/mouse_gestures.gd -> _on_player_damaged
@warning_ignore("unused_signal")
signal player_damaged(amount: int)

## Emits: scenes_and_scripts/singletons/player_data.gd -> grant_free_miss_shield(), accept_reflect_damage(), recompute_max_health(), _on_floor_cleared(); scenes_and_scripts/levels/room_base.gd -> _ready()
## Connects: scenes_and_scripts/actors/player/paddle.gd -> _on_reflect_shield_changed, scenes_and_scripts/ui_level/main_ui.gd -> update_player_shields, scenes_and_scripts/singletons/player_data.gd -> _on_reflect_shield_changed
@warning_ignore("unused_signal")
signal reflect_shield_changed(count: int)

## Emits: scenes_and_scripts/singletons/player_data.gd -> accept_reflect_damage()
## Connects: scenes_and_scripts/actors/player/mouse_gestures.gd -> _cancel_anger_hold
@warning_ignore("unused_signal")
signal player_shield_spent

## Emits: scenes_and_scripts/singletons/player_data.gd -> grant_pick2_voucher(), consume_pick2_voucher()
## Connects: scenes_and_scripts/ui_menus/free_item_panel.gd -> _update_footer (planned: inventory ticket UI)
@warning_ignore("unused_signal")
signal pick2_vouchers_changed(count: int)

## Emits: scenes_and_scripts/singletons/player_data.gd -> grant_shop_restock_voucher(), consume_shop_restock_voucher()
## Connects: scenes_and_scripts/ui_menus/shop_panel.gd -> _update_reroll (planned: inventory ticket UI)
@warning_ignore("unused_signal")
signal shop_restock_vouchers_changed(count: int)

## Emits: scenes_and_scripts/actors/player/paddle.gd -> _on_ball_magnet_radius_area_shape_entered(), _on_ball_magnet_radius_area_shape_exited()
## Connects: scenes_and_scripts/ball/ball.gd -> set_ball_in_magnet_range
@warning_ignore("unused_signal")
signal ball_in_magnet_range(is_in_range: bool)

## Emits: scenes_and_scripts/actors/player/paddle.gd -> _on_magnet_refresh_timeout()
## Connects: scenes_and_scripts/ball/ball.gd -> set_paddle_can_attract
@warning_ignore("unused_signal")
signal magnet_refresh_timeout

## Emits: scenes_and_scripts/ball/ball.gd -> attract_to_paddle()
## Connects: scenes_and_scripts/actors/player/paddle.gd -> reset_magnet_refresh_timer
@warning_ignore("unused_signal")
signal reset_magnet_refresh

## =============================================================================
## Inventory Signals
## =============================================================================

## Emits: scenes_and_scripts/inventory/inventory.gd -> add_item(), replace_paddle_active(), remove_item()
## Connects: scenes_and_scripts/inventory/inventory_panel.gd -> repopulate_inventory, scenes_and_scripts/ball/ball.gd -> repopulate_effects_from_inventory, scenes_and_scripts/player/paddle.gd -> set_paddle_length_from_items
@warning_ignore("unused_signal")
signal inventory_changed

## Emits: scenes_and_scripts/inventory/inventory.gd -> add_item()
## Connects: scenes_and_scripts/player/paddle.gd -> _assign_active_powerup
@warning_ignore("unused_signal")
signal paddle_active_assigned(item: PaddleActive)

## Emits: scenes_and_scripts/inventory/inventory.gd -> add_item()
## Connects: scenes_and_scripts/ui_menus/paddle_active_swap.gd -> _on_swap_needed
@warning_ignore("unused_signal")
signal paddle_active_swap_needed(old_item: PaddleActive, new_item: PaddleActive)

## Emits: scenes_and_scripts/ui_menus/paddle_active_swap.gd -> _on_new_item_pressed()
## Connects: scenes_and_scripts/inventory/inventory.gd -> replace_paddle_active, scenes_and_scripts/player/paddle.gd -> _assign_active_powerup
@warning_ignore("unused_signal")
signal paddle_swap_resolved(item: PaddleActive)

## Emits: scenes_and_scripts/inventory/inventory.gd -> add_item()
## Connects: scenes_and_scripts/ball/ball.gd -> _assign_active_powerup
@warning_ignore("unused_signal")
signal ball_active_assigned(item: BallActive)

## Emits: scenes_and_scripts/inventory/inventory.gd -> add_item()
## Connects: scenes_and_scripts/ui_menus/paddle_active_swap.gd -> _on_ball_swap_needed
@warning_ignore("unused_signal")
signal ball_active_swap_needed(old_item: BallActive, new_item: BallActive)

## Emits: scenes_and_scripts/ui_menus/paddle_active_swap.gd -> _on_new_item_pressed()
## Connects: scenes_and_scripts/inventory/inventory.gd -> replace_ball_active, scenes_and_scripts/ball/ball.gd -> _assign_active_powerup
@warning_ignore("unused_signal")
signal ball_swap_resolved(item: BallActive)

## Emits: scenes_and_scripts/ui_menus/paddle_active_swap.gd -> _on_old_item_pressed(), _on_new_item_pressed()
## Connects: scenes_and_scripts/inventory/inventory.gd -> add_item (awaited); false means the pick was declined and must not be charged
@warning_ignore("unused_signal")
signal active_swap_closed(kept_new: bool)

## =============================================================================
## Enemy Signals
## =============================================================================

## Emits: scenes_and_scripts/enemies/placed_enemy.gd -> _ready()
## Connects: scenes_and_scripts/player/paddle.gd -> add_blocker_enemy
@warning_ignore("unused_signal")
signal blocker_added(enemy: PlacedEnemy)

## Emits: scenes_and_scripts/enemies/placed_enemy.gd -> die(), scenes_and_scripts/enemies/specific_enemies/no_see_me_demon/deon.gd -> die()
## Connects: scenes_and_scripts/player/paddle.gd -> remove_blocker_enemy
@warning_ignore("unused_signal")
signal blocker_removed(enemy: PlacedEnemy)

## Emits: scenes_and_scripts/enemies/placed_enemy.gd -> pick_action(), scenes_and_scripts/enemies/enemy_actions/hop_to_center.gd -> execute_action(), scenes_and_scripts/enemies/enemy_actions/deon_boss_hop.gd -> execute_action(), scenes_and_scripts/enemies/specific_enemies/boss_1_denial/boss_deon.gd -> pick_action(), _on_cage_cleared()
## Connects: scenes_and_scripts/player/paddle.gd -> _calculate_blockers_bounds
@warning_ignore("unused_signal")
signal blocker_moved

## Emits: scenes_and_scripts/enemies/enemy_actions/hop_to_center.gd -> execute_action(), scenes_and_scripts/enemies/enemy_actions/deon_boss_hop.gd -> execute_action()
## Connects: scenes_and_scripts/enemies/placed_enemy.gd -> jump_land_shake
@warning_ignore("unused_signal")
signal jump_landed

## Emits: scenes_and_scripts/bricks/boss_deon_seal.gd -> _damage_current_stage()
## Connects: scenes_and_scripts/levels/common_rooms/boss_deon_cage.gd -> _on_seal_cleared
@warning_ignore("unused_signal")
signal deon_boss_seal_cleared(seal: Node2D)

## Emits: scenes_and_scripts/levels/common_rooms/boss_deon_cage.gd -> _on_seal_cleared()
## Connects: scenes_and_scripts/enemies/specific_enemies/boss_1_denial/boss_deon.gd -> _on_cage_cleared
@warning_ignore("unused_signal")
signal deon_boss_cage_cleared()

## Emits: scenes_and_scripts/enemies/enemy_actions/deon_boss_hop.gd -> spawn_cage()
## Connects: scenes_and_scripts/enemies/specific_enemies/boss_1_denial/boss_deon.gd -> _on_spawn_cage
@warning_ignore("unused_signal")
signal deon_boss_spawn_cage(world_pos: Vector2)
