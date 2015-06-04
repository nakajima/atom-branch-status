# atom-branch-status package

Show the current status of your branch using the GitHub status API.
It also inserts a link to the branch's pull request if there is one.

## Usage

1. Install the package (Settings > Install > search for `branch-status`)
2. Make sure `branch-status` has a GitHub personal access token:
  - [Create one](https://github.com/settings/tokens) and give it the
    `repo:status` scope
  - Add the token to the package settings (Settings > Packages > branch-status)

The package works without the personal access token, but the GitHub API has a
rate limit of 60 unauthenticated requests per hour.

If the branch name turns pink, open the developer tools (View > Developer >
Toggle Developer Tools) and see if the console shows an error.

## Todo

- I'd also like to be able to click the build and go to the `target_url`.
- Tool tip with the status message when hovering over the branch name.

### Here's what it looks like right now:

![](http://cloud.patnakajima.com/image/3t422y0p2S45/Gemfile%20-%20_Users_nakajima_github_github.png)
