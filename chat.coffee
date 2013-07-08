#Global for testing purposes
@Messages = new Meteor.Collection "messages"
@ConnectedUsers = new Meteor.Collection "connectedUsers"

Messages.allow
  remove: (uid, doc) -> 
    (uid and doc.uid is uid)

if Meteor.isClient
  Meteor.subscribe "messages"
  Meteor.subscribe "connectedUsers"
  #change default config so we always have a username
  Accounts.ui.config
    passwordSignupFields:'USERNAME_AND_EMAIL'
    
  Meteor.loginWithPassword = _.wrap Meteor.loginWithPassword, (login) ->
    args = _.toArray(arguments).slice(1)
    user = args[0]
    pass = args[1]
    origCallback = args[2]
    newCallback = () -> Meteor.call "setOnline", user
    Session.set "user", user
    login(user, pass, newCallback);

  #scroll to the bottom of the chat every 2 seconds
  Meteor.setInterval( (() -> $("#chat").scrollTop(99999)) ,2000)
  Template.meteorChat.events
    "click div#login-buttons-logout": (e,t) ->
      Meteor.call "setOffline", Session.get "user"
      Session.set "user", undefined

  Template.entry.registered = () -> Meteor.userId()
  
  Template.message.events
    "click a" : (e,t) -> #remove message with stored id
      Messages.remove _id:t.find("input").value
      e.preventDefault()
  
  Template.connectedUsers.users = () ->
    ConnectedUsers.find()
    #Meteor.call "connectedUsers"

  Template.message.deletable = () ->
    #only the owner/writer of the message can delete
    Meteor.user()?.username is this.name

  Template.messages.messages = () ->
    Messages.find()

  Template.entry.events
    "keypress #messageBox": (e,t)-> 
      #send on enter
      if e.keyCode is 13
        name = $("#name").val()
        message = $("#messageBox").val()
        Meteor.call "insert", Meteor.userId(), name, message
        $("#messageBox").val("")
        $("#chat").scrollTop 99999


if Meteor.isServer
  Meteor.publish "connectedUsers", () -> ConnectedUsers.find({online:true})
  Meteor.publish "messages", () -> Messages.find()

  Meteor.methods
    insert: (uid, name, message) ->
      Messages.insert
        uid:uid
        name:name
        message:message
        createdOn: new Date()
    connectedUsers: () ->
      sockets = Meteor.default_server.stream_server.open_sockets;
      sockets.map (sock) ->
        sock.username
    setOnline: (user) ->
      if typeof(ConnectedUsers.findOne({user:user})) isnt "undefined"
        ConnectedUsers.update user:user,
          user:user
          online:true
      else
        ConnectedUsers.insert
          user:user
          online:true
    setOffline: (user) ->
      ConnectedUsers.update user:user,
        user:user
        online:false
      