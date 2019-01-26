# https://github.com/sqlcollaborative/dbatools
Return 'This is a demo, don''t run the whole thing, fool!!'


set-location c:\github

git clone https://github.com/sqlcollaborative/dbatools.git

set-location c:\github\dbatools


git status

git checkout development

git status

git remote -v
git remote add upstream https://github.com/sqlcollaborative/dbatools.git

#git remote set-url upstream https://github.com/sqlcollaborative/dbatools.git

git remote -v

# Create a new Branch and Checkout
git branch SQLSatMalaysia
git checkout SQLSatMalaysia

git status

# Add Changes to Set-DbaDbState - https://github.com/sqlcollaborative/dbatools/issues/4899

git add *

git status

git commit -m "Changes to Export-DbaScript to resolve Issue 2914"

git status


git checkout development
git merge SQLSatMalaysia

git status

git push origin SQLSatMalaysia

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

