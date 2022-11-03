## Hard Rules
  - Keep ids below 999 (for room editing) and unique unless necessary
  - Keep variants in the 0-4095 range (and try to follow the conventions listed below)
  - Keep subtypes within the 0-255 range

## Variant Conventions
  - Enemies: usually variant 541, true variants just be near that in some sane way
  - Bosses: "variants" like monsnow are variant 3133, all others are variant 2678 (except narc who has his own)
  - Non enemy entities that are room hazards/mechanics: e.g. ice block dudes, grillos, usually around variant 333
  - Elites: variant 1005
  - Prank: id 753, variant follows in sequence from 1005
  - Narc: variant 826, effects and other helpers follow sequence from 3480 (make sure id+variant is unique)
  - Effects and Familiars: just make sure it's unique and doesn't conflict with base game