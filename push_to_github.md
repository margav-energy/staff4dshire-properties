# Push to GitHub Instructions

## Step 1: Create a GitHub Repository

1. Go to https://github.com/new
2. Repository name: `staff4dshire-properties` (or your preferred name)
3. Choose Public or Private
4. **DO NOT** initialize with README, .gitignore, or license (we already have these)
5. Click "Create repository"

## Step 2: Push Your Code

After creating the repository, GitHub will show you commands. Use these instead (already configured):

```bash
cd "c:\Users\User\Desktop\Staff4dshire Properties"
git remote add origin https://github.com/margav-energy/staff4dshire-properties.git
git branch -M main
git push -u origin main
```

**Note:** Replace `margav-energy/staff4dshire-properties` with your actual GitHub username and repository name.

## Alternative: Using SSH (if you have SSH keys set up)

```bash
git remote add origin git@github.com:margav-energy/staff4dshire-properties.git
git branch -M main
git push -u origin main
```



