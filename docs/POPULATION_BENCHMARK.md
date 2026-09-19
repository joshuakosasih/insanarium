# Population behavior benchmark

September 15, 2026 · Godot 4.5.1 · native macOS Apple M4 · headless.

Each run used 80 stationary food candidates and 180 measured steps. Every fish was forced hungry and made to repeat its food search each step, with its vertical position reset so candidates were not consumed. Timing covers calls to fish behavior, including age tracking and draw-queue requests. It excludes actual rendering, browser overhead, aquarium UI, save I/O, pets, and invasion processing.

| Fish | Median CPU ms/step | 95th percentile ms/step |
| --- | ---: | ---: |
| 20 | 0.661 | 1.036 |
| 50 | 1.732 | 2.047 |
| 100 | 2.269 | 2.725 |
| 250 | 3.232 | 4.672 |

These are local measurements, not supported-population guarantees or browser FPS estimates. The current cap stays at 20, with breeding stopping at 16. The next performance steps before raising limits are full rendered browser/device profiling, periodically scheduled food searches, and spatial lookup if profiling justifies it.

Identity/history adds a small fixed record per living fish and at most two parent ID references; dead/sold fish do not leave full simulation objects in memory. The ID counter is retained so IDs cannot be reused. Full historical family trees are not implemented.

Reproduce from the repository root:

```sh
godot --headless --path . --script tests/population_benchmark.gd -- --test
```
