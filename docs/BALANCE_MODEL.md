# Active progression estimate

Updated September 25, 2026. These figures estimate attentive human play; they are a tuning baseline rather than a promised completion time.

## Assumptions

- The player catches 80% of income bubbles and 85% of fish rewards.
- A bubble appears every four active seconds on average and has a base mean value of $1.625.
- Fish have average metabolism and resource-allocation genes.
- The player supplies Basic feed promptly at the hunger threshold and keeps the water healthy.
- Purchases are evaluated independently. Buying one item delays the others because they share the same wallet.
- Alien losses, breeding, mutations, missed meals, selling fish, and offline progress are excluded.

Under those assumptions, bubbles gross **$19.50 per active minute**. One fish creates about **1.90 collected reward events per active minute**. Basic care costs about **$2.50 per fish per active minute**. Two Teen fish at the base coin multiplier therefore net about **$18.29/minute**; five Adult fish at the 2× coin multiplier net about **$44.92/minute**.

## Biological milestones

With Basic feed and average metabolism, a fish reaches the hunger threshold about every 48 seconds. Immediate feeding gives this idealized schedule:

| Stage | Required meals | Ideal active time | Practical attentive range |
| --- | ---: | ---: | ---: |
| Teen | 2 | 1.6 min | 2–3 min |
| Adult | 10 | 8 min | 9–12 min |
| Royal | 30 | 24 min | 27–38 min |
| Diamond | 75 | 60 min | 65–90 min |

Premium and Deluxe feed shorten the growth-credit requirements but Diamond still requires 75 actual meals. The practical range allows for swimming time, different metabolism genes, and imperfect feeding.

## Time to earn a purchase price

This table measures earning from a zero wallet. A fresh tank actually begins with $100, so all entry purchases are immediately available and the first $200 coin upgrade needs only another $100, about 5.5 attentive minutes if the player buys nothing else.

| Price | Two Teens, 1× | Five Adults, 2× |
| ---: | ---: | ---: |
| $30 | 1.6 min | 0.7 min |
| $50 | 2.7 min | 1.1 min |
| $75 | 4.1 min | 1.7 min |
| $100 | 5.5 min | 2.2 min |
| $125 | 6.8 min | 2.8 min |
| $150 | 8.2 min | 3.3 min |
| $200 | 10.9 min | 4.5 min |
| $500 | 27.3 min | 11.1 min |
| $800 | 43.7 min | 17.8 min |
| $3,200 | 2.9 hr | 1.2 hr |
| $12,800 | 11.7 hr | 4.7 hr |

## Coin Value payback

Coin Value affects every fish forever, so its price must be judged by payback rather than only by time to afford it. The revised prices are $200, $800, $3,200, and $12,800 for multipliers 1× → 2× → 3× → 5× → 8×.

| Upgrade | Added multiplier | Two Teens payback | Five Adults payback |
| --- | ---: | ---: | ---: |
| 1× → 2× | +1× | 52.7 min | 10.5 min |
| 2× → 3× | +1× | 3.5 hr | 42.2 min |
| 3× → 5× | +2× | 7.0 hr | 1.4 hr |
| 5× → 8× | +3× | 18.8 hr | 3.8 hr |

This curve makes the first level a deliberate early goal and pushes later levels into established-tank progression. More fish and Royal output shorten these paybacks, while missed coins lengthen them. Diamond output uses its own independent upgrade and is excluded from Coin Value payback.

Run the calculation from the repository root with:

```sh
godot --headless --path . --script tests/economy_estimate.gd -- --test
```
