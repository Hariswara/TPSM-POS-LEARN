#Used to read data files Because it is Faster and cleaner than base R functions
library(readr)


# Load the core tables
student_info       <- read_csv("data/raw/studentInfo.csv") #Rows: 32593 Columns: 12 
student_vle        <- read_csv("data/raw/studentVle.csv") #Rows: 10655280 Columns: 6 
student_assessment <- read_csv("data/raw/studentAssessment.csv") #Rows: 173912 Columns: 5  
assessments        <- read_csv("data/raw/assessments.csv") #Rows: 206 Columns: 6 
vle                <- read_csv("data/raw/vle.csv") #Rows: 6364 Columns: 6 

#column specifications each column in each file is seperated using (,) - Delimiter: ","

# First look at each table
#Shows a quick overview of the dataset including Column names, Data types (int, chr, dbl), and Sample values
glimpse(student_info)
glimpse(student_vle)
glimpse(student_assessment)
glimpse(assessments)
glimpse(vle)


#issues identified using gilmpse

  #student_assessment Table has column name score its data type is char but should be numeric
  #student_assessment Table has column name is_banked its data type is dbl but should be logical

  #assessments Table has column name date its data type is char but should be numeric

  #vle Table has column names week_from and week_to its data type is char but should be numeric

  #student_info Table has column name imd_band its data type is char but should be ordered factor
  #student_info Table has column name final_result its data type is char but should be factor


  #student_vle Table has column name date its data type is dbl and it has negative values 
  #which mean the student accessed the VLE before the course officially began. 
  #need to decide this counts in for our definition

  #All nominal categorical in student_info is in char need to decide whether they transform as factor

  #student_vle has 10.6 million rows so aggregation is mandatory before join with student_info (this has 32,593 rows)