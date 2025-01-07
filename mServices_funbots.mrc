on *:load: { 
  set %mServices.loaded.funbots true 
  ms.funbots.makeconfig
  ms.echo green Loaded mServices_funbots.mrc
  ms.echo green Remember to change the configuration in %mServices.config
  load -rs scripts/mIRC-Services/mServices_fb_fishbot.mrc
  load -rs scripts/mIRC-Services/mServices_fb_banana.mrc
  load -rs scripts/mIRC-Services/mServices_fb_catbot.mrc
  load -rs scripts/mIRC-Services/mServices_fb_snailbot.mrc
}
on *:unload: {
  unset %mServices.loaded.funbots
  ms.funbots.remconfig
  ms.echo red Unloaded mServices_funbots.mrc
  unload -rs scripts/mIRC-Services/mServices_fb_fishbot.mrc
  unload -rs scripts/mIRC-Services/mServices_fb_banana.mrc
  unload -rs scripts/mIRC-Services/mServices_fb_catbot.mrc
  unload -rs scripts/mIRC-Services/mServices_fb_snailbot.mrc
}

alias ms.funbots.makeconfig { 

  ; ACCOUNT can be disabled by setting it to CHANGE_ME_TO_ENABLE
  ; ACCOUNT must be "username ID" for example: catbot 16
  ; More channels must be comma separated.

  writeini -n %mServices.config funbots configured false
  writeini -n %mServices.config funbots load fishbot,banana,catbot,snailbot

  writeini -n %mServices.config fishbot numeric AAC
  writeini -n %mServices.config fishbot nick fishbot
  writeini -n %mServices.config fishbot user fish
  writeini -n %mServices.config fishbot host go.moo.oh.yes.they.do
  writeini -n %mServices.config fishbot ip 127.0.0.1
  writeini -n %mServices.config fishbot realname fishbot goo m0o00o0000
  writeini -n %mServices.config fishbot modes +
  writeini -n %mServices.config fishbot account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config fishbot chan #fishbot

  writeini -n %mServices.config banana loaded true
  writeini -n %mServices.config banana numeric AAD
  writeini -n %mServices.config banana nick banana
  writeini -n %mServices.config banana user minions
  writeini -n %mServices.config banana host rule.the.world
  writeini -n %mServices.config banana ip 127.0.0.1
  writeini -n %mServices.config banana realname bello
  writeini -n %mServices.config banana modes +
  writeini -n %mServices.config banana account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config banana chan #fishbot

  writeini -n %mServices.config catbot loaded true
  writeini -n %mServices.config catbot numeric AAE
  writeini -n %mServices.config catbot nick catbot
  writeini -n %mServices.config catbot user cat
  writeini -n %mServices.config catbot host is.hungry
  writeini -n %mServices.config catbot ip 127.0.0.1
  writeini -n %mServices.config catbot realname catbot
  writeini -n %mServices.config catbot modes +
  writeini -n %mServices.config catbot account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config catbot chan #fishbot

  writeini -n %mServices.config snailbot loaded true
  writeini -n %mServices.config snailbot numeric AAF
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

alias ms.start.funbots {
  if ( %mServices.loaded.funbots == true ) && ( $readini(%mServices.config,funbots,configured) == true ) { 
    ms.echo blue [mServices mIRC Services] Prepping loading funbots
    var %ms.fbs.i $numtok($ms.config.get(load,funbots),44)
    while ( %ms.fbs.i ) { 
      var %ms.fbs.bot $gettok($ms.config.get(load,funbots),%ms.fbs.i,44)
      ms.echo blue [mServices mIRC Services] Launching funbots: %ms.fbs.bot
      ; Setting permanent variables because i think i'm going to use them a lot and it's easier to use.
      set %ms.fb. $+ %ms.fbs.bot $+ .numeric $ms.config.get(numeric,%ms.fbs.bot) 
      set %ms.fb. $+ %ms.fbs.bot $+ .nick $ms.config.get(nick,%ms.fbs.bot)
      set %ms.fb. $+ $ms.config.get(numeric,%ms.fbs.bot)  $ms.config.get(nick,%ms.fbs.bot)
      ms.servicebot.spawn $ms.config.get(nick,%ms.fbs.bot) $ctime $ms.config.get(user,%ms.fbs.bot) $ms.config.get(host,%ms.fbs.bot) $ms.config.get(modes,%ms.fbs.bot) $ms.config.get(account,%ms.fbs.bot) $ms.config.get(ip,%ms.fbs.bot) $ms.config.get(numeric,%ms.fbs.bot) $ms.config.get(realname,%ms.fbs.bot)
      ms.servicebot.join $ms.config.get(numeric,%ms.fbs.bot)  $ms.config.get(chan,%ms.fbs.bot)
      if ( $ms.config.get(channels,%ms.fbs.bot) ) { ms.servicebot.join $ms.config.get(numeric,%ms.fbs.bot)  $ms.config.get(channels,%ms.fbs.bot) }
      dec %ms.fbs.i
    }
  }
}

alias ms.stop.funbots { 
  if ( %mServices.loaded.funbots == true ) && ( $readini(%mServices.config,funbots,configured) == true ) { 
    var %ms.fbs.i $numtok($ms.config.get(load,funbots),44)
    while ( %ms.fbs.i ) { 
      var %ms.fbs.bot $gettok($ms.config.get(load,funbots),%ms.fbs.i,44)
      ms.servicebot.despawn $ms.config.get(numeric,%ms.fbs.bot) 
      dec %ms.fbs.i
    }
  }
}

; <client numeric> <target nick> <target chan>
alias ms.funbots.invited {
  if ($istok($ms.config.get(load,funbots),$2,44)) {
    var %ms.sb.clientnum $1
    var %ms.sb.chan $3
    var %ms.sb.num %ms.fb. [ $+ [ $2 ] ] [ $+ [ .numeric ] ]
    var %ms.sb.chans $ms.config.get(channels,$2)
    if ($istok(%ms.sb.chans,%ms.sb.chan,44)) { ms.servicebot.join %ms.sb.num %ms.sb.chan }
    else { ms.servicebot.addchan $2 $3 | ms.servicebot.join %ms.sb.num %ms.sb.chan }
  }
}

; <client numeric> <channel> <target numeric> 
alias ms.funbots.kicked {
  var %ms.sb.nick %ms.fb. [ $+ [ $3 ] ]
  if ($istok($ms.config.get(load,funbots),%ms.sb.nick,44)) {
    if ( $istok($ms.config.get(channels,%ms.sb.nick),$2,44) ) { ms.servicebot.remchan %ms.sb.nick $2 }
  }
}

alias ms.funbots.privmsg { 
  ms.fb.fishbot.privmsg $1- 
  ms.fb.banana.privmsg $1-
  ms.fb.catbot.privmsg $1-
  ms.fb.snailbot.privmsg $1-
  return 
}