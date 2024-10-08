on *:load: { set %mServices.fishbot.loaded true | ms.echo green Loaded mServices_fishbot.mrc }
on *:unload: { unset %mServices.fishbot.loaded | ms.echo red Unloaded mServices_fishbot.mrc }

alias ms.load.fishbot {
  if ( %mServices.fishbot.loaded == true ) { 
    ms.echo green prepping loading fishbot
    set %ms.fishbot.numeric $ms.makenewclientnumeric
    set %ms.fishbot.nick fishbot
    set %ms.fishbot.user fishbot
    set %ms.fishbot.host fishbot.goo.moo
    set %ms.fishbot.realname fishbot goo m0o00o0000
    set %ms.fishbot.modes +x
    ; More channels must be comma separated.
    set %ms.fishbot.chan #spychan
    ms.echo green spawning %ms.fishbot.nick ! %ms.fishbot.user @ %ms.fishbot.host [ %ms.fishbot.realname ] with modes: %ms.fishbot.modes 

    ; Making new bot and writing it to the sevrer's database
    mServices.sraw N %ms.fishbot.nick 1 $ctime %ms.fishbot.user %ms.fishbot.host %ms.fishbot.modes $inttobase64($longip(127.0.0.1),6) %ms.fishbot.numeric $+(:,%ms.fishbot.realname)
    ms.newclient %mServices.numeric N %ms.fishbot.nick 1 $ctime %ms.fishbot.user %ms.fishbot.host %ms.fishbot.modes $inttobase64($longip(127.0.0.1),6) %ms.fishbot.numeric $+(:,%ms.fishbot.realname)

    ms.fishbot.join %ms.fishbot.chan
    if ( %ms.fishbot.channels ) { ms.fishbot.join %ms.fishbot.channels }
  }
}
alias ms.fishbot.join { 
  if ( $numtok($1,44) > 2 ) {
    var %c $1 
    while ( %chan ) { 
      mServices.raw %ms.fishbot.numeric J $gettok($1,%c,44)
      ms.client.join %ms.fishbot.numeric $gettok($1,%c,44)
      dec %c
    } 
  }
  else { 
    mServices.raw %ms.fishbot.numeric J $1
    ms.client.join %ms.fishbot.numeric $1
  }
}
alias ms.fishbot.invite {
  var %chan $3
  var %nick $1
  if ( $istok(%ms.fishbot.channels,%chan,44) ) { mServices.raw %ms.fishbot.numeric J %chan }
  else { mServices.raw %ms.fishbot.numeric J %chan | set %ms.fishbot.channels $addtok(%ms.fishbot.channels,%chan,44) }
}
alias ms.fishbot.kicked {
  if ( $istok(%ms.fishbot.channels,$1,44) ) { set %ms.fishbot.channels $remtok(%ms.fishbot.channels,$1,44) }
}
; placeholder, this two aliases are going to be used for the fishbot to respond to messages
alias ms.fishbot.text { return }
alias ms.fishbot.privmsg { return }