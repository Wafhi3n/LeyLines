# Changelog

## v1.1.1

New name, Ley Line / Elemental Convergence Tracker, since Horde players track convergences with it
too, and an icon of its own in the addon list. Nothing else changes. Your saved spots, your
settings and the /ley command stay as they were.

## v1.1.0

Horde players are covered now. You absorb Elemental Convergences (the tornadoes) with Skysight
instead of ley lines, and the addon tracks those the same way. Every spot remembers which kind it
is, so your Alliance characters only see ley lines and your Horde characters only see
convergences, even when they share an account. Messages use the right name for your faction.

The Skyborn spell is built in, so the first cast on a rift already saves it. No `/ley learn`
needed.

You can share spots now. `/ley export` gives you a short code to send a friend and `/ley import`
reads one back. Codes from the test builds didn't say which faction a spot belongs to, so they're
refused instead of guessed. Ask for a new one.

`/ley contribute` gives you a code with only the spots you confirmed with the spell. Paste it in
the form at https://github.com/Wafhi3n/LeyLines/issues/new?template=positions.yml and it goes into
the list that ships with the addon, so everyone gets it on their next update. That list starts
with two ley lines on Zephras Isle. It never moves a spot you recorded yourself, and a spot you
delete stays deleted when the list grows.

Your spots from 1.0.0 carry over. Before sorting them by faction the addon keeps a plain text copy
of your old list in your saved file, and if your list ever loads empty it restores it from a
backup kept in the same file.

## v1.0.0

First release.

Ley Lines remembers where the rifts are and shows them on your minimap and world map, so the next
time your buff runs out you know where to ride.

Tell it which spell you use with `/ley learn`, then it reads the buff you get back. Fifteen minutes
means you were on a rift and the spot is saved. Fifteen seconds means you weren't, and nothing is
written down. You can also record one by hand with `/ley add` or a keybind.

Five minutes before the buff ends it tells you how far the nearest rift is and drops the game's own
map pin on it.

World map pins carry across maps, so the continent view shows everything you've found. Minimap pins
that fall outside the minimap's reach slide to the edge and dim instead of disappearing.

Built and tested on WoW: Forever (Camelot).
