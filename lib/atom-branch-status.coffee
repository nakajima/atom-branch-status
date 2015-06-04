{$} = require 'atom-space-pen-views'
Shell = require 'shell'
request = require 'request'
SimpleGitHubFile = require './SimpleGitHubFile'

foundPR = false
etag = null

getToken = ->
  atom.config.get("branch-status.personalAccessToken")
  #keytar = require 'keytar'
  #token = keytar.findPassword('Atom GitHub API Token') or keytar.findPassword('GitHub API Token')

getNameWithOwner = (editor) ->
  githubURL = new SimpleGitHubFile(editor.getPath()).githubRepoUrl()
  nameWithOwner = githubURL.split('.com/')[1]
  nameWithOwner?.replace(/\/+$/, '') # Replace any trailing slashes

getRef = ->
  repo = atom.project.getRepositories()?[0]
  refName = repo?.branch?.replace('refs/heads/', '').trim()
  refName

findPR = ->
  return if foundPR
  return unless ref = getRef()
  return unless editor = atom.workspace.getActiveTextEditor()

  token = getToken()

  # GitHub API address to poll (add token, if one is specified)
  uri = "https://api.github.com/repos/#{nameWithOwner}/pulls?head=#{owner}:#{ref}"
  uri += "&access_token=#{token}" if token
  console.log "URI:", uri

  # Add `If-None-Match` header to reduce unnecessary requests
  # (these don't count towards the API rate limit)
  ifNoneMatch = etag or ""

  # Find the name with owner
  nameWithOwner = getNameWithOwner(editor)
  owner = nameWithOwner.split('/')[0]
  requestOptions =
    uri: uri
    headers:
      'User-Agent': 'Atom Branch Status 0.8.0'
      'If-None-Match': ifNoneMatch

  request requestOptions, (error, response, body) =>
    console.error "Error:", error if error
    return if error
    console.log "Status code:", response.statusCode
    return unless response.statusCode is 200
    etag = response.headers.etag
    console.log "ETag:", etag
    return unless pr = JSON.parse(body)[0]
    # Don't insert dups while looking up initial PR
    return if $('.atom-branch-status-pr-number').length
    foundPR = true
    link = $("<a class='atom-branch-status-pr-number'> ##{pr.number} </a>")
    link.on "click", -> Shell.openExternal(pr.html_url)
    $('.icon-git-branch').after(link)

pollStatus = ->
  # New poll in 5 seconds
  setTimeout pollStatus, 5000

  return unless ref = getRef()
  return unless editor = atom.workspace.getActiveTextEditor()

  # Get personal access token from settings
  token = getToken()

  # Find the name with owner
  nameWithOwner = getNameWithOwner(editor)

  # GitHub API address to poll (add token, if one is specified in settings)
  uri = "https://api.github.com/repos/#{nameWithOwner}/statuses/#{ref}"
  uri += "?access_token=#{token}" if token
  console.log "URI:", uri

  # Add `If-None-Match` header to reduce unnecessary requests
  # (these don't count towards the API rate limit)
  ifNoneMatch = etag or ""

  statusRequestOptions =
    uri: uri
    headers:
      'User-Agent': 'Atom Branch Status 0.8.0'
      'If-None-Match': ifNoneMatch

  request statusRequestOptions, (error, response, body) =>
    console.log "Error:", error if error
    return if error
    console.log "Status code:", response.statusCode
    return unless response.statusCode is 200
    console.log response
    etag = response.headers.etag
    console.log "ETag:", etag
    statuses = JSON.parse(body)
    statusContexts = []
    console.log statuses

    message = statuses.message
    state = message

    if not state
      for status in statuses
        context = status.context
        # Break if the status is not for the current ref
        break if context in statusContexts
        # Save the context of the status
        statusContexts.push(context)

        if status.state != "success" or not state
          # Set state and message
          state = status.state
          message = status.description
          # Break out of loop if the state is "error" or "failure"
          break if state is "error" or state is "failure"

    console.log "State:", state
    console.log "Message:", message

    # Actually updates the indicator. Wish there was a better way to access it
    # than just DOM traversal but yolo.
    if state is "success"
      console.log "success"
      $('.git-branch').css color: "green"
    else if state is "pending"
      console.log "pending"
      $('.git-branch').css color: "yellow"
    else if state is "error" or state is "failure"
      console.log "error/failure"
      $('.git-branch').css color: "red"
    else if state
      console.log "Some error"
      $('.git-branch').css color: "pink"

    # TODO: Show message in tooltip?
    #setToolTip(message)

module.exports =
  config:
    personalAccessToken:
      type: "string"
      description: "Your personal GitHub access token"
      default: ""

  activate: (state) ->
    setTimeout @retryStatus, 5000

  deactivate: ->

  serialize: ->

  retryStatus: =>
    findPR()
    pollStatus()
