#!/usr/local/bin/bash

# Vars:
# PLUGIN_CHARTS_FOLDER - folder to search for charts from
# PLUGIN_GITHUB_PAGES_BRANCH - branch that github pages is running off of
# PLUGIN_OVERWRITE_EXISTING - overwrite existing charts if they already exist
# PLUGIN_GIT_EMAIL - git email to make the commit with
# PLUGIN_GIT_NAME - git name to make the commit with
# PLUGIN_COMMIT_MESSAGE - commit message to make commit with
# PLUGIN_PUSH - whether to push or not
# PLUGIN_SSH_KEY - base64 encoded private ssh key to pull the repo and push to it (required)

# DEFAULT VARIABLE VALUES
PLUGIN_CHARTS_FOLDER=${PLUGIN_CHARTS_FOLDER:-"charts"}
PLUGIN_GITHUB_PAGES_BRANCH=${PLUGIN_GITHUB_PAGES_BRANCH:-"gh-pages"}
PLUGIN_OVERWRITE_EXISTING=${PLUGIN_OVERWRITE_EXISTING:-""}
PLUGIN_GIT_EMAIL=${PLUGIN_GIT_EMAIL:-"drone@drone.io"}
PLUGIN_GIT_NAME=${PLUGIN_GIT_NAME:-"drone"}
PLUGIN_COMMIT_MESSAGE=${PLUGIN_COMMIT_MESSAGE:-"[drone.io] Added new charts."}
PLUGIN_PUSH=${PLUGIN_PUSH:-"true"}
if [ -z "$PLUGIN_SSH_KEY" ]; then
  echo "-- ERROR: Must set ssh_key!"
  exit 1
fi

function convertGithubToSSH() {
  # Returns $git_repo_url
  if [ $(echo "$DRONE_REMOTE_URL" | grep "https://github.com") ]; then
    USER=`echo $DRONE_REMOTE_URL | sed -Ene's#https://github.com/([^/]*)/(.*).git#\1#p'`
    if [ -z "$USER" ]; then
      echo "-- ERROR: Could not identify User."
      exit 1
    fi

    REPO=`echo $DRONE_REMOTE_URL | sed -Ene's#https://github.com/([^/]*)/(.*).git#\2#p'`
    if [ -z "$REPO" ]; then
      echo "-- ERROR: Could not identify Repo."
      exit 1
    fi
  
    git_repo_url="git@github.com:$USER/$REPO.git"
  elif [ $(echo "$DRONE_REMOTE_URL" | grep 'git@github.com') ]; then
    git_repo_url="$DRONE_REMOTE_URL"
  else
    echo "-- ERROR: Invalid github url."
    exit 1
  fi
}

# Create the ssh key
echo $PLUGIN_SSH_KEY | base64 -d > ~/.ssh/id_rsa
chmod 0400 ~/.ssh/id_rsa

chartsdir="drone_builtcharts"
ghpages_branch="droneghpages"

# Find and package all charts
mkdir -p $chartsdir
for f in $(find $PLUGIN_CHARTS_FOLDER -name Chart.yaml); do
  chart=$(dirname $f)
  packagedchart=$(helm package $chart | grep -o "[^ ]*.tgz")
  mv "$packagedchart" "$chartsdir/"
done

# Clone the github pages branch
convertGithubToSSH
ssh-agent bash -c "ssh-add ~/.ssh/id_rsa; git clone -b \"$PLUGIN_GITHUB_PAGES_BRANCH\" --single-branch \"$git_repo_url\" \"$ghpages_branch\"" &> /dev/null

charts_added=false
# Move (or overwrite) all new charts onto the branch
for f in $(ls $chartsdir); do
  if [ -e "$ghpages_branch/$f" ]; then
    if [ "$PLUGIN_OVERWRITE_EXISTING" = true ]; then
      rm "$ghpages_branch/$f"
      mv "$chartsdir/$f" "$ghpages_branch/"
      echo "Updated: $f"
      charts_added=true
    else
      rm "$chartsdir/$f"
    fi
  else
    mv "$chartsdir/$f" "$ghpages_branch/"
    echo "Added: $f"
    charts_added=true
  fi
done

# Cleanup packaged charts dir
rm -r "$chartsdir"


cd "$ghpages_branch"
# Remake index.yaml if there are new charts
if [ charts_added = true ]; then
  rm -f index.yaml
  helm repo index .
else
  echo "Nothing new to update."
  cd .. && rm -rf "$ghpages_branch"
  exit 0
fi

# Push to repo
if [ "$PLUGIN_PUSH" = true ]; then
  git config --global user.email "$PLUGIN_GIT_EMAIL"
  git config --global user.name "$PLUGIN_GIT_NAME"
  git add .
  git commit -m "$PLUGIN_COMMIT_MESSAGE"
  ssh-agent bash -c "ssh-add ~/.ssh/id_rsa; git push origin \"$PLUGIN_GITHUB_PAGES_BRANCH\""
fi

# Cleanup
cd .. && rm -rf "$ghpages_branch"
exit 0
