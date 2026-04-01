# 01 — Descriptive Statistics

E# Phase 2 — Descriptive Analysis

## Overview
This phase performs descriptive analysis on the cleaned OULAD dataset produced in the data preparation pipeline.

The purpose of this analysis is to explore student engagement and academic performance before applying inferential or predictive methods.

This script focuses on understanding:
- Distribution of student outcomes
- Engagement behaviour (clicks and activity)
- Differences between performance groups
- Relationships between engagement variables

---

## Input Data
This script uses the cleaned dataset generated in Phase 1:

data/processed/oulad_clean.rds

The dataset contains one row per student with engineered features such as:
- total_clicks
- active_days
- avg_score
- final_result
- log-transformed variables

---

## How to Run

1. Open RStudio  
2. Set working directory to:

TPSM-POS-LEARN/oulad-analysis

3. Open and run:

04_descriptive_analysis.R

---

## Required Packages

Due to an issue with `renv::restore()` (lockfile error), packages should be installed manually:

```r
install.packages(c("tidyverse", "skimr", "corrplot", "scales"))