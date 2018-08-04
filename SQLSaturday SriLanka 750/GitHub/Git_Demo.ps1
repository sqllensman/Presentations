Import-Module -Name posh-git

set-location c:\github

git clone https://github.com/sqllensman/dbatools.git

set-location c:\github\dbatools

git status

git remote add upstream https://github.com/sqlcollaborative/dbatools.git

git remote set-url upstream https://github.com/sqlcollaborative/dbatools.git

git remote -v

# Create a new Branch and Checkout
git branch SQLSaturday
git checkout SQLSaturday

git status

# Push backup to GitHub Repository
git push -u origin WaitsSpinsLatch

git push --set-upstream origin WaitsSpinsLatch


git add *

git commit -m "Adding Functions for Latch Statistics, Spin Statistics and IO Latency"

git status

git push origin WaitsSpinsLatch

git checkout development
git merge WaitsSpinsLatch

git pull


# Git Examples

#  Clean up a fork and restart it from the upstream


#The simplest solution would be 


# Check Remote Status
git remote -v

# Add Upstream if needed
git remote add upstream https://github.com/sqlcollaborative/dbatools.git 

# Fetch Files
git fetch upstream

git status
# Switch to master (if not already)
git checkout development
git reset --hard upstream/development  
git push origin development --force 

git status


