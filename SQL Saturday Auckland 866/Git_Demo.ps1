# https://github.com/sqlcollaborative/dbatools
Return 'This is a demo, don''t run the whole thing, fool!!'

# Step 1: Fork from https://github.com/sqlcollaborative/dbatools
# Done via GitHub

# Step 2: Clone to local PC
set-location c:\github

git clone https://github.com/sqllensman/dbatools.git
set-location c:\github\dbatools

# Add Upstream if needed
git remote -v
git remote add upstream https://github.com/sqlcollaborative/dbatools.git 


# Check Status
git status

# Switch to development branch if needed
git checkout development


# Create a new Branch and Checkout
git branch SqlSat866
git checkout SqlSat866


# Add Changes 
# 

git add *

git status

git commit -m "Changes to add export functions for Roles"

git status

git push origin SqlSat866

git status


# Remove Branch from Local and Remote
git branch
# remove from origin
git push --delete origin SqlSat866
# remove from local
git branch -D SqlSat866


# Hard Reset
# Switch to main branch (if not already)
git checkout development
git reset --hard upstream/development  
git push origin development --force 

git status

# Update git with git
git clone https://github.com/git/git
