# College to Pro: 2025 Eligible Player Analysis

library(readxl)
library(ggplot2)
# Import data
players <- read_excel(
  "Data/eligible_players_2025.xlsx",
  sheet = "Eligible_Players_2026"
)
# Create a dataset with resolved pro outcomes only
resolved_players <- players[
  players$`Signed Pro?` %in% c("Yes", "No"),
]
# Create clean variables for modeling

resolved_players$Pro_Status <- ifelse(
  resolved_players$`Signed Pro?` == "Yes", 1, 0
)

resolved_players$Draft_Status <- ifelse(
  resolved_players$`Drafted?` == "Yes",
  "Drafted",
  "Not Drafted"
)

resolved_players$Academy_Status <- ifelse(
  is.na(resolved_players$`MLS NEXT Academy`),
  "No MLS Academy",
  "MLS Academy"
)

resolved_players$Position_Clean <- ifelse(
  resolved_players$Position == "CM",
  "M",
  resolved_players$Position
)
# Chi-square test: MLS Academy background and turning pro

academy_table <- table(
  resolved_players$Academy_Status,
  resolved_players$Pro_Status
)

chisq.test(academy_table)
# Logistic regression: factors associated with turning pro

pro_model <- glm(
  Pro_Status ~ Draft_Status + Academy_Status + Position_Clean,
  data = resolved_players,
  family = binomial
)
# Create a clean regression results table
model_results <- data.frame(
  Variable = names(coef(pro_model)),
  Odds_Ratio = exp(coef(pro_model)),
  P_Value = summary(pro_model)$coefficients[, 4]
)
# Make results easier to read
model_results$Variable <- c(
  "Intercept",
  "Not Drafted",
  "No MLS Academy",
  "Forward",
  "Goalkeeper",
  "Midfielder"
)

model_results$Odds_Ratio <- round(model_results$Odds_Ratio, 2)
model_results$P_Value <- signif(model_results$P_Value, 3)
# Visualize logistic regression results
plot_results <- model_results[model_results$Variable != "Intercept", ]
# Add significance labels
plot_results$Significance <- ifelse(
  plot_results$P_Value < 0.05,
  "Statistically Significant",
  "Not Statistically Significant"
)
# Add 95% confidence intervals
conf_int <- exp(confint(pro_model))

plot_results$Lower_CI <- conf_int[-1, 1]
plot_results$Upper_CI <- conf_int[-1, 2]
# Final odds ratio plot with 95% confidence intervals
ggplot(plot_results,
       aes(x = reorder(Variable, Odds_Ratio),
           y = Odds_Ratio,
           color = Significance)) +
  geom_hline(yintercept = 1, linetype = "dashed") +
  geom_errorbar(
    aes(ymin = Lower_CI, ymax = Upper_CI),
    width = 0.15
  ) +
  geom_point(size = 4) +
  coord_flip() +
  labs(
    title = "Which Factors Were Associated with Turning Pro?",
    subtitle = "Odds ratios with 95% CI | Reference: Drafted, MLS Academy, Defender",
    x = NULL,
    y = "Odds Ratio",
    color = NULL
  ) +
  theme_minimal()

# Save final regression figure
ggsave(
  "Figures/logistic_regression_forest_plot.png",
  width = 10,
  height = 6,
  dpi = 300
)