on *:load: { 
  set %mServices.loaded.funbots true 
  ms.funbots.makeconfig
  ms.echo green Loaded mServices_funbots.mrc
  ms.echo green Remember to change the configuration in %mServices.config
  load -rs mServices_fb_fishbot.mrc
  load -rs mServices_fb_banana.mrc
  load -rs mServices_fb_catbot.mrc
  load -rs mServices_fb_snailbot.mrc
}
on *:unload: {
  unset %mServices.loaded.funbots
  ms.funbots.remconfig
  ms.echo red Unloaded mServices_funbots.mrc
  unload -rs mServices_fb_fishbot.mrc
  unload -rs mServices_fb_banana.mrc
  unload -rs mServices_fb_catbot.mrc
  unload -rs mServices_fb_snailbot.mrc
}

alias ms.funbots.makeconfig { 

  ; ACCOUNT can be disabled by setting it to CHANGE_ME_TO_ENABLE
  ; ACCOUNT must be "username ID" for example: catbot 16
  ; More channels must be comma separated.

  writeini -n %mServices.config funbots configured true
  writeini -n %mServices.config funbots load fishbot,banana,catbot,snailbot

  writeini -n %mServices.config fishbot numeric AAB
  writeini -n %mServices.config fishbot nick fishbot
  writeini -n %mServices.config fishbot user fish
  writeini -n %mServices.config fishbot host go.moo.oh.yes.they.do
  writeini -n %mServices.config fishbot ip 127.0.0.1
  writeini -n %mServices.config fishbot realname fishbot goo m0o00o0000
  writeini -n %mServices.config fishbot modes +
  writeini -n %mServices.config fishbot account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config fishbot chan #fishbot

  writeini -n %mServices.config banana loaded true
  writeini -n %mServices.config banana numeric AAC
  writeini -n %mServices.config banana nick banana
  writeini -n %mServices.config banana user minions
  writeini -n %mServices.config banana host rule.the.world
  writeini -n %mServices.config banana ip 127.0.0.1
  writeini -n %mServices.config banana realname bello
  writeini -n %mServices.config banana modes +
  writeini -n %mServices.config banana account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config banana chan #fishbot

  writeini -n %mServices.config catbot loaded true
  writeini -n %mServices.config catbot numeric AAD
  writeini -n %mServices.config catbot nick catbot
  writeini -n %mServices.config catbot user cat
  writeini -n %mServices.config catbot host is.hungry
  writeini -n %mServices.config catbot ip 127.0.0.1
  writeini -n %mServices.config catbot realname catbot
  writeini -n %mServices.config catbot modes +
  writeini -n %mServices.config catbot account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config catbot chan #fishbot

  writeini -n %mServices.config snailbot loaded true
  writeini -n %mServices.config snailbot numeric AAE
  writeini -n %mServices.config snailbot nick snailbot
  writeini -n %mServices.config snailbot user snail
  writeini -n %mServices.config snailbot host is.slow
  writeini -n %mServices.config snailbot ip 127.0.0.1
  writeini -n %mServices.config snailbot realname snailbot
  writeini -n %mServices.config snailbot modes +
  writeini -n %mServices.config snailbot account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config snailbot chan #fishbot
  ms.echo green [mServices mIRC Services] Configuration for funbots has been reset.
}

alias ms.funbots.remconfig { 
  writeini -n %mServices.config configured funbots false
  remini %mServices.config fishbot
  remini %mServices.config banana
  remini %mServices.config catbot
  remini %mServices.config snailbot
}

alias ms.fb.get { 
  if ( $2 ) {
    if ( $1 == load ) { return $readini(%mServices.config,$2,load) }
    if ( $1 == nick ) { return $readini(%mServices.config,$2,nick) }
    if ( $1 == numeric ) { return $+(%ms.numeric,$readini(%mServices.config,$2,numeric)) }
    if ( $1 == user ) { return $readini(%mServices.config,$2,user) }
    if ( $1 == host ) { return $readini(%mServices.config,$2,host) }
    if ( $1 == ip ) { return $readini(%mServices.config,$2,ip) }
    if ( $1 == realname ) { return $readini(%mServices.config,$2,realname) }
    if ( $1 == modes ) { return $readini(%mServices.config,$2,modes) }
    if ( $1 == account ) { return $readini(%mServices.config,$2,account) }
    if ( $1 == chan ) { return $readini(%mServices.config,$2,chan) }
    if ( $1 == channels ) { return $readini(%mServices.config,$2,channels) }
  }
}

alias ms.fb.addchan { 
  if ( $2 ) { 
    writeini -n %mServices.config $1 channels $addtok($readini(%mServices.config,$1,channels), $2, 44)
  }
}
alias ms.fb.remchan { 
  if ( $2 ) { 
    if ( $readini(%mServices.config,$1,channels) >= 1 ) { writeini -n %mServices.config $1 channels $remtok($readini(%mServices.config,$1,channels), $2, 44) }
    else { remini %mServices.config $1 channels }
  }
}
alias ms.start.funbots {
  if ( %mServices.loaded.funbots == true ) && ( $readini(%mServices.config,funbots,configured) == true ) { 
    ms.echo blue [mServices mIRC Services] Prepping loading funbots
    var %ms.fbs.i $numtok($ms.fb.get(load,funbots),44)
    while ( %ms.fbs.i ) { 
      var %ms.fbs.bot $gettok($ms.fb.get(load,funbots),%ms.fbs.i,44)
      ms.echo blue [mServices mIRC Services] Launching funbots: %ms.fbs.bot
      ; Setting permanent variables because i think i'm going to use them a lot and it's easier to use.
      set %ms.fb. $+ %ms.fbs.bot $+ .numeric $ms.fb.get(numeric,%ms.fbs.bot)
      set %ms.fb. $+ %ms.fbs.bot $+ .nick $ms.fb.get(nick,%ms.fbs.bot)
      set %ms.fb. $+ $ms.fb.get(numeric,%ms.fbs.bot) $ms.fb.get(nick,%ms.fbs.bot)
      ms.servicebot.spawn $ms.fb.get(nick,%ms.fbs.bot) $ctime $ms.fb.get(user,%ms.fbs.bot) $ms.fb.get(host,%ms.fbs.bot) $ms.fb.get(modes,%ms.fbs.bot) $ms.fb.get(ip,%ms.fbs.bot) $ms.fb.get(numeric,%ms.fbs.bot) $ms.fb.get(realname,%ms.fbs.bot)
      ms.servicebot.join $ms.fb.get(numeric,%ms.fbs.bot) $ms.fb.get(chan,%ms.fbs.bot)
      if ( $ms.fb.get(channels,%ms.fbs.bot) ) { ms.servicebot.join $ms.fb.get(numeric,%ms.fbs.bot) $ms.fb.get(channels,%ms.fbs.bot) }
      dec %ms.fbs.i
    }
  }
}

alias ms.stop.funbots { 
  if ( %mServices.loaded.funbots == true ) && ( $readini(%mServices.config,funbots,configured) == true ) { 
    var %ms.fbs.i $numtok($ms.fb.get(load,funbots),44)
    while ( %ms.fbs.i ) { 
      var %ms.fbs.bot $gettok($ms.fb.get(load,funbots),%ms.fbs.i,44)
      ms.servicebot.despawn $ms.fb.get(numeric,%ms.fbs.bot)
      dec %ms.fbs.i
    }
  }
}

; <client numeric> <target nick> <target chan>
alias ms.funbots.invited {
  if ($istok($ms.fb.get(load,funbots),$2,44)) {
    var %ms.sb.clientnum $1
    var %ms.sb.chan $3
    var %ms.sb.num %ms.fb. [ $+ [ $2 ] ] [ $+ [ .numeric ] ]
    var %ms.sb.chans $ms.fb.get(channels,$2)
    if ($istok(%ms.sb.chans,%ms.sb.num,44)) { ms.servicebot.join %ms.sb.num %ms.sb.chan }
    else { ms.fb.addchan $2 $3 | ms.servicebot.join %ms.sb.num %ms.sb.chan }
  }
}

; <client numeric> <channel> <target numeric> 
alias ms.funbots.kicked {
  var %ms.sb.nick %ms.fb. [ $+ [ $3 ] ]
  if ($istok($ms.fb.get(load,funbots),%ms.sb.nick,44)) {
    if ( %ms.sb.nick ) { 
      if ( $istok($ms.fb.get(channels,%ms.sb.nick),$2,44) ) { ms.fb.remchan %ms.sb.nick $2 }
    }
  }
}

alias ms.funbots.privmsg { return }