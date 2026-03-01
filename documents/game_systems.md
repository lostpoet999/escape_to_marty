# Game Systems Guide

Quick reference for how each system works in BreakOut. Each section answers a common "How do I..." question.

---

## How do I... add a new level?

1. Duplicate `scenes_and_scripts/levels/level_01.tscn` and its script `level_01.gd`
2. Arrange brick instances (from `scenes_and_scripts/bricks/blue_brick.tscn`) in your new scene
3. Add a preload constant in `scenes_and_scripts/singletons/game_manager.gd`:
   ```gdscript
   const LEVEL_02: PackedScene = preload("res://scenes_and_scripts/levels/level_02.tscn")
   ```
4. Update `load_next_level()` in GameManager to point to the new level
5. The level script tracks brick/star clearance automatically via Signalbus connections

---

## How do I... create a new brick type?

1. Duplicate `scenes_and_scripts/bricks/blue_brick.tscn` and its script
2. Adjust `brick_health` and `brick_score_value` exports in the inspector
3. Swap the sprite texture
4. Add the brick to the `bricks` node group (used for collision detection and win-condition counting)
5. The brick already handles damage, death tweens, star spawning, and score via the base script

---

## How do I... create a new bounce effect?

1. In the Godot editor: right-click the `scenes_and_scripts/powerups_and_effects/ball_effects/bounce_effects/` folder, select "New Script" extending `BaseBounceEffect`
2. Override either or both of these methods:
   - `should_bounce(collider: Node2D) -> bool` — return `false` to let the ball pass through a collider (pierce), `true` to bounce (default)
   - `handle_paddle_collision(ball: Ball, paddle: Paddle)` — customize the paddle bounce angle/velocity
3. The ball handles axis-separated movement and push-out internally. Bounce effects only control *whether* to bounce and *how* the paddle bounce works.
4. Assign your new effect scene to the ball's `bounce_effect_scene` export in the inspector

See `pierce_shot/pierce_shot.gd` for an example that returns `false` for bricks (ball passes through) but `true` for walls (still bounces).

---

## How do I... create a new damage effect?

1. Create a new script extending `BaseDamageEffect`
2. Override `process_targets()` or `apply_damage()` to customize what gets damaged and how
3. Create a `.tscn` scene for it (use `BaseDamageEffect.tscn` as reference)
4. Create a `DamageEffectRef` resource (`.tres`) pointing to your scene
5. Add the `DamageEffectRef` to a `BallPowerUp` resource's `attached_effects` array

---

## How do I... create a new power-up?

1. Create a new `BallPowerUp` resource (`.tres`) in `scenes_and_scripts/powerups_and_effects/ball_powerups/`
2. Set properties in the inspector:
   - `powerup_name` and `powerup_id` for identification
   - `global_damage_bonus` / `global_damage_multi` to modify ball damage
   - `rarity` (COMMON, UNCOMMON, RARE, VERY_RARE)
   - `powerup_type` (BOUNCE, MOVEMENT, DAMAGE)
3. Attach any `DamageEffectRef` resources to the `attached_effects` array
4. Add the power-up resource to the ball's `powerup_array` export

---

## How do I... add a new signal?

1. Define the signal in `scenes_and_scripts/singletons/signalbus.gd` under the appropriate section
2. Add `@warning_ignore("unused_signal")` above it
3. Document it with `## Emits:` and `## Connects:` comments showing which scripts emit and connect
4. Emit from the source script: `Signalbus.your_signal.emit()`
5. Connect from the listener script: `Signalbus.your_signal.connect(your_callback)`

All cross-scene communication should go through Signalbus. Direct references are only for parent-to-immediate-child.

---

## How do I... modify player stats?

Player state lives in the `PlayerData` singleton:

- **Score**: `PlayerData.update_player_score(amount)` - adds to score, emits `score_updated`
- **Health**: `PlayerData.accept_damage(damage)` - subtracts health, emits `player_health_updated` or `player_died`
- **Stars**: `PlayerData.change_player_stars(value)` - adjusts star count, emits `stars_updated`
- **Reset**: `PlayerData.initialize_player_data()` - resets all stats to defaults

The HUD (`main_ui.gd`) auto-updates by connecting to those signals.

---

## How do I... change game state?

Use the GameManager state machine:

```gdscript
GameManager.change_state(GameManager.GameState.PLAYING)
```

Valid states: `MAIN_MENU`, `PLAYING`, `PAUSED`, `GAME_OVER`, `CLICK_MODE`

State transitions are validated - not all transitions are allowed. Check `is_valid_state_transition()` in GameManager for the full transition table. Each state change emits a corresponding Signalbus signal and handles mouse mode automatically.

---

## How do I... add UI that responds to game events?

1. Create your UI scene extending `Control`
2. In `_ready()`, connect to the relevant Signalbus signals:
   ```gdscript
   Signalbus.score_updated.connect(my_update_function)
   ```
3. Read current values from `PlayerData` (score, health, stars) or `GameManager` (state)
4. If your UI needs to work during pause, set `process_mode = Node.PROCESS_MODE_ALWAYS`

See `scenes_and_scripts/ui_level/main_ui.gd` for a simple HUD example and `scenes_and_scripts/ui_menus/escape_menu.gd` for a pause-aware menu.
