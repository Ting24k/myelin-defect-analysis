# SCC notes

Start MATLAB as you normally do on SCC. Before testing the repository copy, change MATLAB's current folder to the repository and run:

```matlab
run('scc/check_paths.m')
```

Pay particular attention to `apply_matlab_classifier`, `matlab_defect_classifier.mat`, and any duplicate functions resolved from `/projectnb/gpumcml/annanov/EV`.

The current active apps are intentionally unmodified and may still add Anna's EV directory. That dependency should be removed only in the next refactoring commit after baseline output is recorded.
