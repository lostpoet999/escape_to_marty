# Method Registry

Every method in the codebase, organized by script. Each entry describes what the method does and where it is called from.

---

## scenes_and_scripts/singletons/game_manager.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Configures frame rate, initializes player data, connects to `player_died` and `level_cleared` signals | Godot engine (scene enter) |
| `_input(event)` | Handles escape key (pause toggle) and click mode toggle | Godot engine (input event) |
| `change_state(to_state)` | Validates and executes a game state transition | `_input()`, `_load_level_on_player_death()`, `load_next_level()`, `escape_menu.gd`, `main_menu.gd` |
| `is_valid_state_transition(from, to)` | Returns whether a state transition is allowed | `change_state()` |
| `enter_state(state)` | Sets current state, configures mouse mode, emits the corresponding Signalbus signal | `change_state()` |
| `exit_state(state)` | Runs cleanup for the state being left (e.g. resets stats on leaving main menu, toggles pause) | `change_state()` |
| `pause_game()` | Toggles `get_tree().paused` | `enter_state()` (PAUSED), `exit_state()` (PAUSED) |
| `_configure_frame_rate()` | Disables VSync, detects monitor refresh rate, caps FPS at 2x refresh (max 300) | `_ready()` |
| `init_all_game_stats()` | Resets player data via PlayerData singleton | `exit_state()` (MAIN_MENU) |
| `restart_level()` | Resets player data and reloads the current scene | `escape_menu.gd -> _on_restart_button_pressed()` |
| `load_scene(scene)` | Changes to the given packed scene | `enter_state()` (GAME_OVER), `load_next_level()` (via call_deferred) |
| `_load_level_on_player_death()` | Transitions to GAME_OVER state | Signalbus `player_died` signal |
| `load_next_level()` | Transitions to MAIN_MENU and loads the main menu scene | Signalbus `level_cleared` signal |

---

## scenes_and_scripts/singletons/player_data.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `update_player_score(amount)` | Adds amount to score, emits `score_updated` | `blue_brick.gd -> _on_tween_finished()` |
| `get_player_score()` | Returns current score | `main_ui.gd -> update_score_ui()` |
| `initialize_player_data()` | Resets score, stars, and health to defaults | `GameManager.gd -> _ready()`, `init_all_game_stats()`, `restart_level()` |
| `change_player_stars(value)` | Adjusts star count, emits `stars_updated` | `star_collectible.gd -> _on_body_entered()` |
| `accept_damage(damage)` | Subtracts health and emits `player_health_updated`, or emits `player_died` if health would drop to 0 | `BaseDamageEffect.gd -> apply_damage()` |
| `get_player_health()` | Returns current health | `main_ui.gd -> update_player_health()` |
| `get_player_stars()` | Returns stars collected | `main_ui.gd -> update_star_ui()` |

---

## scenes_and_scripts/singletons/signalbus.gd

No methods. Pure signal definitions. See Signalbus.gd for the full signal list with emitter/connector documentation.

---

## scenes_and_scripts/ball/ball.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Positions ball on paddle, instantiates bounce effect, loads damage effects, calculates base damage | Godot engine (scene enter) |
| `_process(delta)` | Either tracks paddle position or moves ball depending on `on_paddle` state | Godot engine (every frame) |
| `position_ball_on_paddle()` | Snaps ball above the paddle center | `_ready()`, `_process()`, `BaseDamageEffect.gd -> apply_damage()` |
| `instantiate_all_effects()` | Iterates powerup_array, instantiates all attached DamageEffectRef scenes as children | `_ready()` |
| `update_base_dmg()` | Recalculates ball_dmg from DEFAULT_BALL_DMG plus all powerup bonuses/multipliers | `_ready()` |
| `get_paddle_half_height()` | Returns half the paddle collision shape height (handles rotation) | `position_ball_on_paddle()` |
| `_input(event)` | Launches ball on left click when on paddle | Godot engine (input event) |
| `launch_ball()` | Sets ball velocity based on paddle speed and initial_speed, starts movement | `_input()` |
| `move_ball(delta)` | Axis-separated movement: moves X, queries collisions, resolves; then moves Y, queries collisions, resolves. Applies leftover travel after bounces for smooth motion | `_process()` |
| `update_velocity(velocity_ref)` | Sets the ball's velocity (called by bounce effects) | `BaseBounceEffect.gd -> handle_paddle_collision()` |
| `query_collisions()` | Uses `PhysicsDirectSpaceState2D.intersect_shape()` with the ball's CircleShape2D to find overlapping colliders | `move_ball()`, `clean_collision_set()` |
| `push_out_x(collider, move_x)` | Pushes ball outside collider on X axis, direction opposite to movement | `move_ball()` (X step) |
| `push_out_y(collider, move_y)` | Pushes ball outside collider on Y axis, direction opposite to movement | `move_ball()` (Y step) |
| `get_collider_half_size(collider)` | Returns half-size of a collider's RectangleShape2D (scaled) | `push_out_x()`, `push_out_y()` |
| `handle_pierce(collider)` | Adds collider to `_collision_set` so it won't be damaged again while overlapping | `move_ball()` |
| `clean_collision_set()` | Removes colliders from `_collision_set` that the ball is no longer overlapping | `move_ball()` |
| `apply_collider_effects(collider)` | Runs all damage effects on the collider unless it's in `_collision_set` | `move_ball()` |

---

## scenes_and_scripts/bricks/blue_brick.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Sets health label text, enables input picking | Godot engine (scene enter) |
| `accept_damage(damage)` | Reduces health or triggers death tween if health would drop to 0 | `BaseDamageEffect.gd -> apply_damage()`, `_input_event()` (click mode) |
| `pop_tween()` | Plays scale-up then scale-down death animation | `accept_damage()` |
| `_input_event(viewport, event, shape_idx)` | Handles left-click to deal 1 damage (click mode testing) | Godot engine (Area2D input) |
| `_on_tween_finished(collider)` | Awards score, frees brick, spawns star collectible, emits `star_spawned` and `brick_destroyed` | `pop_tween()` (tween finished callback) |

---

## scenes_and_scripts/levels/level_01.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Emits initial UI sync signals, connects to brick/star signals | Godot engine (scene enter) |
| `check_level_cleared()` | If both stars and bricks cleared, emits `level_cleared` | `update_stars_in_level()`, `_on_brick_destroyed()` |
| `update_stars_in_level(amount)` | Tracks net star count (spawned - collected), sets `stars_cleared` when count reaches 0 | Signalbus `star_spawned`, `star_collected` signals |
| `_on_brick_destroyed()` | Checks remaining bricks in group, sets `bricks_cleared` when last brick is destroyed | Signalbus `brick_destroyed` signal |

---

## scenes_and_scripts/main_menu/main_menu.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Hides exit button on web platform | Godot engine (scene enter) |
| `_on_start_button_pressed()` | Changes state to PLAYING, loads level 01 | Start button signal |
| `_on_exit_button_pressed()` | Quits the application | Exit button signal |
| `_on_fullscreen_button_pressed()` | Toggles between fullscreen and windowed mode | Fullscreen button signal |

---

## scenes_and_scripts/player_paddle/paddle.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Calculates screen bounds, sets initial mouse position, connects to game state signals | Godot engine (scene enter) |
| `_on_game_state_playing()` | Unfreezes paddle movement | Signalbus `game_state_playing` signal |
| `_on_game_state_click_mode()` | Freezes paddle movement | Signalbus `game_state_click_mode` signal |
| `_input(event)` | Accumulates mouse movement for paddle position (when not frozen) | Godot engine (input event) |
| `get_movement_direction()` | Returns current paddle speed | Not currently called externally |
| `_physics_process(delta)` | Applies accumulated mouse position, calculates speed from frame delta | Godot engine (physics tick) |

---

## scenes_and_scripts/star_collectible/star_collectible.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Creates looping scale bounce animation | Godot engine (scene enter) |
| `_process(delta)` | Moves star downward at fall_speed | Godot engine (every frame) |
| `_on_area_entered(area)` | If star hits a death wall, emits `star_collected(-1)` and frees itself | Godot engine (Area2D overlap) |
| `_on_body_entered(body)` | If paddle catches star, emits `star_collected(-1)`, adds stars to PlayerData, frees itself | Godot engine (body overlap) |

---

## scenes_and_scripts/ui_menus/escape_menu.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Sets process mode to always, hides menu, connects to pause/play signals, hides exit on web | Godot engine (scene enter) |
| `show_menu()` | Shows the escape menu | Signalbus `game_state_paused` signal |
| `hide_menu()` | Hides the escape menu | Signalbus `game_state_playing` signal, `_ready()` |
| `_on_restart_button_pressed()` | Changes state to PLAYING, restarts the level | Restart button signal |
| `_on_button_pressed()` | Quits the application | Exit button signal |

---

## scenes_and_scripts/ui_level/main_ui.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `_ready()` | Connects to stars_updated, score_updated, and player_health_updated signals | Godot engine (scene enter) |
| `update_star_ui()` | Updates star count label from PlayerData | Signalbus `stars_updated` signal |
| `update_score_ui()` | Updates score label from PlayerData | Signalbus `score_updated` signal |
| `update_player_health()` | Updates health label from PlayerData | Signalbus `player_health_updated` signal |

---

## scenes_and_scripts/powerups_and_effects/ball_effects/bounce_effects/base_bounce_effect.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `handle_paddle_collision(ball, paddle)` | Calculates bounce angle based on hit position relative to paddle center, sets ball velocity | `ball.gd -> move_ball()` |
| `should_bounce(collider) -> bool` | Returns whether the ball should bounce off the collider (default: `true`). Override to implement pierce effects | `ball.gd -> move_ball()` |

---

## scenes_and_scripts/powerups_and_effects/ball_effects/bounce_effects/pierce_shot/pierce_shot.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `should_bounce(collider) -> bool` | Returns `false` for bricks (ball passes through), `true` for everything else (walls, etc.) | `ball.gd -> move_ball()` |

---

## scenes_and_scripts/powerups_and_effects/ball_effects/damage_effects/base_damage_effect.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `process_damage(ball, collider)` | Entry point: stores references, calls `process_targets()` | `ball.gd -> apply_collider_effects()` |
| `process_targets()` | Sets target to the collider, calls `apply_damage()` | `process_damage()` |
| `apply_damage(target)` | If target is a brick, calls `accept_damage()`. If death wall, returns ball to paddle and damages player | `process_targets()` |

---

## scenes_and_scripts/powerups_and_effects/ball_effects/damage_effects/damage_effect_wrapper.gd

| Method | Description | Called By |
|--------|-------------|-----------|
| `instantiate_effect()` | Instantiates the packed scene as a BaseDamageEffect | `ball.gd -> instantiate_all_effects()` |

---

## scenes_and_scripts/powerups_and_effects/ball_powerups/ball_power_up.gd

No methods. Resource class with exported properties for power-up configuration (name, id, damage stats, rarity, type, attached effects).
