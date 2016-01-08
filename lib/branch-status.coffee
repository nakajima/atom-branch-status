$ = null
request = null
SimpleGitHubFile = null
Shell = null

etag = null
tooltip = null

ref = null
state = null
message = null
targetUrl = null

getToken = ->
  atom.config.get("branch-status.personalAccessToken")
  #keytar = require 'keytar'
  #token = keytar.findPassword('Atom GitHub API Token') or keytar.findPassword('GitHub API Token')

getNameWithOwner = (editor) ->
  githubURL = new SimpleGitHubFile(editor.getPath()).githubRepoUrl()
  return unless githubURL
  nameWithOwner = githubURL.split('.com/')[1]
  nameWithOwner?.replace(/\/+$/, '') # Replace any trailing slashes

getRef = ->
  repo = atom.project.getRepositories()?[0]
  refName = repo?.branch?.replace('refs/heads/', '').trim()
  refName

findPR = ->
  # New poll in 5 seconds (TODO: Better way of doing this?)
  setTimeout findPR, 5000

  return unless prRef = getRef()
  return unless editor = atom.workspace.getActiveTextEditor()

  # Get personal access token from settings
  token = getToken()

  # Find the name with owner
  return unless nameWithOwner = getNameWithOwner(editor)
  owner = nameWithOwner.split('/')[0]

  # GitHub API address to poll (add token, if one is specified in settings)
  uri = "https://api.github.com/repos/#{nameWithOwner}/pulls?head=#{owner}:#{prRef}"
  uri += "&access_token=#{token}" if token

  requestOptions =
    uri: uri
    headers:
      'User-Agent': 'Atom Branch Status 0.8.0'

  request requestOptions, (error, response, body) =>
    console.error "Error:", error if error
    return if error
    # Return if nothing has changed since the last request
    return if response.statusCode is 304
    body = JSON.parse(body)
    # Print error if something went wrong with the request
    if not response.statusCode is 200
      console.error response.statusCode, body?.message or response.statusMessage
      return
    # Remove previous PR link
    $('.branch-status-pr-number')?.remove()
    return unless pr = body[0]
    link = $("<a class='branch-status-pr-number'> (##{pr.number})</a>")
    link.on "click", -> Shell.openExternal(pr.html_url)
    labelElement = $('.git-branch .branch-label')
    labelElement.after(link)

pollStatus = ->
  # New poll in 5 seconds (TODO: Better way of doing this?)
  setTimeout pollStatus, 5000

  # Store ref from last poll
  oldRef = ref

  return unless ref = getRef()
  return unless editor = atom.workspace.getActiveTextEditor()

  # Get personal access token from settings
  token = getToken()

  # Find the name with owner
  return unless nameWithOwner = getNameWithOwner(editor)

  # GitHub API address to poll (add token, if one is specified in settings)
  uri = "https://api.github.com/repos/#{nameWithOwner}/statuses/#{ref}"
  uri += "?access_token=#{token}" if token

  # Add `If-None-Match` header to reduce unnecessary requests
  # (these don't count towards the API rate limit)
  ifNoneMatch = etag or ""

  # Always get the status if the ref has changed
  # (otherwise we would need to store the status for each ref)
  ifNoneMatch = "" if ref is not oldRef

  statusRequestOptions =
    uri: uri
    headers:
      'User-Agent': 'Atom Branch Status 0.8.0'
      'If-None-Match': ifNoneMatch

  request statusRequestOptions, (error, response, body) =>
    console.error "Error:", error if error
    return if error
    # Return if nothing has changed since the last request
    return if response.statusCode is 304
    etag = response.headers.etag
    body = JSON.parse(body)

    state = null
    state = response.statusCode unless response.statusCode is 200
    message = body.message or response.statusMessage
    targetUrl = null

    if not state
      statusContexts = []
      for status in body
        context = status.context
        # Break if the status is not for the current ref
        break if context in statusContexts
        # Save the context of the status
        statusContexts.push(context)

        if status.state != "success" or not state
          # Set state and message
          state = status.state
          message = status.description
          targetUrl = status.target_url
          # Break out of loop if the state is "error" or "failure"
          break if state is "error" or state is "failure"

  # Actually updates the indicator. Wish there was a better way to access it
  # than just DOM traversal but yolo.
  branchElement = $('.git-branch')
  if state is "success"
    branchElement.css color: "green"
  else if state is "pending"
    branchElement.css color: "yellow"
  else if state is "error" or state is "failure"
    branchElement.css color: "red"
  else if state
    branchElement.css color: "pink"
    console.error state, message

  if message
    # Remove previous tool tip
    tooltip?.dispose()
    # Show status message in tool tip
    tooltip = atom.tooltips.add(branchElement, {title: message})

  if targetUrl
    # Add link to the status target_url (e.g. build log)
    labelElement = $('.git-branch .branch-label')
    linkText = labelElement[0].innerText
    link = $("<a class='branch-status-target-link'>" + linkText + "</a>")
    link.on "click", -> Shell.openExternal(targetUrl)
    labelElement.html(link)

module.exports =
  config:
    personalAccessToken:
      type: "string"
      description: "Your personal GitHub access token"
      default: ""

  activate: (state) ->
    console.log state
    setTimeout @retryStatus, 5000

  deactivate: ->

  serialize: ->

  retryStatus: =>
    $ ?= require('atom-space-pen-views').$
    request ?= require 'request'
    SimpleGitHubFile ?= require './SimpleGitHubFile'
    Shell ?= require 'shell'
    findPR()
    pollStatus()
