# Insanarium: agreed long-term direction

Recorded September 15, 2026. The user explicitly endorsed this direction. This is a design reference, not authorization to implement every future feature immediately.

## Identity

An idle ecosystem where individuals come and go while the habitat develops. Neither an endless numerical leveling game nor full survival. The goal is a resilient aquarium that can reach a satisfying equilibrium and recover from disturbances.

Keep Godot 4, GDScript, Compatibility rendering, web targeting, and fully frontend-only systems. Active play uses normal simulation speed; away play is slower. Recovery must remain possible even with no animals or money.

## Long-term systems

- Multiple animals and plants: shrimp, snails, fish, grasses/plants, algae, and interactions between them. Reserve the sea urchin concept for a later algae-grazing or detritus role rather than bubble collection.
- Understandable food chains and different diets; decomposers consume leftovers but do not magically eliminate waste.
- Tank expansions add real capacity, zones, and species options. Zooming out may make animals appear smaller without changing biological size.
- Purchasable, upgradeable pets with vulnerability to alien attacks, including possible death. Injury warnings, shelter, defense, and recovery are possible supporting designs.
- Reproduction, inherited traits, and finite lifespans: replacement generations become part of management.
- Parentage and inbreeding risk. Repeated close-relative breeding increases probabilistic risks, rather than guaranteeing defects. Unrelated introductions should offer a remedy.
- Decorative mutations and harmful traits are separate concepts; rare color alone does not imply health or disease.
- Predictable aging, visible life stages, and advance warning before old-age death.

## Player experience

- Preparation and thoughtful habitat composition should matter more than constant clicking.
- Stable tanks should be achievable; new species or expansions introduce fresh decisions.
- Explain important consequences. Prefer a few legible biological relationships over an opaque realism simulation.
- Individual animal losses must not erase all progress. Lasting achievements may include habitats, equipment, discovered species, and recorded lineages.
- Avoid adding an automatic prestige/reset loop merely because this is an idle game.

## Lifecycle foundation (implemented September 15, 2026)

Stable individual IDs, parent IDs, simulation-age tracking, an animal inspector, and save migration are implemented. Old-age death and inbreeding penalties remain future work and require suitable warnings and tuning. Population benchmarking is included; gameplay caps remain unchanged.

Then consider plant/shrimp interactions, carrying capacity and tank expansion, and pet health/upgrades. Validate browser export and persistence before relying on offline progression.

Specific lifespans, genetic probabilities, ecological formulas, prices, and future mechanics remain open for discussion and playtesting.

## Personal progression (implemented September 16, 2026)

Keep the current game a personal, frontend-only simulation. Multiplayer trading, account services, and server-authoritative economies are outside the current scope. Local saves, bounded offline care at 10% speed (eight real hours maximum), a return summary, and JSON backup controls are implemented. Offline breeding and alien attacks are intentionally excluded from this first care model.

## Relaxed opening and sound (September 16, 2026)

Fresh tanks start with $100 and two fed fish. Hunger fills in 120 active seconds with a further 45-second rescue window. Growth requires 10/30 credits for Adult/Royal and 75 actual meals for Diamond. Existing stages remain earned. Clickable $1–$3 bubbles replace the plankton button, appearing every 3–5 active seconds even after extinction. Sound effects are original procedural audio with a persistent mute toggle. These are initial balance values, open to playtesting.
