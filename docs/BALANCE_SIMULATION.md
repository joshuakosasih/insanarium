# Multi-seed balance simulation

Run September 25, 2026 against the real Godot gameplay systems. This is a diagnostic model, not a substitute for human playtesting. Subsequent hands-on play showed that this version materially overestimates alien danger: its one-second movement step and probabilistic action scan do not represent a warned player tracking the spawn point and tapping continuously. Treat its alien death and extinction figures as a stress case, not expected player outcomes. The recorded economy also predates the separation of Coin Value from Diamond Value, so its late-game wallet figures are retained as historical evidence rather than current projections.

## Method

Each profile ran 20 seeded sessions for 90 active minutes using one-second simulation steps. The driver uses the real fish movement, hunger, feeding, growth, reward, pet, water, breeding, invasion, purchase, and wallet code. Players collect each newly noticed reward according to their profile, save toward an explicit purchase plan, use automation after buying it, and rapidly deliver all eight alien hits once they react.

| Profile | Bubble / coin collection | Action scan | Alien reaction per scan | Purchase plan |
| --- | ---: | ---: | ---: | --- |
| Attentive optimizer | 95% / 95% | 1s | 95% | Feeder, helpers, six fish, Coin Value |
| Typical | 80% / 80% | 2s | 80% | Snail, feeder, shrimp, five fish, remaining pets |
| Typical without aliens | 80% / 80% | 2s | Disabled | Same as Typical |
| Relaxed | 50% / 55% | 4s | 55% | Same as Typical |
| Pet-first | 80% / 80% | 2s | 80% | All pets, feeder, then five fish |

Every death in the final simulation was caused by an alien. There were no starvation, water-quality, or old-age deaths within the 90-minute horizon.

## Median results

| Profile | Wallet | Fish | Clicks/min | Any death | Extinction | Royal | Diamond |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Attentive optimizer | $1,906.58 | 16 | 37.4 | 30% | 0% | 23.1m | 60.3m |
| Typical | $106.50 | 6 | 14.1 | 100% | 25% | 23.4m | 62.2m among the 11/20 runs that reached it |
| Typical without aliens | $122.29 | 12 | 12.8 | 0% | 0% | 23.4m | 60.2m |
| Relaxed | $45.50 | 0 | 4.6 | 100% | 100% | Never | Never |
| Pet-first | $62.50 | 3 | 9.0 | 100% | 70% | 23.6m among the 14/20 runs that reached it | 65.1m among 4/20 runs |

## Typical peaceful progression

The no-alien control isolates the aquarium economy and care loop:

| Milestone | 10th percentile | Median | 90th percentile |
| --- | ---: | ---: | ---: |
| Teen | 1.5m | 1.6m | 1.7m |
| Adult | 7.4m | 8.0m | 8.4m |
| Royal | 20.6m | 23.4m | 25.4m |
| Diamond | 55.3m | 60.2m | 63.2m |
| Feeder | 18.2m | 21.7m | 25.0m |
| Cleanup shrimp | 31.3m | 36.2m | 39.2m |
| Seahorse | 41.5m | 62.2m | 68.2m |
| Bubble puffer | 51.7m | 68.2m | 72.7m |

The peaceful loop is financially stable, but population growth is fast: the median reaches 12 fish and the 90th percentile reaches the 16-fish breeding limit within 90 minutes.

## Findings

1. **This driver exaggerates alien pressure.** A Typical profile that checks only every two seconds loses fish in every run and suffers total extinction in 25%, while the no-alien control has no deaths. Human testing does not reproduce that result because the warning and music cause earlier attention and real input is continuous rather than quantized into one-second movement steps.
2. **The biological growth curve is consistent.** Without alien disruption, stage timing has narrow variation and matches the analytical estimate: Teen around 1.6 minutes, Adult around 8, Royal around 23, and Diamond around 60.
3. **The former stacked economy had a runaway tail.** The optimizer's final wallet was $431.75 at the 10th percentile, $1,906.58 at the median, and $92,152.10 at the 90th percentile. That run allowed Diamond output and Coin Value to multiply each other. The current build separates those reward tracks and needs a fresh simulation before drawing a new late-game conclusion.
4. **Active attention is high.** Typical peaceful play takes a median 12.8 clicks per minute. Most are bubble collection before the puffer is purchased; automation-aware feeding is already modeled. This may suit an active clicker session but is high for a relaxed idle session.
5. **Pet-first spending does not protect the aquarium from combat.** Utility pets improve care but provide no defense, so the pet-first profile still has 70% extinction under current invasions.

## Recommended next tuning experiment

Keep the current hunger, water, stage timing, and live alien tuning for now. Before using combat results for balance, change the driver to substep alien movement and model a warning reaction delay followed by rapid taps. Compare that revised profile with hands-on sessions before making the invader harder.

After combat is stable, address the optimizer tail with a separate experiment. Candidate controls are slower breeding near capacity, diminishing Coin Value multipliers, or making high-value output require increasing upkeep. Changing all three together would hide which mechanism fixed the curve.

Reproduce the run from the repository root:

```sh
godot --headless --path . --script tests/balance_monte_carlo.gd -- --test
```
