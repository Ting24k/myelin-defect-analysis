# Baseline validation plan

The goal of the first validation is **not** to improve the algorithm. It is to confirm that repository organization does not change scientific output.

## 1. Preserve the current SCC workflow

Do not delete or overwrite the existing working SCC folder.

## 2. Initialize Git from this repository copy

Install Git LFS if it is available, then initialize the repository and make the baseline commit.

## 3. Run one known sample with the existing working SCC app

Record:

- input sample/folder
- app used
- detector model
- FP classifier model
- overlap value
- score threshold(s)
- ROI/perilesion settings
- final defect count
- output MAT/CSV/XLSX files

Keep these outputs outside Git.

## 4. Test the repository copy

Before launching the app, run `scc/check_paths.m` from MATLAB after updating the `repoRoot` variable if needed. The script reports which implementation MATLAB resolves for important functions/models.

## 5. Compare outputs

The repository baseline should reproduce the same output as the existing working folder. Any discrepancy should be investigated before path refactoring or algorithm changes.

## 6. Refactor paths in a new commit

Only after successful baseline comparison:

- remove the hard-coded Anna `/EV` dependency;
- use repository-relative paths;
- explicitly pass the classifier model path;
- make qBRM preprocessing dependencies explicit;
- rerun the same known sample and compare again.
