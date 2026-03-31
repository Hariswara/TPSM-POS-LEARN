# Understand data quality BEFORE any cleaning decisions

# helps to Clean data, Transform data, Analyze data, Visualize data
library(tidyverse)

#for quick data summaries
library(skimr)

# SECTION 1: Missing values across all tables

cat("\nNA COUNTS: student_info\n")
colSums(is.na(student_info))

cat("\nNA COUNTS: student_assessment\n")
colSums(is.na(student_assessment))

cat("\nNA COUNTS: student_vle\n")
colSums(is.na(student_vle))

cat("\nNA COUNTS: assessments\n")
colSums(is.na(assessments))

cat("\nNA COUNTS: vle\n")
colSums(is.na(vle))

# almost every file has 0 NULL values 
#which means the creators might have used some placeholders instead of proper NA values


---------------------
  
  
# SECTION 2: Investigate the score column
# score is char as identified in the previous script so we need to know EXACTLY what non-numeric values exist

cat("\nUNIQUE NON NUMERIC VALUES IN score\n")

student_assessment %>%
  filter(is.na(suppressWarnings(as.numeric(score)))) %>%
  count(score, sort = TRUE)

#output -  ?       173
#The unknown/missing scores are prefixes like ? 0.099%


# SECTION 3: Investigate date column in assessments
# date is char as identified in the previous script so we need to know EXACTLY what non-numeric values exist

cat("\nUNIQUE NON-NUMERIC VALUES IN assessments$date\n")

assessments %>%
  filter(is.na(suppressWarnings(as.numeric(date)))) %>%
  count(date, sort = TRUE)

# output - ?        11


cat("\nassessment_type distribution\n")

assessments %>% count(assessment_type, sort = TRUE)

# 1 TMA               106
# 2 CMA                76
# 3 Exam               24

# SECTION 4: Investigate final_result — what categories exist, how many?
# This is our outcome variable need to confirm what categories exists.
# since any unexpected values (typos, extra spaces) would create phantom groups.

cat("\nfinal_result categories\n")

student_info %>% count(final_result, sort = TRUE)

#identified 4 sections in final_results
# 1 Pass         12361
# 2 Withdrawn    10156
# 3 Fail          7052
# 4 Distinction   3024 if we use logistic regression accuracy alone will be misleading with this imbalance

# SECTION 5: Investigate imd_band — check all levels and NAs
# since we Need exact strings to build the ordered factor correctly (as mentioned in previous script).

cat("\n=== imd_band all levels ===\n")

student_info %>% count(imd_band, sort = FALSE)

#results
# 1 0-10%     3311
# 2 10-20     3516 This one doesn't have the % mark need to address
# 3 20-30%    3654
# 4 30-40%    3539
# 5 40-50%    3256
# 6 50-60%    3124
# 7 60-70%    2905
# 8 70-80%    2879
# 9 80-90%    2762
# 10 90-100%   2536
# 11 ?         1111 

# ? appears 1,111 times 3.4% of students, too large to drop
#IMD is a socioeconomic control variable if we dropped it it would introduce selection bias


# SECTION 6: Investigate Negative dates in student_vle
# As i mentioned earlier Negative = pre-course. We need to decide include or exclude?
# since if "Withdrawn" students never engaged pre-course,
# including pre-course data could INFLATE the engagement difference.
# We need to look at the distribution first.

cat("\n Date range in student_vle \n")

summary(student_vle$date)


#   Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
# -25.00   25.00   86.00   95.17  156.00  269.00


cat("\nPre-course interactions (date < 0): total click\n")

student_vle %>%
  filter(date < 0) %>%
  summarise(
    n_interactions = n(),
    total_clicks   = sum(sum_click),
    pct_of_all     = n() / nrow(student_vle) * 100
  )

#output - 688988      2147947       6.47


# SECTION 7: Inspect week_from / week_to in vle 
cat("\nNon-numeric values in vle week columns \n")

vle %>%
  filter(is.na(suppressWarnings(as.numeric(week_from)))) %>%
  count(week_from)

#output -  ?          5243

vle %>%
  filter(is.na(suppressWarnings(as.numeric(week_to)))) %>%
  count(week_to)
#output - ?        5243


#SECTION 8: Inspect is_banked — confirm it's truly binary before converting to binary as mentioned in previous script

cat("\n=== is_banked unique values ===\n")

student_assessment %>% count(is_banked)

# output -
#   0  -  172003
#   1  -  1909


# SECTION 9: Check for duplicate student-module-presentation combination,
# Because If the same student appears twice in student_info for the same course,
# our unit of analysis is broken. since it would cause double-counting when joining.

cat("\nDuplicate student-module-presentation rows in student_info\n")
student_info %>%
  count(id_student, code_module, code_presentation) %>%
  filter(n > 1) %>%
  nrow() %>%
  cat("Number of duplicates:", ., "\n")

#output Number of duplicates: 0 
#No duplicate student-module-presentation rows

# SECTION 10: Summary of student_info
# skim() is used since it gives us completion rate, mean, SD, histogram all at once.

cat("\nFULL SKIM: student_info\n")
skim(student_info)

#num_of_prev_attempts and studied_credits are heavily right-skewed
#num_of_prev_attempts has mean 0.163, p75 = 0, max = 6 — meaning most students are on their first attempt, 
#studied_credits has mean 79.8 but max 655 this has extreme outliers. 