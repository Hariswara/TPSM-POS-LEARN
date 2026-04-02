# Clean and engineer the analytical dataset

library(tidyverse)

# STEP 1: Fix imd_band inconsistency
# WHY: Diagnostic showed "10-20" missing the "%" that all other bands have.
# If we don't fix this string FIRST, our ordered factor will have 11 levels
# instead of 10 — "10-20" and "10-20%" would be treated as different groups.

# The "?" rows become NA since too many to drop; they stay in
# the dataset but won't influence tests that use imd_band directly.

student_info_clean <- student_info %>%
  mutate(
    imd_band = case_when(
      imd_band == "10-20" ~ "10-20%", 
      imd_band == "?"     ~ NA_character_,
      TRUE                ~ imd_band
    )
  )

# Verify
cat("imd_band levels after fix:\n")
table(student_info_clean$imd_band, useNA = "always")

# STEP 2: Encode all character columns to correct factor types

# NOMINAL factors like gender, region, disability, code_module, code_presentation
# plain factor() is correct since ordering would imply a ranking that doesn't exist

# ORDERED factors like,
#   imd_band: 0-10% = most deprived, 90-100% = least deprived,
#   age_band: 0-35 < 35-55 < 55+,
#   highest_education: No Formal, Lower Than A Level, A Level, HE, Post Graduate

# final_result: not really ordinal for every test, but we can treat it as
# Withdrawn < Fail < Pass < Distinction
# because it shows the progression of student performance
# so might be able used it in the descriptive analysis

student_info_clean <- student_info_clean %>%
  mutate(
    # Nominal factors
    gender             = factor(gender),
    region             = factor(region),
    disability         = factor(disability),
    code_module        = factor(code_module),
    code_presentation  = factor(code_presentation),
    
    # Ordered: IMD band 
    imd_band = factor(imd_band,
                      levels  = c("0-10%","10-20%","20-30%","30-40%","40-50%",
                                  "50-60%","60-70%","70-80%","80-90%","90-100%"),
                      ordered = TRUE),
    
    # Ordered: age band
    age_band = factor(age_band,
                      levels  = c("0-35", "35-55", "55<="),
                      ordered = TRUE),
    
    # Ordered: highest education level
    highest_education = factor(highest_education,
                               levels  = c(
                                 "No Formal quals",
                                 "Lower Than A Level",
                                 "A Level or Equivalent",
                                 "HE Qualification",
                                 "Post Graduate Qualification"),
                               ordered = TRUE),
    
    # Nominal factor for result — 4 groups for ANOVA
    final_result = factor(final_result,
                          levels = c("Withdrawn", "Fail", "Pass", "Distinction")),
    
    # Need Binary outcome for logistic regression
    # Pass + Distinction = course completed successfully
    # Fail + Withdrawn = course not completed successfully
    # This makes sense for our analysis question and keeps the outcome defensible
    passed = if_else(final_result %in% c("Pass", "Distinction"), 1L, 0L),
    
  )

# Check factor levels are correct
cat("\nfinal_result levels:\n")
levels(student_info_clean$final_result)

cat("\nimd_band levels:\n")
levels(student_info_clean$imd_band)

cat("\nage_band distribution:\n")
table(student_info_clean$age_band)

cat("\npassed distribution:\n")
table(student_info_clean$passed)

cat("\nhighest_education distribution:\n")
table(student_info_clean$highest_education)

# STEP 3: Fix score column in student_assessment

# as i mentioned in second script "?" means the score was not recorded (0.099% of rows).
# I am going to NA-encode rather than impute because:

#   (a) 173 rows out of 173,912 is negligible
#   (b) we do not know WHY the score is missing imputing might introduce some way of bias

# We also convert is_banked to logical.
# so R treats it as TRUE/FALSE instead of a continuous variable
# This helps to prevent accidental averaging or misuse in models

student_assessment_clean <- student_assessment %>%
  mutate(
    score_num  = suppressWarnings(as.numeric(score)), 
    score_flag = (score == "?"),              
    is_banked  = as.logical(is_banked)
  )

cat("\nScore conversion check\n")
sum(is.na(student_assessment_clean$score_num))
# Should be 173 because we identified that 173 "?" in student_assessment in second script
#and now those "?" became NA

cat("\nBanked assessment count:\n")
sum(student_assessment_clean$is_banked)
# Output - 1909 


# STEP 4: Fix assessments metadata

cat("\nAssesment types and counts where daste is ?:\n")
assessments %>%
  filter(date == "?") %>%
  count(assessment_type)

# "?" in date column = exam with no fixed date.
# These are all Exam type, confirmed by the above diagnostic outputing only Exam    11.

# We NA-encode the date and convert assessment_type to factor.

# We will EXCLUDE Exams from our weighted score calculation because:
#   (a) Exams have no fixed date so timing data is unreliable and so the sustained part cannot explain
#   (b) Our engagement construct is about learning during the course (TMA/CMA),
#       not final performance at one point in time.
#   (c) Exam type only has 24 records and from it 11 doesn't have date records

assessments_clean <- assessments %>%
  mutate(
    date            = suppressWarnings(as.numeric(date)), # convert "? to NA
    assessment_type = factor(assessment_type,
                             levels = c("TMA", "CMA", "Exam"))
  )

cat("\nAssessment type counts:\n")
table(assessments_clean$assessment_type)

cat("\nDate NAs \n")
sum(is.na(assessments_clean$date))

# STEP 5: Aggregate student_vle to student level
# WHY we filter out date >= 0:
#   Pre-course clicks (date < 0) represent orientation period not the learning engagement.
#   Our construct "positive learning experience" refers to engagement DURING
#   the course. Keeping pre course data would conflate orientation behaviour
#   with learning behaviour.

# WHY we generate these three metrics:
#   total_clicks: volume of engagement (how much)
#   active_days:  consistency of engagement (how regularly — distinct days)
#   n_resources:  breadth of engagement (how many different resources)
#   These three together capture different dimensions of learning behaviour.

vle_agg <- student_vle %>%
  filter(date >= 0) %>%                          # exclude pre-course
  group_by(id_student, code_module, code_presentation) %>%
  summarise(
    total_clicks = sum(sum_click),               # total volume of interaction
    active_days  = n_distinct(date),             # number of distinct active days
    n_resources  = n_distinct(id_site),          # number of distinct resources used
    .groups = "drop"
  )

cat("\nvle_agg dimensions:\n")
dim(vle_agg)
#Output [1] 28500     6

head(vle_agg)

cat("\nEngagement summary:\n")
summary(vle_agg[, c("total_clicks", "active_days", "n_resources")])


# STEP 6: Compute weighted assessment scores (for TMA + CMA only)

# WHY exclude Exam: as explained in Step 4.

# We choose weighted mean because assessments have different weights (e.g. TMA worth 20%
# vs another worth 40%). A simple mean would treat all equally, which is statistically incorrect 

# Ex: a high score on a 5% weighted assessment should contribute 
#less than a high score on a 40% weighted assessment.

# We drop is_banked rows because banked assessments are from a PREVIOUS attempt
# carried forward they do not reflect this module's learning engagement.

score_agg <- student_assessment_clean %>%
  filter(!is_banked) %>%                         # exclude carried-over scores
  filter(!is.na(score_num)) %>%                  # drop the 173 "?" rows
  inner_join(
    assessments_clean %>%
      filter(assessment_type != "Exam") %>%      # TMA and CMA only
      select(id_assessment, weight),
    by = "id_assessment"
  ) %>%
  group_by(id_student) %>%
  summarise(
    avg_score        = weighted.mean(score_num, weight, na.rm = TRUE),
    n_assessments    = n(),
    .groups = "drop"
  )

cat("\nscore_agg dimensions:\n")
dim(score_agg)

#Output 23285     3

cat("\nAverage score summary:\n")
summary(score_agg$avg_score)

# STEP 7: Join all tables into the master analytical dataset

# We use left join from student_info because,
#   student_info is our main file since it defines our population.
#   LEFT JOIN preserves ALL students, including those with no VLE activity
#   (they get NA from vle_agg, which we immediately replace with 0).

# WHY We replace NA engagement with 0 without dropping it
#   A student with NA total_clicks didn't have a missing value they had ZERO
#   interactions. Dropping them would remove an important group: non-engagers.


analytical_df <- student_info_clean %>%
  left_join(vle_agg,   by = c("id_student", "code_module", "code_presentation")) %>%
  left_join(score_agg, by = "id_student") %>%
  
  # Replace NA engagement with 0 — students with no VLE record had zero activity
  mutate(
    total_clicks = replace_na(total_clicks, 0),
    active_days  = replace_na(active_days,  0),
    n_resources  = replace_na(n_resources,  0)
    # avg_score stays NA for students with no assessments didn't change it
  )

cat("\n MASTER DATASET DIMENSIONS \n")

dim(analytical_df)
#Output - 32593    18

head(analytical_df)


cat("\n NA SUMMARY OF MASTER DATASET \n")
colSums(is.na(analytical_df))

cat("\n DATA TYPES CHECK \n")
glimpse(analytical_df)

# FIX 1: Re-encode factors lost in join (found out after glimpse(analytical_df))
analytical_df <- analytical_df %>%
  mutate(
    code_module       = factor(code_module),
    code_presentation = factor(code_presentation)
  )

#Verify the fix

cat("code_module class:", class(analytical_df$code_module), "\n")
cat("code_presentation class:", class(analytical_df$code_presentation), "\n")
cat("code_module levels:", levels(analytical_df$code_module), "\n")
cat("code_presentation levels:", levels(analytical_df$code_presentation), "\n")

cat("\n ENGAGEMENT ZEROS: students with no VLE activity \n")
analytical_df %>%
  summarise(
    zero_click_students = sum(total_clicks == 0),
    pct_zero            = mean(total_clicks == 0) * 100
  )


# PRE-STEP-8 DIAGNOSTIC: Understand NA patterns in avg_score

# We need to know if NAs are informative (not random) before any analysis.

cat("avg_score NA breakdown by final_result\n")
analytical_df %>%
  group_by(final_result) %>%
  summarise(
    total_students    = n(),
    missing_score     = sum(is.na(avg_score)),
    pct_missing       = round(mean(is.na(avg_score)) * 100, 1),
    zero_clicks       = sum(total_clicks == 0),
    pct_zero_clicks   = round(mean(total_clicks == 0) * 100, 1)
  )
#Based on the output The probability of having a missing score is directly related to the outcome itself. 
#Withdrawn students are nearly 6× more likely to have no score than Pass students. 


cat("\navg_score vs n_assessments NA mismatch\n")
analytical_df %>%
  summarise(
    both_na          = sum(is.na(avg_score) & is.na(n_assessments)),
    score_na_only    = sum(is.na(avg_score) & !is.na(n_assessments)),
    assess_na_only   = sum(!is.na(avg_score) & is.na(n_assessments))
  )

# both_na = 5,933 means these students have neither a score nor an assessment count — they submitted nothing at all.
# 
# score_na_only = 2,296 means these students have an n_assessments value but still no avg_score. 
# This is the mismatch I flagged. The reason might be these students submitted assessments that were all 
# either banked (carried from prior attempt) or had "?" scores, 
# so after our filters they have zero valid scores to average. 
# They show up in n_assessments because the raw join found records, but avg_score came back NA after the weighted mean on an empty set.
# 
# assess_na_only = 0 No student has a score without an assessment count.


# FIX 2: Apply log transformation to engagement variables

# Reason for using log1p:
# total_clicks contains many zero values (around 4,093 students),
# and using log(0) would give -Inf, which causes errors in analysis

# log1p(x) = log(x + 1), so it safely handles zeros while still reducing
# the effect of very large values (right-skewed data)

# We keep the original variables as well:
# - log-transformed values are used for statistical tests since they more stable
# - original values are used for reporting (e.g., mean, median in real terms).

analytical_df <- analytical_df %>%
  mutate(
    log_clicks    = log1p(total_clicks),
    log_days      = log1p(active_days),
    log_resources = log1p(n_resources)
  )

cat("\nLog-transformed summary:\n")
summary(analytical_df[, c("log_clicks","log_days","log_resources")])

# FIX 3: Add MNAR (Missing Not At Random) flag for avg_score

# Reason:
# avg_score is MNAR — the fact that it is missing actually carries information.
# We make a flag variable so we can:
#   (a) use it as a predictor in logistic regression if needed
#   (b) always track which rows are complete vs incomplete

# We also add a separate flag for 2,296 students who had assessments
# recorded but all were banked/invalid — this is a different case
# from students who didn’t submit anything at all

analytical_df <- analytical_df %>%
  mutate(
    has_score_data    = !is.na(avg_score),
    no_submission     = is.na(avg_score) & is.na(n_assessments),  # submitted nothing
    banked_only       = is.na(avg_score) & !is.na(n_assessments)  # had records but all filtered
  )

print(analytical_df, width = Inf)

cat("\nSubmission status by final_result\n")
analytical_df %>%
  group_by(final_result) %>%
  summarise(
    n                 = n(),
    has_score         = sum(has_score_data),
    no_submission     = sum(no_submission),
    banked_only       = sum(banked_only)
  )

# Observation:
# - Withdrawn students mostly did not submit or had few valid scores
# - Pass/Distinction students almost all have valid scores

# SAFE AUDIT BEFORE FINAL DATA SAVE

cat("\nFINAL COLUMN TYPES\n")
type_df <- data.frame(
  column = names(analytical_df),
  type   = sapply(analytical_df, function(x) class(x)[1]),
  row.names = NULL
)
print(type_df)

#I Confirmed that all data types are in order

cat("\nFINAL NA COUNTS (only columns with NAs)\n")
na_counts <- colSums(is.na(analytical_df))
print(na_counts[na_counts > 0])

#Output
# imd_band     avg_score n_assessments 
# 1111          8229          5933


cat("\n FINAL DIMENSIONS ===\n")
print(dim(analytical_df))

#Output
#32593    24

# SAVE BOTH FORMATS

# CSV: human-readable, shareable, importable anywhere
# RDS: preserves factor levels and ordering exactly
#      loading the CSV later would lose all encoding and we'd redo it

write_csv(analytical_df, "data/processed/analytical_dataset.csv")
saveRDS(analytical_df,   "data/processed/analytical_dataset.rds")




