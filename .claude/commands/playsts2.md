Play Slay the Spire 2 using the MCP tools (`mcp__sts2__*`). Your goal is to win the run.

## Setup
1. `AGENTS.md` explains how to operate the tools. It contains no strategy on purpose.
2. Read `GUIDE.md` if it exists. It holds only experience recorded in earlier runs. If it doesn't exist, you start without any.
3. Call `get_game_state(format="markdown")` to see the current state and begin playing.

## How to Decide
- Nobody prescribes which cards, paths or options to pick. Read the full state (cards, relics, potions, enemy HP, intents and powers) and decide what you consider best.
- Use `GUIDE.md` as evidence, not as rules: check whether a recorded experience applies to the current situation before relying on it.
- `search_wiki` and `get_compendium` only cover content the active profile has discovered.

## Recording Experience in `GUIDE.md`
Update `GUIDE.md` after each boss fight and at the end of every run, won or lost.

- Record observations with their context instead of fixed rules. Example: "Run 3, floor 8, Foglonis (Ironclad, 57 HP at start): lost 23 HP; most of it came from its 4x3 attack in round 2."
- Note the game version (`release_info.json` in the game folder) and the character for each entry.
- Only write a general conclusion when several runs support it, and note how many runs confirm or contradict it.
- Correct or remove entries that later runs disprove.
- Summarize each run in one line: character, floor reached, result, cause of death or key turning point.
