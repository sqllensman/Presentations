# https://github.com/sqlcollaborative/dbatools
Return 'This is a demo, don''t run the whole thing, fool!!'

# Step 1: Fork from https://github.com/sqlcollaborative/dbatools
# Done via GitHub

# Step 2: Clone to local PC
set-location c:\github

git clone https://github.com/sqllensman/dbatools.git

set-location c:\github\dbatools

# Check Status
git status

# Switch to development branch
git checkout pre

git status

# Add Remote Reference
git remote -v
git remote add upstream https://github.com/sqlcollaborative/dbatools.git

git remote -v

# Create a new Branch and Checkout
git branch SydneyUG
git checkout SydneyUG

git status

# Add Changes for issue 5443 - https://github.com/sqlcollaborative/dbatools/issues/5443
# 

git add *

git status

git commit -m "Changes to resolve Issue 5443"

git status

git push origin SydneyUG

git status

# Merge Back to development
git checkout development
git merge SydneyUG




# Git Examples

# Get updates from Remote
git remote -v

git fetch upstream
<#
 Alternative pull from all remotes
 git remote update
#>
git merge upstream/development development

# Push to Origin
git push -u origin development
git status

# Remove Branch from Local and Remote
git branch
# remove from origin
git push --delete origin SydneyUG
# remove from local
git branch -D SydneyUG


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

# Update git with git
git clone https://github.com/git/git
