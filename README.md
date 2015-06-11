# branch-status package

Show the current status of your branch using the GitHub status API.
It also inserts links to the status `target_url` and to the branch's pull
request if there is one.

## Usage

1. Install the package (Settings > Install > search for `branch-status`)
2. Make sure `branch-status` has a GitHub personal access token (OAuth):
  - [Create one](https://github.com/settings/tokens) and give it **only** the
    `repo:status` scope. See [security section](#security-section) below
  - Add the token to the package settings (Settings > Packages > branch-status)


If the branch name turns pink, open the developer tools (View > Developer >
Toggle Developer Tools) and see if the console shows an error.


### Here's what it looks like right now:

![](http://cloud.patnakajima.com/image/3t422y0p2S45/Gemfile%20-%20_Users_nakajima_github_github.png)

## Security

It's important to remember that inside Atom, any other package will be able to query and fetch the access token that you provide `branch-status`.

You should create a specific unique access token just for it to use. This way you can remove it later and provide it with just the access scope that it needs.

You should **ONLY** give it the `repo:access` scope.

**Don't** use a general all personall access token that has full permission for this package.
