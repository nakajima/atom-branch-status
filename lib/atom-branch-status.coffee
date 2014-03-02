{$} = require 'atom'
request = require 'request'
SimpleGitHubFile = require './SimpleGitHubFile'

module.exports =
  activate: (state) ->
    atom.workspaceView.command "atom-branch-status:toggle", =>
      @pollStatus()

  deactivate: ->

  serialize: ->

  pollStatus: =>
    return unless repo = atom.project.getRepo()
    return unless editor = atom.workspace.getActiveEditor()

    # Pretty sure this requires the user to `apm login` first
    token = atom.getGitHubAuthToken()

    # Just want the name of the ref
    branch = repo.branch.replace('refs/heads/', '')

    # Find the name with owner
    githubURL = new SimpleGitHubFile(editor.getPath()).githubRepoUrl()
    nameWithOwner = githubURL.split('.com/')[1]

    requestOptions =
      uri: "https://api.github.com/repos/#{nameWithOwner}/statuses/#{branch}?access_token=#{token}"
      headers:
        'User-Agent': 'Atom Branch Status 0.0.1'

    request requestOptions, (error, response, body) =>
      statuses = JSON.parse(body)
      return unless lastStatus = statuses[0]

      # Actually updates the indicator. Wish there was a better way to access it
      # than just DOM traversal but yolo.
      if lastStatus.state is "success"
        $('.git-branch').css color: "green"
      if lastStatus.state is "pending"
        $('.git-branch').css color: "yellow"
      if lastStatus.state is "error" or lastStatus.state is "failure"
        $('.git-branch').css color: "red"
