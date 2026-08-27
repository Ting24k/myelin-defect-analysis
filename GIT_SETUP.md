# Git Setup and Workflow Guide

This guide is for the `myelin-defect-analysis` MATLAB repository running on SCC and hosted on GitHub.

## 1. Core idea

Use:
- `main` for trusted, validated code.
- feature branches for changes and experiments.
- separate specialized apps only when the workflow is genuinely different.
- commits for checkpoints.
- tags for important scientific milestones.

## 2. Commit messages

A good commit message answers: **What changed?**

Recommended form:

```text
<Action> <specific change>
```

Good examples:

```text
Add saved ROI loading to perilesion app
Fix classifier model path on SCC
Update ROI filtering for perilesion analysis
Remove dependency on Anna EV directory
Add manual missed-defect annotation
Integrate retrained FP classifier
Fix annotation loader for ROI-filtered MAT files
Document YOLOv4 detector metadata
```

Avoid vague messages:

```text
update
fix stuff
new version
final
test
working
```

For a small change, one line is enough:

```bash
git commit -m "Fix ROI-filtered annotation loading"
```

For an important scientific change, use a title plus a short body:

```text
Add saved ROI loading to perilesion app

- Load ROI coordinates from defect_struct.ROI
- Reuse existing polygon instead of manual redrawing
- Preserve manual ROI workflow
- Tested with SM087 S2E4 sample
```

For model updates, document extra details in `docs/models.md`.

## 3. Can a pushed commit be changed?

Yes, but use different approaches depending on where it was pushed.

### Shared or main branch

Do not rewrite history. Make a new corrective commit:

```bash
git add .
git commit -m "Fix ROI loading introduced in previous commit"
git push
```

If you need to undo a shared commit:

```bash
git revert <commit-id>
git push
```

This is the safest method because it preserves history.

### Personal feature branch

You can modify the latest commit:

```bash
git add .
git commit --amend
```

If that commit was already pushed:

```bash
git push --force-with-lease
```

Use `--force-with-lease`, not plain `--force`.

Recommended rule:
- feature branch: amend if needed
- `main`: preserve history; fix with a new commit or `git revert`

## 4. Normal feature workflow

A workflow:
```
create branch
→ modify app
→ save app
→ test app
→ if it works, commit
→ push branch
→ merge into main
```

Start from `main`:

```bash
git switch main
git pull
```

Create a branch:

```bash
git switch -c feature/load-saved-roi
```
Directly modify in matlab, save it, test it:
```
app/Deep_learning_app_v2_filterFP_perilesion.mlapp
```
Make changes and inspect them:

```bash
git status
git diff
```

Stage and commit:

```bash
# putting the file into a "save these changes" basket.
git add app/Deep_learning_app_v2_filterFP_perilesion.mlapp
# Create a permanent Git checkpoint containing the staged changes 
git commit -m "Add saved ROI loading to perilesion app"
```

Push, after push, GIthub has a copy:

```bash
git push -u origin feature/load-saved-roi
```

After validation:

```bash
git switch main  #go back to main branch
git pull   # bring newer changes from github to scc
git merge feature/load-saved-roi
git push    # upload updated main branch to github
```

Optional cleanup:

```bash
git branch -d feature/load-saved-roi
git push origin --delete feature/load-saved-roi
```
Rule:
```
One feature branch = one specific task

task finished + merged
→ stop using that branch

new task
→ create a new branch from main
```

## 5. When to modify the original app vs keep a separate app

### Same workflow + one new capability

Example:

```text
Detect defects
→ draw ROI OR load saved ROI
→ classify FP
→ count defects
```

This should usually become a feature of the existing app.

Workflow:
1. create feature branch
2. modify app
3. test
4. merge into `main`

### Genuinely different workflow

Example:

```text
General app:
whole-lesion analysis

Perilesion app:
perilesion-specific ROI logic
different measurements or output calculations
```

In this case, keeping two apps is reasonable:

```text
app/
├── Deep_learning_app_v2_filterFP.mlapp
└── Deep_learning_app_v2_filterFP_perilesion.mlapp
```

Develop the specialized app on a branch:

```bash
git switch main
git switch -c feature/perilesion-app
```

After validation, merge it into `main`.

Important: **merging does not mean replacing the original app.**

After merge, `main` can contain both:

```text
main
├── general app
└── perilesion app
```

A branch is mainly a safe development workspace, not necessarily a permanent version.

### If the two apps later differ only by a few settings

You may eventually combine them into one app with a mode selector:

```text
Analysis mode:
- General
- Existing ROI
- Perilesion
```

Do this only after both workflows are stable and well understood.

## 6. Recommended branch names

Features:

```text
feature/load-saved-roi
feature/perilesion-analysis
feature/missed-defect-annotation
feature/retrain-detector
feature/retrain-fp-classifier
```

Bug fixes:

```text
fix/roi-loading
fix/classifier-path
fix/annotation-gtruth-loader
```

Experiments:

```text
experiment/new-roi-definition
experiment/resnet50-classifier
```

Documentation:

```text
docs/update-model-documentation
```

Avoid names such as:

```text
branch1
test
new
final
version2
```

## 7. Inspect branches

List branches:

```bash
git branch
```

List local and remote branches:

```bash
git branch -a
```

Current branch:

```bash
git branch --show-current
```

Switch:

```bash
git switch main
```

Create and switch:

```bash
git switch -c feature/new-feature
```

## 8. Inspect changes before committing

Check status:

```bash
git status
```

See unstaged changes:

```bash
git diff
```

See staged changes:

```bash
git diff --staged
```

For `.m` files, Git shows line-level changes well.

`.mlapp` files are binary, so Git can version them but does not show useful line-by-line diffs. For that reason, move important analysis logic into normal `.m` functions under `src/` when practical.

## 9. Undo changes safely

Undo one uncommitted file:

```bash
git restore path/to/file.m
```

Unstage while keeping edits:

```bash
git restore --staged path/to/file.m
```

Undo a shared commit:

```bash
git revert <commit-id>
git push
```

Be cautious with:

```bash
git reset --hard
```

because it can permanently discard uncommitted work.

## 10. Pull Requests

Push a branch:

```bash
git push -u origin feature/load-saved-roi
```

On GitHub, open a Pull Request:

```text
feature/load-saved-roi → main
```

Useful PR description:

```text
Purpose:
Allow previously saved lesion ROIs to be reused.

Changes:
- Load defect_struct.ROI from defects_data MAT files
- Recreate polygon from saved coordinates
- Preserve manual ROI drawing option

Validation:
Compared old and new workflows using the same SM087 S2E4 ROI.
```

Even for a one-person research project, PRs are useful documentation.

## 11. Tags

Use tags for stable scientific milestones.

Create:

```bash
git tag -a baseline-v1 -m "Validated self-contained SCC baseline"
```

Push:

```bash
git push origin baseline-v1
```

List:

```bash
git tag
```

Show:

```bash
git show baseline-v1
```

Useful examples:

```text
baseline-v1
perilesion-v1
fp-classifier-v2
manuscript-analysis-v1
```

For manuscript work:

```bash
git tag -a manuscript-analysis-v1 -m "Code and models used for manuscript defect analysis"
git push origin manuscript-analysis-v1
```

## 12. Model workflow

For retraining:

```bash
git switch main
git pull
git switch -c feature/retrain-fp-classifier
```

Train and validate the model.

Document in `docs/models.md`:
- training date
- training samples
- architecture
- input size
- validation metric
- reason for replacement

Commit:

```text
Update FP classifier with reviewed perilesion samples
```

Merge only after validation.

Optionally tag:

```text
fp-classifier-v2
```

Do not use long-lived branches as model-version storage.

## 13. Before every commit

Run:

```bash
git status
git diff
```

Check:
- no TIFF data was added accidentally
- no generated results were added
- no `.DS_Store`
- only related files are included
- commit message explains the change

Then:

```bash
git add <files>
git diff --staged
git commit
```

## 14. Before merging into main

For analysis changes verify:
- app opens
- `scc/check_paths.m` passes
- detector loads
- classifier loads
- test sample completes
- important counts/results match the expected baseline
- no hidden dependency on another SCC user's directory remains

Then merge.

## 15. Useful commands

History:

```bash
git log --oneline --graph --decorate --all
```

Status:

```bash
git status
```

Changes:

```bash
git diff
git diff --staged
```

Pull latest main:

```bash
git switch main
git pull
```

Create feature branch:

```bash
git switch -c feature/my-feature
```

Commit:

```bash
git add .
git commit -m "Add my feature"
```

First push:

```bash
git push -u origin feature/my-feature
```

Merge:

```bash
git switch main
git pull
git merge feature/my-feature
git push
```

Tag:

```bash
git tag -a tag-name -m "Description"
git push origin tag-name
```

## 16. Practical decision guide

```text
Small fix or new capability in existing workflow?
        ↓
Create branch
Modify existing app/function
Test
Merge into main

Genuinely different analysis workflow?
        ↓
Create branch
Create/maintain specialized app
Test
Merge branch into main
Keep BOTH apps in main

Temporary experimental code?
        ↓
Keep on experiment branch
Do not merge until validated
```

The key idea is:

> `main` is your trusted protocol, a branch is your experiment, a commit is a checkpoint, and a tag freezes an exact scientific version.
