#!/usr/local/bin/bash

# Vars:
# PLUGIN_CHARTS_FOLDER
# PLUGIN_GITHUB_PAGES_BRANCH
# PLUGIN_OVERWRITE_EXISTING
# PLUGIN_COMMIT_MESSAGE
# PLUGIN_PUSH
# PLUGIN_BRANCH_DIR
# PLUGIN_SSH_KEY

# DEFAULT VARIABLE VALUES
PLUGIN_CHARTS_FOLDER=${PLUGIN_CHARTS_FOLDER:-"charts"}
PLUGIN_GITHUB_PAGES_BRANCH=${PLUGIN_GITHUB_PAGES_BRANCH:-"gh-pages"}
PLUGIN_OVERWRITE_EXISTING=${PLUGIN_OVERWRITE_EXISTING:-""}
PLUGIN_COMMIT_MESSAGE=${PLUGIN_COMMIT_MESSAGE:-"[ci] Added new charts."}
PLUGIN_PUSH=${PLUGIN_PUSH:-"true"}
PLUGIN_BRANCH_DIR=${PLUGIN_BRANCH_DIR:-"droneghpages"}
if [ -z "$PLUGIN_SSH_KEY" ]; then
    echo "ERROR: Must set ssh_key!"
    exit 1
fi

echo "$PLUGIN_CHARTS_FOLDER"

function convertGithubToSSH() {
    # Returns $git_repo_url
    USER=`echo $DRONE_REMOTE_URL | sed -Ene's#https://github.com/([^/]*)/(.*).git#\1#p'`
    if [ -z "$USER" ]; then
      echo "-- ERROR:  Could not identify User."
      exit
    fi

    REPO=`echo $DRONE_REMOTE_URL | sed -Ene's#https://github.com/([^/]*)/(.*).git#\2#p'`
    if [ -z "$REPO" ]; then
      echo "-- ERROR:  Could not identify Repo."
      exit
    fi

    git_repo_url="git@github.com:$USER/$REPO.git"
}

# Create the ssh key
mkdir ~/.ssh
echo $PLUGIN_SSH_KEY > ~/.ssh/id_rsa
chmod 0400 ~/.ssh/id_rsa

chartsdir="drone_builtcharts"

# Find and package all charts
mkdir $chartsdir
for f in $(find $PLUGIN_CHARTS_FOLDER -name Chart.yaml); do
    packagedchart=$(helm package $chart | grep -o "[^ ]*.tgz")
    mv $packagedchart $chartsdir/
done

# Clone the github pages branch
convertGithubToSSH
git clone -b $PLUGIN_GITHUB_PAGES_BRANCH --single-branch $git_repo_url $PLUGIN_BRANCH_DIR

# Move (or overwrite) all new charts onto the branch
for f in $(ls $chartsdir); do
    if [ -e $PLUGIN_BRANCH_DIR/$f ]; then
        if $PLUGIN_OVERWRITE_EXISTING; then
            rm $PLUGIN_BRANCH_DIR/$f
            mv $chartsdir/$f $PLUGIN_BRANCH_DIR/
        else
            rm $chartsdir/$f
        fi
    else
        mv $chartsdir/$f $PLUGIN_BRANCH_DIR/
    fi
done

# Cleanup
rm -r $chartsdir


cd $PLUGIN_BRANCH_DIR
# Remake index.yaml
rm -f index.yaml
helm repo index .

# Push to repo
if [ "$PLUGIN_PUSH" ]; then
    git add .
    git commit -m $PLUGIN_COMMIT_MESSAGE
    git push origin $PLUGIN_GITHUB_PAGES_BRANCH
fi
