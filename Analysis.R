"Framework","DiscountRate","ValueTodayTrillions"
"Stern Review (2007)","1.4%",1.77
"Gollier (2013)","4.0%",0.14
"Nordhaus (2007, DICE)","5.5%",0.03
"Weitzman (2007)","6.0%",0.02
"Framework","rho","eta","g","r"
"Weitzman (2007)",0.02,2,0.02,0.06
"Nordhaus (2007, DICE)",0.015,2,0.02,0.055
"Gollier (2013)",0,2,0.02,0.04
"Stern Review (2007)",0.001,1,0.013,0.014
# ==============================================================================
# PROJECT: Intergenerational Climate Ethics & Social Discount Rates
# AUTHOR:  Yashy
#
# QUESTION:
#   How much is it worth, TODAY, to prevent climate damage that will occur
#   decades from now? The math (Ramsey discounting) is objective. The inputs
#   to that math are not; they encode a philosophical position on how much
#   we owe people who haven't been born yet.
#
# DATA SOURCES (all real, cited):
#   - Global CO2 emissions, 2024: 37.4 billion tonnes (fossil + industry)
#       Global Carbon Project, Global Carbon Budget 2024
#       https://globalcarbonbudget.org/fossil-fuel-co2-emissions-increase-again-in-2024/
#   - Social Cost of Carbon: $190/tonne CO2 (2020 USD), central estimate
#       US EPA, "Report on the Social Cost of Greenhouse Gases" (Nov 2023),
#       using the 2.0% near-term Ramsey discount rate
#       https://www.epa.gov/system/files/documents/2023-12/epa_scghg_2023_report_final.pdf
#   - Discount rate parameters (rho, eta, g), by economist:
#       Nordhaus (2007, DICE):  rho=1.5%, eta=2, g=2%    -> r = 5.5%
#       Weitzman (2007):        rho=2.0%, eta=2, g=2%    -> r = 6.0%
#       Gollier (2013):         rho=0.0%, eta=2, g=2%    -> r = 4.0%
#       Stern Review (2007):    rho=0.1%, eta=1, g=1.3%  -> r = 1.4%
#     (Summary table in Loisel, "The DICE Model," ENSAE Macroeconomics notes,
#      2025, citing the original papers)
#
# MODEL:
#   Ramsey Rule:  r = rho + eta * g
#   Present Value of damage D occurring t years from now:  PV = D / (1+r)^t
#
#   We treat "D" as the total damage caused by ONE YEAR of today's global
#   emissions (2024's 37.4 Gt, priced at EPA's $190/tonne SCC = ~$7.1 trillion),
#   and ask: what is that damage worth TODAY if it actually lands in year t?
# ==============================================================================

library(ggplot2)
library(dplyr)
library(tidyr)
library(scales)

dir.create("output", showWarnings = FALSE)

# ------------------------------------------------------------------------------
# 1. REAL-WORLD INPUTS
# ------------------------------------------------------------------------------

global_co2_emissions_2024_tonnes <- 37.4e9        # Global Carbon Project 2024
social_cost_of_carbon_usd_per_tonne <- 190         # EPA, Nov 2023 report

annual_global_damage_usd <- global_co2_emissions_2024_tonnes *
  social_cost_of_carbon_usd_per_tonne

cat(sprintf(
  "One year of global emissions (2024): %.1f billion tonnes CO2\n",
  global_co2_emissions_2024_tonnes / 1e9
))
cat(sprintf(
  "Priced at EPA's Social Cost of Carbon ($%d/tonne): $%.2f trillion in damage\n\n",
  social_cost_of_carbon_usd_per_tonne, annual_global_damage_usd / 1e12
))

# ------------------------------------------------------------------------------
# 2. THE FOUR ETHICAL/ECONOMIC FRAMEWORKS (real published parameters)
# ------------------------------------------------------------------------------

scenarios <- data.frame(
  Framework = c("Weitzman (2007)", "Nordhaus (2007, DICE)",
                "Gollier (2013)", "Stern Review (2007)"),
  rho = c(0.020, 0.015, 0.000, 0.001),   # pure rate of time preference
  eta = c(2.00, 2.00, 2.00, 1.00),       # elasticity of marginal utility
  g   = c(0.02, 0.02, 0.02, 0.013)       # per-capita consumption growth
) %>%
  mutate(
    r = rho + eta * g,
    Framework = factor(Framework, levels = Framework)
  )

cat("Discount rate by framework (r = rho + eta*g):\n")
print(scenarios %>% mutate(r = percent(r, accuracy = 0.1)))
cat("\n")

write.csv(scenarios, "output/scenario_parameters.csv", row.names = FALSE)

# ------------------------------------------------------------------------------
# 3. PRESENT VALUE OF ONE YEAR'S DAMAGE, IF IT LANDS t YEARS FROM NOW
# ------------------------------------------------------------------------------

years <- 0:100

time_horizon_df <- expand.grid(Year = years, Framework = scenarios$Framework) %>%
  left_join(scenarios, by = "Framework") %>%
  mutate(PresentValue = annual_global_damage_usd / ((1 + r) ^ Year))

# ------------------------------------------------------------------------------
# CHART 1: Line chart -- present value decay over 100 years, by framework
# ------------------------------------------------------------------------------

palette4 <- c("Weitzman (2007)" = "#7570B3",
              "Nordhaus (2007, DICE)" = "#D95F02",
              "Gollier (2013)" = "#66A61E",
              "Stern Review (2007)" = "#1B9E77")

p1 <- ggplot(time_horizon_df, aes(x = Year, y = PresentValue / 1e12,
                                   color = Framework, linetype = Framework)) +
  geom_line(linewidth = 1.2) +
  scale_y_continuous(labels = dollar_format(suffix = "T")) +
  scale_color_manual(values = palette4) +
  labs(
    title = "What is one year of global emissions damage worth today,\nif it actually lands t years from now?",
    subtitle = sprintf(
      "2024 global emissions (37.4 Gt CO2) priced at EPA's Social Cost of Carbon ($%d/tonne) = $%.1fT",
      social_cost_of_carbon_usd_per_tonne, annual_global_damage_usd / 1e12
    ),
    x = "Years into the future (t)",
    y = "Present value (trillions USD)",
    caption = "Ramsey Rule: r = rho + eta x g  |  Sources: Global Carbon Project 2024, EPA SC-GHG 2023 Report,\nNordhaus (2007), Weitzman (2007), Gollier (2013), Stern Review (2007)"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", legend.title = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave("output/chart1_present_value_decay.png", p1, width = 9, height = 6, dpi = 150)

# ------------------------------------------------------------------------------
# CHART 2: Bar chart -- valuation gap at milestone years
# ------------------------------------------------------------------------------

milestones <- c(25, 50, 75, 100)

milestone_df <- time_horizon_df %>%
  filter(Year %in% milestones) %>%
  mutate(YearLabel = factor(paste("Year", Year),
                             levels = paste("Year", milestones)))

p2 <- ggplot(milestone_df, aes(x = YearLabel, y = PresentValue / 1e12,
                                fill = Framework)) +
  geom_bar(stat = "identity", position = position_dodge(width = 0.75), width = 0.7) +
  scale_y_continuous(labels = dollar_format(suffix = "T")) +
  scale_fill_manual(values = palette4) +
  labs(
    title = "The valuation gap: same $7.1T damage, four ethical price tags",
    subtitle = "Higher discount rates (Weitzman, Nordhaus) write off distant damage fastest",
    x = NULL, y = "Present valuation (trillions USD)"
  ) +
  theme_minimal(base_size = 13) +
  theme(legend.position = "bottom", legend.title = element_blank(),
        plot.title = element_text(face = "bold"))

ggsave("output/chart2_milestone_comparison.png", p2, width = 9, height = 6, dpi = 150)

# ------------------------------------------------------------------------------
# CHART 3: Sensitivity heatmap -- Year-100 valuation as a function of rho & eta
# (the "dynamic parameter sweep" -- shows the full ethical parameter space,
#  not just four fixed points)
# ------------------------------------------------------------------------------

g_fixed <- 0.02
rho_seq <- seq(0, 0.03, by = 0.001)
eta_seq <- seq(0.5, 2.5, by = 0.05)

sweep_df <- expand.grid(rho = rho_seq, eta = eta_seq) %>%
  mutate(
    r = rho + eta * g_fixed,
    Year100_PV_trillions = (annual_global_damage_usd / ((1 + r) ^ 100)) / 1e12
  )

p3 <- ggplot(sweep_df, aes(x = rho * 100, y = eta, fill = Year100_PV_trillions)) +
  geom_tile() +
  geom_point(data = scenarios, aes(x = rho * 100, y = eta),
             inherit.aes = FALSE, color = "white", size = 2.5, shape = 21,
             fill = "black", stroke = 1) +
  geom_text(data = scenarios, aes(x = rho * 100, y = eta, label = Framework),
             inherit.aes = FALSE, color = "white", size = 3, vjust = -1.1,
             fontface = "bold") +
  scale_fill_viridis_c(option = "magma", labels = dollar_format(suffix = "T")) +
  labs(
    title = "The full ethical parameter space",
    subtitle = "Value today of $7.1T in damage occurring in year 100, across all (rho, eta) combinations",
    x = "Pure rate of time preference, rho (%)",
    y = "Elasticity of marginal utility, eta",
    fill = "PV ($T)"
  ) +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

ggsave("output/chart3_sensitivity_heatmap.png", p3, width = 9, height = 6.5, dpi = 150)

# ------------------------------------------------------------------------------
# 4. NUMERIC SUMMARY (for the personal statement / README)
# ------------------------------------------------------------------------------

summary_table <- time_horizon_df %>%
  filter(Year == 100) %>%
  select(Framework, r, PresentValue) %>%
  mutate(
    DiscountRate = percent(r, accuracy = 0.1),
    ValueTodayTrillions = round(PresentValue / 1e12, 2)
  ) %>%
  select(Framework, DiscountRate, ValueTodayTrillions) %>%
  arrange(desc(ValueTodayTrillions))

cat("Value TODAY of $7.1T in damage occurring 100 years from now:\n")
print(summary_table)

write.csv(summary_table, "output/year100_summary.csv", row.names = FALSE)

ratio <- summary_table$ValueTodayTrillions[summary_table$Framework == "Stern Review (2007)"] /
  summary_table$ValueTodayTrillions[summary_table$Framework == "Weitzman (2007)"]

cat(sprintf("\nStern values the SAME future damage at %.1fx what Weitzman does.\n", ratio))
cat("The gap is entirely ethical, not empirical: both frameworks agree on the physical\n")
cat("damage and the emissions data -- they disagree only on rho and eta.\n")
