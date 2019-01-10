# drone-helm-gh-pages-deploy
[![Build Status](https://ci.andrewmellen.org/api/badges/mellena1/drone-helm-gh-pages-deploy/status.svg)](https://ci.andrewmellen.org/mellena1/drone-helm-gh-pages-deploy)

A plugin for drone.io to deploy charts to Github Pages. This plugin will search the repo for charts, package them all, and then deploy them to the branch hosting Github Pages.

## Build
To build the docker image:
```bash
docker build -t mellena1/drone-helm-gh-pages-deploy .
```

## Usage
Execute from the working directory (should be repo with the charts):
```bash
docker run --rm \
    -e DRONE_REMOTE_URL=git@github.com:mellena1/helm-charts.git \
    -e PLUGIN_SSH_KEY=$(cat ~/.ssh/id_rsa | base64) \
    -v $(pwd):$(pwd) \
    -w $(pwd) \
    mellena1/drone-helm-gh-pages-deploy
```

## Variables
| .drone.yml option | env var | description | default |
|-------------------|---------|-------------|---------|
| ssh_key | PLUGIN_SSH_KEY | base64 encoded private ssh key to pull the repo and push to it **(required)** | - |
| charts_folder | PLUGIN_CHARTS_FOLDER | folder to search for charts from | charts |
| github_pages_branch | PLUGIN_GITHUB_PAGES_BRANCH | branch that github pages is running off of | gh-pages |
| overwrite_existing | PLUGIN_OVERWRITE_EXISTING | overwrite existing charts if they already exist | false |
| git_email | PLUGIN_GIT_EMAIL | git email to make the commit with | drone@drone.io |
| git_name | PLUGIN_GIT_NAME | git name to make the commit with | drone |
| commit_message | PLUGIN_COMMIT_MESSAGE | commit message to make commit with | [drone.io] Added new charts. |
| push | PLUGIN_PUSH | whether to push or not | false |
