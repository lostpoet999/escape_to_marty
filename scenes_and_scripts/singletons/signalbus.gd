extends Node

## NOTE: One child-down should use direct references.  Otherwise let's just use signalbus to make things easy.

## =============================================================================
## GAME STATE SIGNALS
## =============================================================================

## Emits: scenes_and_scripts/singletons/game_manager.gd -> enter_state()
## Connects: scenes_and_scripts/ui_menus/escape_menu.gd -> show_menu
@warning_ignore("unused_signal")
signal game_state_paused

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

## Emits: scenes_and_scripts/levels/room_base.gd -> _ready(), check_level_cleared(), scenes_and_scripts/levels/encounter_room_base.gd -> clear_encounter(), scenes_and_scripts/memories/memory_flame.gd -> close_memory(), scenes_and_scripts/db_panel/db_panel.gd -> _on_enable_exits_btn_pressed()
## Connects: scenes_and_scripts/singletons/game_manager.gd -> set_state_to_cleared, scenes_and_scripts/ball/ball.gd -> remove_ball, scenes_and_scripts/exits/exits.gd -> enable_exits
@warning_ignore("unused_signal")
signal level_cleared

## Emits: scenes_and_scripts/actors/enemies/specific_enemies/boss_1_denial/boss_deon.gd -> accept_damage()
## Connects: scenes_and_scripts/levels/deon_encounter_room.gd -> _ready() -> clear_encounter
@warning_ignore("unused_signal")
signal boss_defeated

## Emits: scenes_and_scripts/bricks/base_seal.gd -> _on_tween_finished()
## Connects: scenes_and_scripts/levels/room_base.gd -> update_gold_in_level
@warning_ignore("unused_signal")
signal gold_spawned(amount: int)

## Emits: scenes_and_scripts/collectibles/bonus_drop.gd -> _on_area_entered(), collect(); money_thief_spider.gd -> _eat()
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
## Connects: scenes_and_scripts/actors/enemies/wall_walker.gd -> _on_wall_hit
@warning_ignore("unused_signal")
signal wall_hit(source: Node2D, wall: Node2D, damage: float, dmg_types: Array)

## Emits: scenes_and_scripts/exits/floor_portal.gd -> _input_event()
## Connects: scenes_and_scripts/singletons/game_manager.gd -> floor_cleared
@warning_ignore("unused_signal")
signal floor_cleared

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
## Connects: scenes_and_scripts/singletons/game_manager.gd -> _load_level_on_player_death
@warning_ignore("unused_signal")
signal player_died

## Emits: scenes_and_scripts/bricks/base_seal.gd -> _resolve_undercut() (GOLD on deal)
## Connects: scenes_and_scripts/levels/room_base.gd -> flash_play_area
@warning_ignore("unused_signal")
signal screen_flash(color: Color)

## Emits: scenes_and_scripts/singletons/player_data.gd -> accept_damage()
## Connects: scenes_and_scripts/levels/room_base.gd -> _on_player_damaged
@warning_ignore("unused_signal")
signal player_damaged(amount: int)

## Emits: scenes_and_scripts/singletons/player_data.gd -> grant_free_miss_shield(), accept_reflect_damage()
## Connects: scenes_and_scripts/player/paddle.gd -> _on_reflect_shield_changed
@warning_ignore("unused_signal")
signal reflect_shield_changed(count: int)

## Emits: scenes_and_scripts/singletons/player_data.gd -> grant_pick2_voucher(), consume_pick2_voucher()
## Connects: scenes_and_scripts/ui_menus/free_item_panel.gd -> _update_footer (planned: inventory ticket UI)
@warning_ignore("unused_signal")
signal pick2_vouchers_changed(count: int)

## Emits: scenes_and_scripts/singletons/player_data.gd -> grant_shop_restock_voucher(), consume_shop_restock_voucher()
## Connects: scenes_and_scripts/ui_menus/shop_panel.gd -> _update_reroll (planned: inventory ticket UI)
@warning_ignore("unused_signal")
signal shop_restock_vouchers_changed(count: int)

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
