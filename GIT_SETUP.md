# First Git setup

From the repository directory:

```bash
git init
git lfs install
git add .gitattributes .gitignore
git add .
git status
git commit -m "Initial import of working SCC defect-analysis pipeline"
```

Before pushing, inspect `git status` and confirm that raw microscopy data/results are not staged.

Create a new empty GitHub repository, then connect it using the remote URL GitHub provides:

```bash
git branch -M main
git remote add origin <YOUR_GITHUB_REPOSITORY_URL>
git push -u origin main
```

Do not paste passwords, tokens, private SSH keys, or credentials into tracked project files.
