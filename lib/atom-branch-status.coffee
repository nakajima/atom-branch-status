{$} = require 'atom-space-pen-views'
Shell = require 'shell'
request = require 'request'
SimpleGitHubFile = require './SimpleGitHubFile'

foundPR = false

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

  # Find the name with owner
  nameWithOwner = getNameWithOwner(editor)
  owner = nameWithOwner.split('/')[0]
  requestOptions =
    uri: "https://api.github.com/repos/#{nameWithOwner}/pulls?access_token=#{token}&head=#{owner}:#{ref}"
    headers:
      'User-Agent': 'Atom Branch Status 0.0.1'

  request requestOptions, (error, response, body) =>
    return unless pr = JSON.parse(body)[0]
    return if $('.atom-branch-status-pr-number').length # Don't insert dups while looking up initial PR
    foundPR = true
    link = $("<a class='atom-branch-status-pr-number'> ##{pr.number} </a>")
    link.on "click", -> Shell.openExternal(pr.html_url)
    $('.icon-git-branch').after(link)

pollStatus = ->
  return unless ref = getRef()
  return unless editor = atom.workspace.getActiveTextEditor()

  token = getToken()

  # Find the name with owner
  nameWithOwner = getNameWithOwner(editor)

  uri = "https://api.github.com/repos/#{nameWithOwner}/statuses/#{ref}"
  uri += "?access_token=#{token}" if token
  console.log uri

  statusRequestOptions =
    uri: uri
    headers:
      'User-Agent': 'Atom Branch Status 0.8.0'

  request statusRequestOptions, (error, response, body) =>
    console.log "request"
    statuses = JSON.parse(body)
    console.log statuses

    state = statuses.message

    if not state
      for status in statuses
        if status.state is "success"
          # Only set state to success if no previous state has been set
          state = status.state if not state
          console.log state
        else
          # Set state
          state = status.state
          console.log state
          # Break out of loop if the state is either "error" or "failure"
          break if state is "error" or state is "failure"

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

    setTimeout pollStatus, 5000

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
