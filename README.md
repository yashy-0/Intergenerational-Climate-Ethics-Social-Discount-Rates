# Intergenerational Climate Ethics & Social Discount Rates

**Question:** How much is it worth, today, to prevent climate damage that will actually occur 50 or 100 years from now?

The arithmetic (Ramsey discounting) is objective. The inputs are not — they encode a philosophical position on what we owe people who haven't been born yet.

## The Model

**Ramsey Rule:** `r = ρ + η·g`  
**Present Value:** `PV = D / (1+r)^t`

Where:
- `ρ` (rho) = pure rate of time preference
- `η` (eta) = elasticity of marginal utility
- `g` = per-capita consumption growth
- `D` = total damage from one year of global emissions (~$7.1 trillion)

## Data Sources

| Source | Value | Citation |
|--------|-------|----------|
| Global CO2 emissions, 2024 | 37.4 Gt | Global Carbon Project |
| Social Cost of Carbon | $190/tonne | EPA SC-GHG Report (Nov 2023) |
| Discount parameters | Varies by economist | Nordhaus (2007), Weitzman (2007), Gollier (2013), Stern Review (2007) |

## Results

### Chart 1: Present Value Decay Over 100 Years
![Chart 1](charts/chart1_decay.png)

### Chart 2: The Valuation Gap at Milestone Years
![Chart 2](charts/chart2_milestones.png)

### Chart 3: The Full Ethical Parameter Space
![Chart 3](charts/chart3_heatmap.png)

## Key Finding

For damage occurring **100 years from now**:

| Framework | Discount Rate | Value Today |
|-----------|--------------|-------------|
| Stern Review (2007) | 1.4% | **$1.77 trillion** |
| Gollier (2013) | 4.0% | $0.14 trillion |
| Nordhaus (2007, DICE) | 5.5% | $0.03 trillion |
| Weitzman (2007) | 6.0% | **$0.02 trillion** |

**Stern values the same future damage at 84.5× what Weitzman does.**  
The gap is entirely ethical, not empirical — both frameworks agree on the physics and the emissions data. They disagree only on `ρ` and `η`.

## Discussion

*[Add your 300–500 word argument here. See below for prompts.]*

## Code

The full analysis is in [`analysis.R`](analysis.R).
