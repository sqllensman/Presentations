# https://github.com/sqlcollaborative/dbatools
Return 'This is a demo, don''t run the whole thing, fool!!'

# Step 1: Fork from https://github.com/sqlcollaborative/dbatools

# Step 2: Clone to local PC
set-location c:\github

git clone https://github.com/sqllensman/dbatools.git

set-location c:\github\dbatools

# Check Status
git status

# Check 
git branch

# Switch to development branch
git checkout development

git status

# Add Remote Reference
git remote -v
git remote add upstream https://github.com/sqlcollaborative/dbatools.git

git remote -v

# Create a new Branch and Checkout
git branch SQLSatWinnipeg
git checkout SQLSatWinnipeg

git status

# Add Changes to Restart-DbaService - https://github.com/sqlcollaborative/dbatools/issues/5128
# View https://github.com/sqlcollaborative/dbatools/issues/5108

git add *

git status

git commit -m "Changes to Restart-DbaService to resolve Issue 5128"

git status

git push origin SQLSatWinnipeg

git status


# Git Examples

#  Clean up a fork and restart it from the upstream


# Check Remote Status
git remote -v

# Add Upstream if needed
git remote add upstream https://github.com/sqlcollaborative/dbatools.git 

# Fetch Files
git fetch upstream

git status
# Switch to main branch (if not already)
git checkout development
git reset --hard upstream/development  
git push origin development --force 

git status

