@Messages = new Meteor.Collection "messages"
Messages.allow
  remove: (uid, doc) -> (uid and doc.uid is uid)

if Meteor.isClient
  Meteor.subscribe "messages"
  Accounts.ui.config
    passwordSignupFields:'USERNAME_AND_EMAIL'
  Meteor.setInterval( (() -> $("#chat").scrollTop(99999)) ,2000)
  Template.entry.registered = () -> Meteor.userId()
  
  Template.message.events
    "click a" : (e,t) ->
      Meteor.call "remove", t.find("input").value
      e.preventDefaults()
  
  Template.message.deletable = () ->
    Meteor.user() and Meteor.user().username is this.name
  Template.messages.messages = () ->
    Messages.find()
  Template.entry.events
    "keypress #messageBox": (e,t)-> 
      if e.keyCode is 13
        name = $("#name").val()
        message = $("#messageBox").val()
        Meteor.call "insert", Meteor.userId(), name, message
        $("#messageBox").val("")


if Meteor.isServer
  Meteor.publish "messages", () -> Messages.find()
  Meteor.methods
    insert: (uid, name, message) ->
      Messages.insert
        uid:uid
        name:name
        message:message
        createdOn: new Date()
    remove: (id) ->
      Messages.remove 
        _id:id
