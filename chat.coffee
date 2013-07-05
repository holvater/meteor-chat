#Global for testing purposes
@Messages = new Meteor.Collection "messages"
Messages.allow
  remove: (uid, doc) -> 
    (uid and doc.uid is uid)


if Meteor.isClient
  Meteor.subscribe "messages"
  #change default config so we always have a username
  Accounts.ui.config
    passwordSignupFields:'USERNAME_AND_EMAIL'

  #scroll to the bottom of the chat every 2 seconds
  Meteor.setInterval( (() -> $("#chat").scrollTop(99999)) ,2000)
  Template.entry.registered = () -> Meteor.userId()
  
  Template.message.events
    "click a" : (e,t) -> #remove message with stored id
      Messages.remove _id:t.find("input").value
      e.preventDefault()
  
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
  Meteor.publish "messages", () -> Messages.find()
  #define helper methods to access database
  Meteor.methods
    insert: (uid, name, message) ->
      Messages.insert
        uid:uid
        name:name
        message:message
        createdOn: new Date()
