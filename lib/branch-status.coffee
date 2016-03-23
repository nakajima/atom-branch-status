$ = null
request = null
SimpleGitHubFile = null
Shell = null

etag = null
tooltip = null

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

  return unless ref = getRef()
  return unless editor = atom.workspace.getActiveTextEditor()

  # Get personal access token from settings
  token = getToken()

  # Find the name with owner
  return unless nameWithOwner = getNameWithOwner(editor)
  owner = nameWithOwner.split('/')[0]

  # GitHub API address to poll (add token, if one is specified in settings)
  uri = "https://api.github.com/repos/#{nameWithOwner}/pulls?head=#{owner}:#{ref}"
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
      state = response.statusCode unless response.statusCode is 200
      message = body?.message or response.statusMessage
      console.error state, message
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
      branchElement.css color: "#0AB254"
    else if state is "pending"
      branchElement.css color: "#FFE754"
    else if state is "error" or state is "failure"
      branchElement.css color: "#FF2F1D"
    else if state
      branchElement.css color: "#AA8A69"
      console.error state, message
    else
      branchElement.css color: "inherit"
      message = null

    # Remove any previous tool tip
    tooltip?.dispose()

    if message
      # Show status message in tool tip
      tooltip = atom.tooltips.add(branchElement, {title: message})

    if targetUrl
      # Add link to
      labelElement = $('.git-branch .branch-label')
      link = $("<a class='branch-status-target-link'>" + labelElement[0].innerText + "</a>")
      link.on "click", -> Shell.openExternal(targetUrl)
      labelElement.html(link)
    else
      # Remove any previous link
      labelElement = $('.git-branch .branch-label')
      text = $("<span>" + labelElement[0].innerText + "</span>")
      labelElement.html(text)

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
