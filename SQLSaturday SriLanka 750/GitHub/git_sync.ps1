set-location c:\github\dbatools

# Check Status
git status

# Check remote Branches
git remote -v

# Add Reference to Original Source
git remote add upstream https://github.com/sqlcollaborative/dbachecks.git

# What does this do:
# Set an alias in your local repository called upstream that points at the main dbatools repository.

# Sync Repository
git fetch source
git fetch upstream

git push source

