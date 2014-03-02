{$} = require 'atom'
Shell = require 'shell'
request = require 'request'
SimpleGitHubFile = require './SimpleGitHubFile'

module.exports =
  activate: (state) ->
    atom.workspaceView.command "atom-branch-status:toggle", =>
      @pollStatus()
      @findPR()
    setTimeout (=> @pollStatus()), 10000

  deactivate: ->

  serialize: ->

  findPR: =>
    return if @foundPR
    return unless repo = atom.project.getRepo()
    return unless editor = atom.workspace.getActiveEditor()

    # Pretty sure this requires the user to `apm login` first
    token = atom.getGitHubAuthToken()

    # Just want the name of the ref
    branch = repo.branch.replace('refs/heads/', '').trim()

    # Find the name with owner
    githubURL = new SimpleGitHubFile(editor.getPath()).githubRepoUrl()
    nameWithOwner = githubURL.split('.com/')[1]
    owner = nameWithOwner.split('/')[0]
    requestOptions =
      uri: "https://api.github.com/repos/#{nameWithOwner}/pulls?access_token=#{token}&head=#{owner}:#{branch}"
      headers:
        'User-Agent': 'Atom Branch Status 0.0.1'

    request requestOptions, (error, response, body) =>
      return unless pr = JSON.parse(body)[0]
      @foundPR = true
      link = $("<a class='atom-branch-status-pr-number'> ##{pr.number} </a>")
      link.on "click", -> Shell.openExternal(pr.html_url)
      $('.icon-git-branch').after(link)

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

    statusRequestOptions =
      uri: "https://api.github.com/repos/#{nameWithOwner}/statuses/#{branch}?access_token=#{token}"
      headers:
        'User-Agent': 'Atom Branch Status 0.0.1'

    request statusRequestOptions, (error, response, body) =>
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
