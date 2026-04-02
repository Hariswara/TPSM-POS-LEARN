# =============================================================
# Script : 04_descriptive_analysis.R
# Purpose: Descriptive analysis of OULAD student engagement
# Author  : [Your Name]
# Phase   : 2 - Descriptive Analytics
# Depends : output from 00_data_pipeline (oulad_clean.rds)
# =============================================================

# -------------------------------------------------------------
# WHY this script exists
# -------------------------------------------------------------
# Phase 1 produced a cleaned, analysis-ready dataset with one row
# per student-module-presentation enrollment.
#
# This Phase 2 script explores that dataset descriptively before
# any inferential or predictive modelling is attempted.
#
# The goal here is NOT to prove causation.
# The goal is to:
#   1. understand the overall structure of the cleaned data,
#   2. compare engagement patterns across final result groups,
#   3. inspect the distribution of key variables,
#   4. identify skewness, spread, and outliers,
#   5. summaries directional relationships between engagement
#      and academic outcome.
#
# Flow used throughout:
#   see the data -> justify the metric -> write the code
#   -> interpret the output -> save results
# -------------------------------------------------------------

# -------------------------------------------------------------
# Load libraries
# -------------------------------------------------------------
# tidyverse : data wrangling + ggplot2 visualizations
# skimr     : quick descriptive summaries
# corrplot  : correlation heatmap visualization
# scales    : useful for formatting labels if needed
library(tidyverse)
library(skimr)
library(corrplot)
library(scales)

# -------------------------------------------------------------
# Load cleaned dataset
# -------------------------------------------------------------
# We load the RDS file instead of CSV because RDS preserves:
#   - factor types
#   - ordered factor levels
#   - transformed variables
#   - logical columns
#
# This avoids having to recreate encoding decisions from Phase 1.
df <- readRDS("data/processed/oulad_clean.rds")

# -------------------------------------------------------------
# Sanity check
# -------------------------------------------------------------
# Before analysis, always confirm:
#   - file loaded successfully
#   - expected size looks correct
#   - variable types look sensible
#
# This protects us from silently analyzing the wrong file.
cat("Rows:", nrow(df), "\nColumns:", ncol(df), "\n")
glimpse(df)

# -------------------------------------------------------------
# Create output folders
# -------------------------------------------------------------
# All descriptive outputs should be reproducible and exportable.
# These folders store:
#   - figures for the report/presentation
#   - tables for summary statistics
dir.create("outputs/figures", recursive = TRUE, showWarnings = FALSE)
dir.create("outputs/tables", recursive = TRUE, showWarnings = FALSE)

# -------------------------------------------------------------
# Consistent color palette
# -------------------------------------------------------------
# Same outcome group = same color across all charts.
# This reduces cognitive load for the reader and makes charts
# easier to compare visually.
result_colours <- c(
  "Distinction" = "#1D9E75",  # strongest outcome
  "Pass"        = "#378ADD",  # successful completion
  "Fail"        = "#EF9F27",  # unsuccessful completion
  "Withdrawn"   = "#E24B4A"   # disengaged / dropped
)

# -------------------------------------------------------------
# Shared theme for all ggplots
# -------------------------------------------------------------
# One common theme keeps all visuals report-ready and consistent.
report_theme <- theme_minimal(base_size = 12) +
  theme(
    plot.title = element_text(size = 16, face = "bold", color = "black"),
    plot.subtitle = element_text(size = 11, color = "gray30"),
    axis.title = element_text(size = 13, face = "bold", color = "black"),
    axis.text = element_text(size = 11, color = "black"),
    panel.grid.major = element_line(color = "#D9D9D9", linewidth = 0.4),
    panel.grid.minor = element_blank(),
    legend.title = element_text(size = 11, face = "bold", color = "black"),
    legend.text = element_text(size = 10, color = "black"),
    legend.position = "right",
    plot.background = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA)
  )

# =============================================================
# PART A: SUMMARY STATISTICS
# =============================================================

# -------------------------------------------------------------
# WHY summary statistics first?
# -------------------------------------------------------------
# Before plotting, we need a numerical overview.
# Summary statistics let us compare groups using:
#   - n      : group size
#   - mean   : average value
#   - median : middle value, robust to outliers
#   - SD     : variability / spread
#
# These are especially important because Phase 1 already indicated
# that engagement variables are right-skewed. That means mean alone
# is not enough - median and SD help explain shape and variability.
#
# Grouping by final_result allows us to check whether students with
# better outcomes tend to have higher engagement.
# -------------------------------------------------------------

summary_stats <- df |>
  group_by(final_result) |>
  summarise(
    # number of students in each outcome group
    n = n(),
    
    # total_clicks = overall engagement volume
    mean_clicks   = mean(total_clicks, na.rm = TRUE),
    median_clicks = median(total_clicks, na.rm = TRUE),
    sd_clicks     = sd(total_clicks, na.rm = TRUE),
    
    # active_days = engagement consistency over time
    mean_active_days   = mean(active_days, na.rm = TRUE),
    median_active_days = median(active_days, na.rm = TRUE),
    sd_active_days     = sd(active_days, na.rm = TRUE),
    
    # avg_score = weighted coursework performance
    # NAs are expected here because missing score data was
    # classified as informative in Phase 1, so we use na.rm = TRUE
    mean_score   = mean(avg_score, na.rm = TRUE),
    median_score = median(avg_score, na.rm = TRUE),
    sd_score     = sd(avg_score, na.rm = TRUE),
    
    .groups = "drop"
  )

# Print to console for direct inspection
print(summary_stats)

# Save for report writing / appendix use
write.csv(summary_stats, "outputs/tables/summary_stats.csv", row.names = FALSE)

# -------------------------------------------------------------
# EXPECTED INTERPRETATION
# -------------------------------------------------------------
# What we want to check from this table:
#   1. Do Pass / Distinction groups have higher mean engagement?
#   2. Is mean > median for clicks/days? If yes, that supports
#      right-skewness already seen in diagnostics.
#   3. Is standard deviation large? If yes, that means student
#      engagement varies substantially across individuals.
# -------------------------------------------------------------

# =============================================================
# PART B: BAR CHART OF FINAL RESULT COUNTS
# =============================================================

# -------------------------------------------------------------
# WHY this chart?
# -------------------------------------------------------------
# Before comparing engagement, we need to understand the size of
# each outcome group.
#
# A bar chart answers:
#   - How many students passed?
#   - How many failed?
#   - How many withdrew?
#   - Is any class much larger than another?
#
# Group size matters because very uneven groups can affect how
# later results are interpreted.
# -------------------------------------------------------------

p1 <- ggplot(df, aes(x = final_result, fill = final_result)) +
  geom_bar(width = 0.7) +
  scale_fill_manual(values = result_colours) +
  labs(
    title = "Number of Students by Final Result",
    subtitle = "Distribution of learners across outcome categories",
    x = "Final Result",
    y = "Count"
  ) +
  report_theme +
  theme(legend.position = "none")

# show chart in plotting window
print(p1)

# save chart for report
ggsave(
  "outputs/figures/A_result_counts.png",
  plot = p1,
  width = 8,
  height = 5,
  dpi = 200,
  bg = "white"
)

# -------------------------------------------------------------
# EXPECTED INTERPRETATION
# -------------------------------------------------------------
# This chart should reveal the overall outcome distribution.
# Example questions to answer after viewing:
#   - Is Pass the largest group?
#   - Is Withdrawn substantial?
#   - Is Distinction the smallest but strongest-performing group?
# -------------------------------------------------------------

# =============================================================
# PART C: HISTOGRAMS OF ENGAGEMENT
# =============================================================

# -------------------------------------------------------------
# WHY histograms?
# -------------------------------------------------------------
# Histograms are used to inspect distribution shape.
# They help us answer:
#   - Is the variable approximately normal?
#   - Is it strongly right-skewed?
#   - Are there extreme outliers?
#
# This matters because skewed data affects interpretation of means
# and informs whether transformed variables are more suitable for
# later inferential testing.
# -------------------------------------------------------------

# -------------------------------------------------------------
# C1. Raw total_clicks histogram
# -------------------------------------------------------------
# total_clicks is kept in original units here because descriptive
# reporting should remain interpretable in real-world values.
# We expect strong right skew: many students with low-to-moderate
# clicks, and a smaller number with extremely high engagement.
p2 <- ggplot(df, aes(x = total_clicks)) +
  geom_histogram(bins = 50, fill = "#378ADD", color = "white", linewidth = 0.2) +
  labs(
    title = "Distribution of Total Clicks (Raw)",
    subtitle = "Raw engagement distribution across all students",
    x = "Total Clicks",
    y = "Number of Students"
  ) +
  report_theme

print(p2)

ggsave(
  "outputs/figures/B_clicks_raw.png",
  plot = p2,
  width = 8,
  height = 5,
  dpi = 200,
  bg = "white"
)

# -------------------------------------------------------------
# C2. Log-transformed total_clicks histogram
# -------------------------------------------------------------
# WHY transform?
# Engagement variables are typically not normally distributed.
# A few highly active students can stretch the right tail.
#
# log1p(x) = log(x + 1)
# We use log1p instead of log because some students have zero clicks.
# log(0) is undefined, but log1p handles zeros safely.
#
# The log histogram helps us see the same variable on a compressed
# scale, reducing skewness and making the overall pattern easier
# to interpret.
p3 <- ggplot(df, aes(x = log1p(total_clicks))) +
  geom_histogram(bins = 50, fill = "#1D9E75", color = "white", linewidth = 0.2) +
  labs(
    title = "Distribution of Total Clicks (Log Scale)",
    subtitle = "Log transformation reduces skewness and makes spread easier to interpret",
    x = "log(clicks + 1)",
    y = "Number of Students"
  ) +
  report_theme

print(p3)

ggsave(
  "outputs/figures/B_clicks_log.png",
  plot = p3,
  width = 8,
  height = 5,
  dpi = 200,
  bg = "white"
)

# -------------------------------------------------------------
# EXPECTED INTERPRETATION
# -------------------------------------------------------------
# Compare raw vs log versions:
#   - Raw plot should show strong right skew.
#   - Log plot should look more balanced and compressed.
#
# If mean is much larger than median in the summary table,
# and the raw histogram has a long right tail, those two findings
# support each other.
# -------------------------------------------------------------

# =============================================================
# PART D: BOXPLOTS BY FINAL RESULT
# =============================================================

# -------------------------------------------------------------
# WHY box plots?
# -------------------------------------------------------------
# Box plots compare distributions across groups and summaries:
#   - median
#   - interquartile range
#   - overall spread
#   - outliers
#
# This is one of the most important parts of descriptive analysis
# because it directly shows whether higher engagement is associated
# with better academic outcomes.
# -------------------------------------------------------------

# -------------------------------------------------------------
# D1. log(total_clicks) by final_result
# -------------------------------------------------------------
# We use log1p(total_clicks) here because the raw click variable
# is heavily skewed. Logging gives a cleaner comparison between
# groups without changing the rank-order relationship.
p4 <- ggplot(df, aes(x = final_result, y = log1p(total_clicks), fill = final_result)) +
  geom_boxplot(alpha = 0.85, outlier.size = 0.8) +
  scale_fill_manual(values = result_colours) +
  labs(
    title = "Student Engagement (Clicks) by Final Result",
    subtitle = "Higher distributions suggest stronger engagement",
    x = "Final Result",
    y = "Total Clicks (Log Scale)"
  ) +
  report_theme +
  theme(legend.position = "none")

print(p4)

ggsave(
  "outputs/figures/C_clicks_boxplot.png",
  plot = p4,
  width = 8,
  height = 5,
  dpi = 200,
  bg = "white"
)

# -------------------------------------------------------------
# D2. active_days by final_result
# -------------------------------------------------------------
# active_days measures consistency of participation rather than
# total volume of clicking. A student may click a lot on a few days,
# but active_days captures whether they stayed engaged over time.
p5 <- ggplot(df, aes(x = final_result, y = active_days, fill = final_result)) +
  geom_boxplot(alpha = 0.85, outlier.size = 0.8) +
  scale_fill_manual(values = result_colours) +
  labs(
    title = "Active Days by Final Result",
    subtitle = "Comparison of student activity duration across outcome groups",
    x = "Final Result",
    y = "Active Days"
  ) +
  report_theme +
  theme(legend.position = "none")

print(p5)

ggsave(
  "outputs/figures/C_days_boxplot.png",
  plot = p5,
  width = 8,
  height = 5,
  dpi = 200,
  bg = "white"
)

# -------------------------------------------------------------
# EXPECTED INTERPRETATION
# -------------------------------------------------------------
# These boxplots are the clearest visual check of the main project
# statement. We want to see whether:
#   - Withdrawn students have the lowest engagement,
#   - Fail students are higher but still below successful groups,
#   - Pass students are higher,
#   - Distinction students show the strongest engagement.
#
# If that pattern appears, it supports the idea that positive
# learning experience is associated with sustained academic success.
# -------------------------------------------------------------

# =============================================================
# PART E: CORRELATION MATRIX
# =============================================================

# -------------------------------------------------------------
# WHY correlation?
# -------------------------------------------------------------
# Correlation measures how numeric variables move together.
# It does NOT prove causation, but it is useful for seeing whether
# engagement and performance indicators tend to increase together.
#
# Values close to:
#   +1  = strong positive relationship
#    0  = weak/no linear relationship
#   -1  = strong negative relationship
# -------------------------------------------------------------

# Select key numeric variables for correlation analysis.
# We drop rows with missing values because avg_score is not available
# for all students, and cor() requires complete cases.
numeric_cols <- df |>
  select(total_clicks, active_days, avg_score, n_assessments, n_resources) |>
  drop_na()

# Compute Pearson correlation matrix
cor_matrix <- cor(numeric_cols)

# Save heatmap version for reporting
png("outputs/figures/D_correlation_matrix.png", width = 900, height = 700, res = 140, bg = "white")
corrplot(
  cor_matrix,
  method = "color",
  type = "upper",
  addCoef.col = "black",
  tl.col = "black",
  tl.cex = 0.9,
  number.cex = 0.8,
  mar = c(0, 0, 2, 0),
  title = "Correlation Between Engagement Variables"
)
dev.off()

# -------------------------------------------------------------
# EXPECTED INTERPRETATION
# -------------------------------------------------------------
# We expect:
#   - strong positive correlation between total_clicks and active_days
#   - positive relationship between engagement and avg_score
#   - positive relationship between engagement and n_resources
#
# This section provides a numerical overview of how engagement
# variables relate to each other before inferential testing begins.
# -------------------------------------------------------------

# -------------------------------------------------------------
# Final confirmation
# -------------------------------------------------------------
cat("DONE — All styled outputs saved!\n")