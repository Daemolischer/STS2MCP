# STS2 MCP — AI Gameplay Guide

This file only explains how to operate the game through the MCP tools. It deliberately contains no strategy:
decide every play yourself from the game state and from your own recorded experience in `GUIDE.md`.

## MCP Tool Calling Tips

### Timing
- The game reacts with a short delay. Wait about 1 second after each card or action and about 2 seconds before `combat_end_turn`; ending the turn too early can drop the last card.
- A tool result of `"status": "ok"` only means the command was accepted, not that it took effect. Confirm the outcome in the next game state.
- Instant Mode skips most animations. It is not saved between game starts: call `menu_select("instant_mode")` once after every game launch.

### State Polling
- After `combat_end_turn`, the state may show `is_play_phase: false` or `turn: enemy`. Call `get_game_state` again to advance to the next player turn.
- Sometimes you need to call `get_game_state` twice — once to see enemy turn results, once to see your new hand.
- Use `format: "json"` during combat for structured data; `format: "markdown"` for map/event overview.
- Read the state only as often as needed; every call costs tokens.

### Card Index Shifting
- **CRITICAL**: Playing a card removes it from hand and shifts all indices. Play cards from RIGHT to LEFT (highest index first) to keep lower indices stable, or re-check state between plays.
- Cards that draw add new cards to the right end of the hand.
- When targeting, always provide `target` for single-target cards. Entity IDs are UPPER_SNAKE_CASE with a `_0` suffix (e.g. `KIN_PRIEST_0`).
- When an enemy dies, the IDs of the remaining enemies of the same type can shift (e.g. `INKLET_2` becomes `INKLET_1`). Re-read the IDs before targeting.

### Event & Reward Flow
- Events: `event_choose_option`. After choosing, there's often a "Proceed" option at index 0.
- Rest sites: `rest_choose_option`, then `proceed_to_map`.
- Shops: `shop_purchase`, then `proceed_to_map`. Card removal opens a card selection (`deck_select_card`, `deck_confirm_selection`).
- Rewards: claim from right-to-left (highest index first) to avoid index shifting. Card rewards open a sub-screen; use `rewards_pick_card` or `rewards_skip_card`.

### Potions
- `use_potion(slot=N)` — slot is the potion slot index, not a card index.
- `discard_potion(slot=N)` — discard a potion to free up the slot when full.
- Potions don't cost energy or count as card plays.

### Menus
- If `singleplayer` is missing from the main menu, unrevealed Timeline unlocks are usually pending. The mod does not reveal them automatically; the player has to do it in the normal game window.
- Never call `delete_profile`.
