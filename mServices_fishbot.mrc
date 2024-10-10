on *:load: { set %mServices.fishbot.loaded true | set %mServices.banana.loaded true | ms.echo green Loaded mServices_fishbot.mrc }
on *:unload: { unset %mServices.fishbot.loaded,%mServices.fishbot.loaded | ms.echo red Unloaded mServices_fishbot.mrc }

alias ms.load.fishbot {
  if ( %mServices.fishbot.loaded == true ) { 
    ms.echo blue [mServices mIRC Services] prepping loading fishbot
    set %ms.fishbot.numeric $ms.picknumeric
    set %ms.fishbot.nick fishbot
    set %ms.fishbot.user fish
    set %ms.fishbot.host go.moo.oh.yes.they.do
    set %ms.fishbot.ip 127.0.0.1
    set %ms.fishbot.realname fishbot goo m0o00o0000
    set %ms.fishbot.modes +x
    
    ; More channels must be comma separated.
    set %ms.fishbot.chan #fishbot

    ms.servicebot.spawn %ms.fishbot.nick $ctime %ms.fishbot.user %ms.fishbot.host %ms.fishbot.modes %ms.fishbot.ip %ms.fishbot.numeric %ms.fishbot.realname 
    ms.servicebot.join %ms.fishbot.numeric %ms.fishbot.chan
    if ( %ms.fishbot.channels ) { ms.servicebot.join %ms.fishbot.numeric %ms.fishbot.channels }
  }
}

alias ms.load.banana {
  if ( %mServices.banana.loaded == true ) { 
    ms.echo blue [mServices mIRC Services] prepping loading banana
    set %ms.banana.numeric $ms.picknumeric
    set %ms.banana.nick banana
    set %ms.banana.user minions
    set %ms.banana.host rule.the.world
    set %ms.banana.ip 127.0.0.1
    set %ms.banana.realname bello
    set %ms.banana.modes +x
    
    ; More channels must be comma separated.
    set %ms.banana.chan #fishbot

    ms.servicebot.spawn %ms.banana.nick $ctime %ms.banana.user %ms.banana.host %ms.banana.modes %ms.banana.ip %ms.banana.numeric %ms.banana.realname
    ms.servicebot.join %ms.banana.numeric %ms.banana.chan
    if ( %ms.banana.channels ) { ms.servicebot.join %ms.banana.numeric %ms.banana.channels }
  }
}
alias ms.unload.fishbot { 
  if ( %mServices.fishbot.loaded == true ) { 
    ms.servicebot.despawn %ms.fishbot.numeric 
  }
}
alias ms.unload.banana { 
  if ( %mServices.banana.loaded == true ) { 
    ms.servicebot.despawn %ms.banana.numeric 
  }
}
alias ms.fishbot.invite {
  var %chan $3
  var %nick $1
  if ( $istok(%ms.fishbot.channels,%chan,44) ) { mServices.raw %ms.fishbot.numeric J %chan }
  else { mServices.raw %ms.fishbot.numeric J %chan | set %ms.fishbot.channels $addtok(%ms.fishbot.channels,%chan,44) }
}

