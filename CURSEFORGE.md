# Ley Lines

Skyborn soak a ley line for a fifteen minute buff. Stand beside one instead of on it and you get
fifteen seconds. The rifts don't show up on your map, so the second time you want one you end up
riding around the zone trying to remember where it was.

This addon remembers them for you, on the minimap and on the world map.

## It learns from your own spell

Type `/ley learn` once, then cast your absorb spell. The addon remembers which spell that is, and
from then on it watches what comes back. Fifteen minutes of buff means you were standing on a rift,
so the spot gets saved. Fifteen seconds means you missed, and nothing is written down. The game
already knows whether you hit, so the addon reads its answer instead of guessing at ranges and at
where the object really sits.

You can record one by hand too. Stand on a rift, type `/ley add`, or bind a key to it.

## Five minutes before the buff drops

You get one line telling you how much time is left and how far the nearest known rift is, and a map
pin lands on it. It's the game's own pin, so there's nothing else to install. `/ley warn 3` moves
the warning, `/ley warn 0` turns it off.

## On the map

Minimap pins sit where the rift is. When one is further away than the minimap reaches, its pin
slides to the edge and dims, so you still know which way to ride.

World map pins carry across maps. Open the continent and you see every rift you've found, not only
the ones in the zone you're standing in. Click a pin to drop a waypoint on it.

There's also a small bar with the nearest rift, its distance, and an arrow that points where to
turn. Drag it wherever you want, right-click to hide it.

## Commands

`/ley` on its own says what it knows. After that: `add`, `del`, `list`, `clean`, `clear`, `hud`,
`pins`, `map`, `track`, `learn`, `auto`, `tooltip`, `warn <min>`, `name <text>`, `scale <n>` and
`probe`. `/ley help` prints the list in game.

## Notes

Everything stays on your machine. Nothing is sent anywhere, and all your characters share one list.

Built for WoW: Forever (Camelot). It leans on the mainline map APIs, which Classic Era doesn't have.

English, French, German and Spanish.
