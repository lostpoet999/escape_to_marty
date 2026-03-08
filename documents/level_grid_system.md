# Grid & Sprite Spec:

- **Target Resolution:** 1920 x 1080
- **Cell Size:** 64 x 64 pixels (everything but the paddle — seals, enemies, spirits, walls)
- **Brick Grid:** 24 wide × 12 tall (Note: use rows 11 and 12 towards the bottom sparringly)
- **Combat Zone:** ~4-5 cell-heights below the grid for enemies and paddle
- **PNG Import Size:** 24 × 12 pixels (one pixel = one cell) **Plan on doing a pixel png 24x12 to level import if its not too crazy to pull off.**

**NOTE: Collisions right now depend on a rectangle collision shape.  We can move away from this if extremely limiting but it will have trade-offs** 
**NOTE: Every level, sprite, enemy, tool, and import pipeline has a dependency on this spec.
