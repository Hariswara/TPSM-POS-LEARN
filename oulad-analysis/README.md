# OULAD Data Science Analysis

This repository contains the data science pipeline and analysis for the Open University Learning Analytics Dataset (OULAD). It is structured to support a reproducible, bilingual (R and Python) workflow, drawing inspiration from established project structures like Cookiecutter Data Science.

## Repository Structure

The project is organized into the following directories to separate concerns, ensure reproducibility, and keep the workflow organized for collaborators.

```text
oulad-analysis/
│
├── data/
│   ├── raw/                  ← Original, immutable OULAD CSVs. Never modify these.
│   ├── processed/            ← Cleaned, merged, and transformed data files (generated).
│   └── features/             ← Engineered feature tables ready for modeling (generated).
│
├── notebooks/                ← Jupyter or R Markdown notebooks, prefixed by execution order.
│   ├── 00_data_pipeline/     ← Data loading, cleaning, and merging scripts (R or Python).
│   ├── 01_descriptive/       ← Exploratory Data Analysis (EDA), distributions, summaries (R).
│   ├── 02_inferential/       ← Hypothesis tests, ANOVA, chi-square, etc. (R).
│   ├── 03_predictive/        ← Machine learning models, regression, time series (Python).
│   └── 04_scratch/           ← Personal sandboxes for ad-hoc exploration (not reviewed).
│
├── src/                      ← Reusable source code and helper modules.
│   ├── r/                    ← Shared R helper functions used across notebooks/scripts.
│   └── python/               ← Shared Python modules/classes.
│
├── outputs/                  ← Final generated artifacts.
│   ├── figures/              ← Saved plots and visualizations (generated).
│   ├── tables/               ← Exported result tables (generated).
│   └── models/               ← Serialized, saved model objects (generated).
│
├── report/                   ← Source files for final written reports or presentations.
├── docs/                     ← Team documentation, design decisions, and meeting notes.
│
├── .gitattributes            ← Git LFS tracking rules (auto-generated, do not edit manually).
├── .gitignore                ← Specifies intentionally untracked files to ignore.
├── oulad-analysis.Rproj      ← RStudio Project file to set working directory natively.
├── README.md                 ← The top-level README for developers/collaborators.
├── requirements.txt          ← Python dependencies file.
└── renv.lock                 ← R dependencies lockfile (renv).
```

## Directory Details

### `data/`
- **`raw/`**: The ground truth dataset. This folder must contain the original provided CSVs. Treat these files as read-only.
- **`processed/`**: Intermediate datasets that have been cleaned and prepared by the pipeline scripts.
- **`features/`**: The final formulated tables that are fed directly into statistical analysis and machine learning models.

### `notebooks/`
Notebooks are numbered sequentially (`00_` to `03_`) to clearly indicate the order of operations. Anyone picking up the project should run them in this order.
- **`04_scratch/`**: Use this for messy, experimental work. Notebooks here are not expected to run cleanly or be reviewed.

### `src/`
Any code that is used in multiple notebooks or scripts should be extracted into functions/classes and stored here based on the language. This keeps notebooks clean and analytical.

### `outputs/`
This folder is for generated assets. Everything in here should be deterministically reproducible from the `data/` and the code in `notebooks/` or `src/`. Large files in this folder are tracked via **Git LFS** (see below).

### Dependencies
This project uses two separate package management systems due to the bilingual nature of the analysis:
- **Python**: Use `pip install -r requirements.txt` to install the required Python packages. Maintain this file when adding new Python libraries.
- **R**: Uses `renv` for reproducible environments. The `renv.lock` tracks the exact package versions used.

### RStudio Integration
This repository is fully compatible with RStudio as an "R Project".
1. **Working Directory & Paths**: Double-click `oulad-analysis.Rproj` to open the project in RStudio. This automatically sets R's working directory to the project root, meaning you can load data securely using relative paths (e.g., `read.csv("data/raw/data.csv")`).
2. **Environment Management**: Opening the `.Rproj` file will trigger `renv` to restore the precise package versions specified in `renv.lock`.
3. **Seamless Development**: You can create and knit `.Rmd` files directly in `notebooks/` and seamlessly `source("src/r/...")` helper functions.

### Git LFS (Large File Storage)
This project uses **Git LFS** to handle large files. Instead of storing full data files directly in Git history, LFS replaces them with lightweight pointer files while the actual content is stored on the LFS server.

**First-time setup** (required once per machine):
```bash
git lfs install
```

**Tracked file types:**
| Category | Extensions |
|----------|------------|
| Data | `.csv`, `.xlsx`, `.xls`, `.parquet`, `.feather` |
| Models | `.pkl`, `.rds`, `.h5`, `.hdf5` |
| Images | `.png`, `.jpg`, `.jpeg`, `.svg` |
| Documents | `.pdf` |

All files inside `data/` and `outputs/` are also tracked by LFS regardless of extension.

> **Note:** After cloning, run `git lfs pull` if large files appear as pointer files instead of actual content.
