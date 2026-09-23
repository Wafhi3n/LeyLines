# Ley Lines

<!-- Texte EXACT publie sur la page CurseForge (resume + description), garde ici pour que la page
     et le depot ne divergent pas. Toute retouche de la page se recopie dans ce fichier. -->

## Summary

Remembers every ley line you find and pins it on your minimap and world map, with a warning before
your buff runs out.

## Description

Skyborn soak a ley line for a fifteen minute buff. Stand beside one instead of on it and you get
fifteen seconds. The rifts don't show on your map, so the second time you want one you end up
riding around trying to remember where it was.

Just cast your absorb spell. The addon reads the buff you get back: fifteen minutes means you were
on a rift and the spot is saved, fifteen seconds means you missed and nothing is written down.
Nothing to set up. You can also stand on one and type /ley add, or bind a key to it.

Rifts then show up on your minimap and on the world map. A pin slides to the minimap edge and dims
when one is out of range, so you still know which way to ride, and the continent view shows every
rift you've found. Five minutes before your buff ends, the addon tells you how far the nearest one
is and drops the game's own map pin on it, so you don't need TomTom.

Local only, nothing is sent anywhere, and all your characters share one list.

Built for WoW: Forever (Camelot). English, French, German and Spanish.

## Beta note: Forever forgets what addons remember

The beta writes addon data to disk but doesn't read it back when you log in, so anything an addon
remembers is gone the next session — this one included. It's a client bug and an addon can't work
around it: there's nowhere left to put anything, I checked.

The ley lines that ship with the addon aren't affected. They live in the addon's own files, so you
always get those, every session.

Your own finds are what you lose. Export them before you reload: `/ley export` gives you a block of
text to paste anywhere outside the game, and `/ley import` puts it back. The addon reminds you once
per session, the first time you find a rift.

If you'd rather have it all just work, ForeverSVFix (github.com/nobewayo/ForeverSVFix) restores
saved variables until Blizzard fixes the client.
