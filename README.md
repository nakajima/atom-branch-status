# branch-status package

Show the current status of your branch using the GitHub status API.
It also inserts links to the status `target_url` and to the branch's pull
request if there is one.

## Usage

1. Install the package (Settings > Install > search for `branch-status`)
2. Make sure `branch-status` has a GitHub personal access token (OAuth):
  - [Create one](https://github.com/settings/tokens) and give it the
    `repo:status` scope
  - Add the token to the package settings (Settings > Packages > branch-status)


If the branch name turns pink, open the developer tools (View > Developer >
Toggle Developer Tools) and see if the console shows an error.


### Here's what it looks like right now:

![](http://cloud.patnakajima.com/image/3t422y0p2S45/Gemfile%20-%20_Users_nakajima_github_github.png)
