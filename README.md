# Insanarium — idle aquarium

Play the current browser build at **https://joshuakosasih.github.io/insanarium/**.

Godot 4.5.1, GDScript, Compatibility renderer. Entirely frontend-only, with original procedural vector artwork. No backend or account required.

Long-term design: [Agreed ecosystem direction](docs/DESIGN_DIRECTION.md). Future features in that document are plans, not all implemented.

## Run

Import `project.godot` in the standard Godot editor and press **F5**. Or run `godot --path .` from this directory. On macOS the executable may be `/Applications/Godot.app/Contents/MacOS/Godot`.

## Idle loop

Start with two fully fed amber fish and $100. Click water to feed, click rewards to collect, and click a fish to inspect it. Selling requires the separate **Sell fish** button, which displays its exact value. The first persistent tank objective is to reach 20 living fish. Both purchases and breeding stop at that hard capacity, so population remains bounded.

**Income bubbles** appear every 3–5 active seconds, including at $0 with no fish. Small unlabelled bubbles rise from near the bottom to the surface. Pop one for a random $0.50, $1, $2, or $3; the reward is revealed after popping. The tank initially holds one bubble at a time. Capacity upgrades raise that limit through 1, 2, 3, 5, and 8, while a separate value track multiplies every reward by 1×, 1.5×, 2.25×, 3.5×, and 5×. Each track costs $30, $90, $270, then $810. Bubbles disappear at the surface after roughly 22–24 seconds; missed bubbles give no money. A purchased Bubble Puffer wanders through the water and may chase each bubble it notices. It pops accepted targets on contact and briefly inflates afterward. Bubbles are active-play income and are not generated offline, so the puffer earns no offline bubble income. Wallet arithmetic uses integer cents, retaining fractional dollars through purchases, saves, backups, and offline care. A replacement or third fish costs $50; each additional living fish raises the next shop price by about 65%, rounded to the nearest $5. The price reaches $2,745 at ten fish and $249,000 at nineteen, making breeding and selling stock central near the capacity limit. Losing or selling every fish does not reset the tank, upgrades, or pets: earn money and rebuild.

| Stage | Requirement | Coin payout every 20 seconds | Normal sale | Mutated sale |
| --- | --- | --- | --- | --- |
| Baby | Starting stage | None | $5 | $10 |
| Teen | 2 growth credits | $1 bronze | $15 | $30 |
| Adult | 10 growth credits | $2 silver | $120 | $240 |
| Royal | 30 growth credits | $3 gold | $350 | $700 |
| Diamond | 75 actual meals | $10 blue diamond | $1,200 | $2,400 |

Babies are deliberately brief and do not produce coins or waste. Two Basic meals produce a visibly larger Teen and start bronze-coin income; Adult, Royal, and Diamond remain longer goals. Existing saves retain equivalent maturity through schema migration. Every normal fish is amber. Diamond fish wear a tiny blue crown attached to the head in the aquarium and reveal card. Each growth-stage transition has an **8% mutation chance** for an unmutated fish. A mutation changes its color to Azure, Rose, or Jade and doubles its sale value. Each fish can mutate only once; mutation does not increase coin production. Already purchased or starting babies do not randomly start mutated. Coin Value multiplies ordinary fish coins by 1×, 2×, 3×, 5×, and 8× for $200, $800, $3,200, and $12,800. Diamond Value independently multiplies blue diamonds by 1×, 2×, 4×, 7×, and 12× for $150, $450, $1,350, and $4,050. The multipliers do not stack; coin color continues to show the producing fish's stage. The assumptions, milestone estimates, and upgrade payback math are recorded in [`docs/BALANCE_MODEL.md`](docs/BALANCE_MODEL.md); multi-seed player simulations and findings are in [`docs/BALANCE_SIMULATION.md`](docs/BALANCE_SIMULATION.md).

## Feed and survival

Basic costs $2 per pellet and grants 1 growth credit. Upgrade once for $50 to Premium ($4, 2 credits), then for $150 to Deluxe ($6, 3 credits). Manual feeding always uses the highest purchased tier: there is no downgrade selector. All food restores 0.65 hunger, and Diamond still requires 75 actual meals.

Open **Shop** above the tank to browse reusable illustrated cards for fish, helpers, feeder stock, and feed upgrades. Selecting a card opens its details and purchase action. Dragging directly over cards scrolls the catalog on touch screens and with a held mouse. Feed and stock previews adopt the currently unlocked pellet color: orange Basic, blue Premium, or violet Deluxe. The shop confirms each successful purchase; purchases also play the synthesized buy sound when sound is enabled.

While the game is focused, hunger grows at the relaxed rate of **1/120 per second** (two minutes from fully fed to maximum hunger), and the red bar gives **45 seconds** at maximum hunger to rescue the fish. When the game loses focus, is minimized, or its web tab is hidden, live simulation pauses. New tanks begin with offline simulation locked. The Away Time upgrade unlocks progressively safer windows of 5 minutes, 30 minutes, 2 hours, and finally 8 real hours for $50, $150, $450, and $1,350. On return, a bounded data-only calculation advances care at **10%** speed within the unlocked window. Returning immediately restores active speed without resetting hunger or starvation progress. Feeding resets the starvation timer. Dead fish stop participating immediately, flip belly-up, float to the surface, then fade. An orange dot means hungry; red means starving.

Pellets expire after 14 seconds. Manual drops have a 0.12-second cooldown. Rejected or unaffordable drops do not charge money. Food is limited to 80 active pellets. Coins and diamonds remain fully visible while falling. Their countdown begins only after they touch the substrate, with a short fade during the final 2 seconds. Ordinary coins initially last 8 simulation seconds; their shared Fish Coins card upgrades floor time to 15, 25, 45, and finally 75 seconds and has a separate Coin Value button. The Diamonds card independently upgrades diamond floor lifetime through the same five durations and separately multiplies diamond value. Reward position, grounded state, and remaining floor time are preserved in saves and away calculations. Rewards are limited to 150 entities, after which further payouts merge into an existing reward without extending its remaining lifetime.

Every fish has two hidden inheritable alleles for five player-facing traits: Vitality, Metabolism, Agility, Productivity, and Fertility. The allele values remain hidden, while the inspector presents five reusable bars with their direct outcomes. Vitality sets 60–160 maximum health, improves water resilience and recovery, and extends maximum age. Metabolism trades safety for pace: fast fish become hungry sooner, grow and produce rewards faster, and age faster. Agility sets swimming speed from 65–140% of the species baseline. Productivity sets the chance that an output becomes a coin rather than waste, from 40–95%. Fertility sets the individual breeding cooldown from seven to three simulation minutes. Starter fish are deliberately balanced; purchased fish draw from a wider range so breeding and selection produce visible differences. Offspring inherit one allele for every trait from each parent, with a small mutation chance.

Ordinary waste sinks to the substrate. Its fixed, non-upgradable 12-second countdown starts after landing, and it fades only during its final 2 seconds. Clicking it before it disappears restores 0.75 cleanliness points; natural disappearance does not undo its pollution. Living fish and pets create slow biological load, settled waste continues polluting while visible, and an expired pellet causes a larger cleanliness loss. The HUD shows cleanliness from Pristine through Toxic, while a foreground haze and suspended particles make cloudy, dirty, and toxic water visibly harder to see through. **Full clean** costs $25, removes visible waste, and immediately returns water to 100%; it becomes available below 99% so trivial biological load cannot trigger an accidental purchase. A fish below its hunger threshold regenerates in water at 65% or cleaner, with recovery accelerating from 0.05 health per second in merely clear water to 0.25 in pristine water. Hungry fish cannot regenerate. Below 65%, health begins falling and the damage rises geometrically for every ten cleanliness points lost. The effect is already visible at 60%, while 0% kills a healthy neutral fish in roughly five simulation seconds. High-vitality fish heal faster and resist damage longer; frail fish recover more slowly and die sooner. Fish display a health bar after taking damage, and exact health appears in the inspector. The same rules are used during offline catch-up and Tank Care forecasts.

## Sound

Original synthesized effects accompany bubble pops, feeding, coin collection, purchases, growth, fish loss, and alien warnings/hits. Bubble income uses a short air-and-water pop, while coin collection uses a distinct two-note metallic chime. The 1:45 **Underwater Theme II** by Cleyton Kauffman loops during normal play, then smoothly crossfades to MintoDog's loopable **Space Battle** from the alien warning until the invader is defeated or challenges are disabled. Both music tracks are CC0; exact source and license links are recorded in [`assets/audio/LICENSES.md`](assets/audio/LICENSES.md). Separate **Music** and **Effects** switches in the Controls panel let either channel continue while the other is muted. Both preferences are stored locally, separately from aquarium backups; the former single Sound preference migrates to both switches. Effects use a bounded six-voice pool with gentle volume and repeated-effect throttling. Browsers may require an initial click before starting audio. Away calculations remain silent.

## Individual lifecycle and inspector

Click a fish to open its inspector; the × closes it. It displays stable ID, species, sex, mutation, growth stage, age, origin, born/introduced tank time, parents, current and maximum health, hunger, meals, growth credits, output interval, natural breeding cycle, breeding readiness, exact sale price, and the five trait bars. Hidden allele values never appear in this player-facing panel. The inspector refreshes four times a second.

Buying a fish or welcoming an offspring first shows a short acquisition celebration: the animal scales into the center of a field of rotating rays and sparkles. The reusable fish reveal card then opens with the same original vector fish and five direct trait bars. Newborn cards name both parents and mark each outcome as above, below, or similar to their average. Purchased pets use the same celebration before returning to the aquarium. Multiple acquisitions queue in order so each animal receives its own reveal. The aquarium keeps running behind the sequence; dismiss a fish card or jump directly to that fish's full inspector.

IDs are monotonic within the saved tank and never reused after sale/death. Offspring store both selected parents' IDs; those references persist even when parents leave the tank. We do not retain full dead/sold animal simulation objects or an unbounded animal archive. Parent identity references alone are kept for now.

Age measures **simulation time**, independent of meal-based growth. It advances ten times slower in idle mode, stops at death/sale, and advances during the bounded offline catch-up. Purchased and starter babies begin tracking at introduction; offspring begin at birth. A neutral fish has an estimated six-hour simulation lifespan. Slow metabolism and high vitality extend it; fast metabolism and low vitality shorten it. Current genetic extremes range from about 3.4 to 9.4 simulation hours. The inspector shows Young, Mature, or Senior life phase and the estimated lifespan. Fish die naturally when that age is reached, including during offline catch-up. Inbreeding penalties are not enabled yet.

Save schema 3 migrates existing schema 1 and 2 files at the same local path. Legacy fish receive unique IDs, but prior age, birth time, and ancestry are explicitly unknown rather than guessed; age thereafter is labeled as tracked time. Fish saved before newer traits were introduced receive neutral values for Vitality, Agility, and Fertility. Existing wallet, earlier traits, equivalent growth stage, and automation remain intact. The saved ID counter prevents reuse across sessions.

## Sex, breeding, and population

Fish are randomly assigned Male, Female, or Asexual, shown when selected. Well-fed adult-or-older Male/Female pairs can breed. Every 30 simulation seconds, one eligible pair has a 25% chance of producing one normal baby with a random sex. Each parent receives its own Fertility-based cooldown between three and seven simulation minutes. Asexual fish do not reproduce in this version. All five traits are inherited; color mutation remains tied to later growth rather than parent color.

Reaching 20 living fish completes the first tank population goal, which remains completed even if fish later die or are sold. The next habitat or species reward is intentionally left for the next design step. Purchases and breeding both stop at 20 without charging money; sell fish to reopen room. **Allow breeding** disables births manually. Sex, cooldowns, breeding preference, and goal completion are saved. Old saves without sex information receive random assignments. Existing fish are not killed or discarded to enforce the cap.

## Active and idle pace

The HUD shows **ACTIVE · 1×** or **AWAY · estimated at 0.1×**. Active play uses normal hunger, movement, feeding, breeding, and encounter speeds. Away time is calculated on return from a timestamped checkpoint, even if the browser suspended the tab or the game was closed.

Catch-up covers hunger, starvation, food expiry, stocked feeding, seahorse food, growth/mutation, fish age and old-age death, reward production, and snail collection. Its cap follows the purchased Away Time level, up to 2,880 one-second care steps at the final eight-hour level, without running movement or physics. Hungry fish receive available food by need. Offline snail collections are estimated from its speed, movement stamina, and sleep cycle, with the oldest rewards expiring first. These are approximations, not a replay of swimming paths. **Breeding, alien attacks, and income bubbles do not occur offline.** Time beyond the unlocked cap is discarded. Returning after 30 seconds or more shows a summary of care, earnings, growth, and losses.

## Tank Care panel

Open **Controls** above the aquarium for live hunger/stock/population warnings and an away forecast matching the current Away Time level. Before the first upgrade, the panel explains that offline simulation is locked. It shows reserve exhaustion, first starvation risk, and estimated feeding demand versus available automation. Predictions use the same offline care model without changing the tank, money, or random growth outcomes. Shop and Controls pause the aquarium while open, so aliens, hunger, movement, and other simulation clocks cannot advance while the player reads or purchases. The care forecast refreshes whenever Controls opens.

Capacity assumes current Amberfin hunger and eating thresholds, accounting for nutrition wasted by early meals. A sufficient feeding rate does not mean unlimited food: the separate reserve forecast shows when stocked supply stops. Coverage is approximate, assumes a fixed population, and excludes away breeding and alien attacks. Active swimming and competition may produce different outcomes. Premium and Deluxe improve growth, not hunger relief.

## Purchasable automation

| Purchase | One-time price | Behavior |
| --- | --- | --- |
| Snail | $50 | Crawls to settled rewards and collects them, including diamonds |
| Cleanup Shrimp | $75 | Forages for settled waste and pellets that are close to spoiling |
| Seahorse | $125 | Holds a free Basic pellet after an 18-second cooldown until a fish becomes hungry |
| Bubble Puffer | $175 | Wanders freely and may chase and pop bubbles during active play |
| Auto-feeder | $100 | Uses stocked pellets to feed the hungriest fish, at most once every 2 seconds |

The snail begins at 16 pixels per second with 10 seconds of movement stamina. Exhausting its stamina makes it retract into its shell and sleep for 20 seconds before resuming with a full reserve, so an unupgraded snail spends more time asleep than moving. Tap a sleeping snail to wake it immediately; the tap is consumed and never drops food. Speed, stamina, and sleep have separate five-level tracks. Speed progresses through 16, 30, 40, 47, and 52 pixels per second; stamina through 10, 28, 43, 53, and 60 seconds; sleep falls through 20, 11, 7, 5, and 4 seconds. Each track costs $30, $75, $190, then $475. The combined collection rate therefore jumps about fourfold when all three first upgrades are bought, with progressively smaller gains later.

The Bubble Puffer has separate Speed and Curiosity tracks. Speed progresses through 45, 60, 78, 100, and 125 pixels per second. Curiosity gives each available bubble a 30%, 45%, 60%, 80%, then 100% chance to become its chase target. Rejected bubbles remain for manual clicking. Puffer and Fish Coin Lifetime tracks cost $40, $100, $250, then $625. Existing sea-urchin purchases automatically migrate to a base-level Bubble Puffer; existing three-level snail saves map to compensating speed and stamina levels, with the new sleep track starting at level one.

The Cleanup Shrimp is a single utility pet rather than breeding livestock. It wanders along the substrate, seeks settled fish waste, and can intercept a floor pellet during its final six seconds before spoilage. Eating waste restores 0.35 cleanliness, less than the 0.75 restored by manual removal, and every meal starts a digestion pause. Speed progresses through 30, 45, 62, 82, and 108 pixels per second; digestion falls through 12, 8, 5, 3.5, and 2 seconds. Both tracks cost $20, $60, $180, then $540. It contributes normal pet biological load, so it reduces maintenance without replacing full cleaning. Away progress estimates its cleanup rate from both upgrades and reports waste eaten and pellets rescued.

No pets or machine are granted free. Each can be purchased once. Unowned helpers and equipment use the exact same procedural artwork as their discovered versions, rendered as a single solid dark silhouette with internal colors and lines hidden. Upgrade artwork is also hidden until the first level is purchased, turning the initial purchase into a small discovery; restored ownership and levels reveal the correct colors immediately. Pet positions and upgrade tracks persist in local saves. Any pet can be sold from its shop detail card for half of its purchase and upgrade investment; selling removes the pet and resets its upgrade tracks. After buying the feeder, use **Stock +20** to buy pellets at the current feed price, up to a 200-pellet reserve. Partial refills charge only for available space. Stocked pellets preserve the tier paid for, even after upgrading manual feed. Dispensing stock never charges a second time. The machine pauses when no fish are hungry or the reserve is empty; it cannot feed without stock.

The seahorse begins with an 18-second production cooldown. Once ready, it holds the free Basic pellet until at least one fish is hungry, then releases it immediately and starts the next cooldown. Production interval upgrades shorten this through 14, 11, 8, and 6 seconds for $60, $150, $375, and $940. A separate pellet track upgrades its output to Premium for $150 and Deluxe for $500. The seahorse stays awake; sleeping remains the snail's distinct behavior.

## Alien challenges

Lethal alien encounters are **on by default during active play** and remain paused during away time. Random delays are 90–150 seconds, followed by a 5-second warning at the entry point. An alien chases at 90 pixels/second and kills fish on contact, at most once per 2 seconds. Eight clicks defeat it for a base $20 diamond, twice the base value of a Diamond fish reward. Only Diamond Value multiplies either diamond. Click its left side to push it right (and vice versa); there is no stun. Taps on every visible part of the alien, including its health bar and arms, are consumed by combat and never drop food. The **Alien challenges** control still allows players to opt out; reopening the game restores the default enabled state.

Debug builds add a compact **TEST** row to the Controls panel. It can toggle the whole simulation between 1× and 10×, make fish hungry, spawn rewards, trigger an invader, and run an autoplay caretaker through the real collection, feeding, cleaning, purchase, and upgrade rules. Reset asks for confirmation before restoring a fresh $100 tank with two starter fish. The invader shortcut requires challenges enabled. Release exports hide these controls and cannot invoke the reset or autoplay paths.

## Local persistence and long sessions

Autosaves every 15 seconds and on focus loss/normal close to `user://idle_tank_v1.json`, using a temporary file and rename. Saves contain wallet, upgrades, owned automation, pellet stock, living fish and mutations, hunger, growth, coin timers, outstanding food and rewards. The tank restores automatically on launch. There is no forced restart or automatic new-fish grant for an empty saved tank.

Browser saves belong to the current browser and site origin; clearing site data can remove them. Use **Export backup** to download a JSON save and **Import backup** to restore one. Imports validate the file and ask before replacing the current tank. Import restores the recorded state without adding time-based rewards or deaths. Older saves without timestamps begin tracking offline time on their next save.

The catch-up checkpoint consumes the elapsed interval once. Repeated reloads do not award the same interval again. Fish can starve while away if automation cannot supply enough food; rewards remain in the tank unless a snail is owned. This is personal local progression, not a secure or synchronized account service.

## Web export

Install Godot 4.5.1 export templates through **Editor → Manage Export Templates**. The included Web preset uses Compatibility with threads/extensions disabled.

The wide tank-first browser layout supports desktop, tablet, and mobile landscape screens. On a phone, rotate to landscape; portrait mode shows a dedicated rotation prompt instead of shrinking the aquarium into an unusable strip. The initial habitat is a smaller fixed-size starter tank centered on every display, with one consistent enlarged presentation scale for its creatures and collectibles. Header controls remain above its border and feeding/help text stays in a dedicated footer below it. Touches work for feeding, bubbles, rewards, waste, fish inspection, combat, and all buttons; a collected or attacked target consumes the press without also dropping food. Music, effects, Tank Care, breeding, challenges, and backup actions live in the expandable **Controls** panel so the main tank remains uncluttered at smaller sizes. The PWA manifest, HTML root, loading overlay, canvas, and iOS theme metadata share the aquarium's dark background to avoid a white frame when an installed app starts or resumes.

The web export is an installable Progressive Web App. Open the HTTPS GitHub Pages build in Chrome, then choose **Install app** from the address bar or browser menu. On Android the same action may be named **Add to Home screen**. Launching the installed app uses a standalone landscape window without Chrome's address bar. The first online visit installs its offline cache; game progress still lives only in that browser/PWA's local storage, so keep a JSON backup before clearing site data.

```sh
mkdir -p build/web
godot --headless --path . --export-release Web build/web/index.html
python3 -m http.server 8000 --directory build/web
```

Visit `http://localhost:8000`. The server only serves static files; it is not a game backend. Publish the whole export folder to static hosting. Do not open exported HTML through `file://`.

## Structure

- `scenes/aquarium.tscn`: main scene.
- `scripts/aquarium.gd`: habitat, UI, purchases, selling, automation coordination, save snapshot/restore.
- `scripts/creatures/`: species profile, movement, meal progression, mutation/sale values, health, starvation, individual history (`fish_life.gd`), and inspector formatting (`fish_inspector.gd`).
- `scripts/systems/life_registry.gd`: non-reusable ID allocation and tank simulation time.
- `scripts/systems/save_migration.gd`: legacy identity migration.
- `scripts/entities/`: food, visible waste, feed profiles, collectible rewards, and income bubbles.
- `scripts/audio/aquarium_audio.gd`: original procedural effects, CC0 music crossfading, and local mute preference.
- `assets/audio/`: bundled CC0 calm and alien music with source/license records.
- `scripts/art/aquarium_vector_art.gd`: shared procedural silhouettes used by live entities and shop cards.
- `scripts/ui/`: reusable shop item definitions and illustrated card controls.
- `scripts/ui/acquisition_celebration.gd`: queued fish and pet discovery animation shared by purchases and births.
- `scripts/pets/`: independent snail, seahorse, and Bubble Puffer behaviors.
- `scripts/systems/activity_pace.gd`: shared focus-driven simulation clock.
- `scripts/systems/breeding.gd`: mating eligibility, cooldowns, and population limits.
- `scripts/systems/idle_assets.gd`: owned pets/machine, stocked pellets, and geometric pet, bubble, coin, and Away Time upgrade tracks.
- `scripts/systems/feed_upgrades.gd`: sequential paid feed upgrades.
- `scripts/systems/economy.gd`: wallet transactions.
- `scripts/systems/local_save.gd`: versioned local JSON storage.
- `scripts/systems/tank_care.gd`: read-only coverage forecasts and care warnings.
- `scripts/systems/tank_environment.gd`: cleanliness, biological load, spoilage, and waste cleanup.
- `scripts/systems/offline_progress.gd`: bounded data-only away calculation.
- `scripts/systems/save_transfer.gd`, `backup_validation.gd`: native/browser backups and import validation.
- `scripts/systems/invasion_director.gd`, `scripts/enemies/alien.gd`: optional encounters.
- `scripts/effects/`: temporary feedback text.

## Verification

The `--test` flag disables automatic save loading/writing so tests never change your tank.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script tests/prototype_test.gd -- --test
godot --headless --path . --script tests/threats_test.gd -- --test
godot --headless --path . --script tests/idle_soak.gd -- --test
godot --headless --path . --script tests/activity_test.gd -- --test
godot --headless --path . --script tests/breeding_test.gd -- --test
godot --headless --path . --script tests/lifecycle_test.gd -- --test
godot --headless --path . --script tests/offline_test.gd -- --test
godot --headless --path . --script tests/tank_care_test.gd -- --test
godot --headless --path . --script tests/bubbles_audio_test.gd -- --test
godot --headless --path . --script tests/opening_balance_test.gd -- --test
godot --headless --path . --script tests/environment_test.gd -- --test
godot --headless --path . --script tests/genetics_test.gd -- --test
godot --headless --path . --script tests/population_benchmark.gd -- --test
godot --headless --path . --script tests/autoplay_balance_test.gd -- --test
godot --headless --path . --script tests/economy_estimate.gd -- --test
godot --headless --path . --script tests/balance_monte_carlo.gd -- --test
godot --path . --script tests/render_preview.gd -- --test --idle
```

Tests cover economy/recovery, mutations and sales, automation purchases, stock, mandatory upgraded manual feed, JSON save round-trip, slow starvation, optional combat, and one hour of automated care. The autoplay balance test starts from the real $100 opening and prints a comparable checkpoint after 30 active simulation minutes. The visual test writes `/tmp/insanarium-preview.png`. Offline tests cover capped catch-up, deterministic results, starvation, growth, automation, timestamp reuse, clock rollback, and backup validation. Matching export templates are required to build the browser version.

Population measurements and their limits: [native behavior benchmark](docs/POPULATION_BENCHMARK.md).

Browser verification (September 16, 2026): the release export rendered correctly in the embedded browser; wallet changes survived reload; JSON import restored a controlled test tank; reopening after 43 seconds showed four seconds of catch-up, feeding, stock use, and snail earnings. Browser error logs were empty. Export invoked the browser download API and showed its requested status, but a completed download was not observable in this test browser.

Relaxed opening verification: deterministic attentive care reaches Teen after about 102 active seconds and Adult at 510 seconds on Basic food. Two fish consume $44 of Basic food over ten minutes. This excludes swimming delays and income; native audio tests verify playback/mute, and browser checks verify bubble rendering and mute persistence.
