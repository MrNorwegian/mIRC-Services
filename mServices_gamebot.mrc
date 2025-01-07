on *:load: { 
  set %mServices.loaded.gamebot true 
  ms.gamebot.makeconfig
  ms.echo green Loaded mServices_gamebot.mrc
  ms.echo green Remember to change the configuration in %mServices.config
  load -rs scripts/mIRC-Services/mServices_gb_3row.mrc
  load -rs scripts/mIRC-Services/mServices_gb_magic.mrc
}
on *:unload: {
  unset %mServices.loaded.gamebot
  ms.gamebot.remconfig
  ms.echo red Unloaded mServices_gamebot.mrc
  unload -rs scripts/mIRC-Services/mServices_gb_3row.mrc
  unload -rs scripts/mIRC-Services/mServices_gb_magic.mrc
}

alias ms.gamebot.makeconfig {

  ; ACCOUNT can be disabled by setting it to CHANGE_ME_TO_ENABLE
  ; ACCOUNT must be "username ID" for example: catbot 16
  ; More channels must be comma separated.

  writeini -n %mServices.config gamebot configured false
  writeini -n %mServices.config gamebot load gamebot

  writeini -n %mServices.config gamebot numeric AAG
  writeini -n %mServices.config gamebot nick G
  writeini -n %mServices.config gamebot user gamebot
  writeini -n %mServices.config gamebot host is.here.to.play.games
  writeini -n %mServices.config gamebot ip 127.0.0.1
  writeini -n %mServices.config gamebot realname Invite me and !help
  writeini -n %mServices.config gamebot modes +
  writeini -n %mServices.config gamebot account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config gamebot adminchan #game
  writeini -n %mServices.config gamebot chan #game
}

alias ms.gamebot.remconfig { writeini -n %mServices.config configured gamebot false | remini %mServices.config gamebot }

alias ms.start.gamebot {
  if ( %mServices.loaded.gamebot == true ) && ( $ms.config.get(configured,gamebot) == true ) { 
    var %ms.gb.bot $ms.config.get(load,gamebot)
    ms.echo blue [mServices mIRC Services] Launching gamebot: %ms.gb.bot

    ; Setting permanent variables because i think i'm going to use them a lot and it's easier to use.
    ;set %ms.gb. $+ %ms.gb.bot $+ .numeric $ms.config.get(numeric,%ms.gb.bot)
    ;set %ms.gb. $+ %ms.gb.bot $+ .nick $ms.config.get(nick,%ms.gb.bot)
    ;set %ms.gb. $+ $ms.config.get(numeric,%ms.gb.bot) $ms.config.get(nick,%ms.gb.bot)

    ms.servicebot.spawn $ms.config.get(nick,%ms.gb.bot) $ctime $ms.config.get(user,%ms.gb.bot) $ms.config.get(host,%ms.gb.bot) $ms.config.get(modes,%ms.gb.bot) $ms.config.get(account,%ms.gb.bot) $ms.config.get(ip,%ms.gb.bot) $ms.config.get(numeric,%ms.gb.bot) $ms.config.get(realname,%ms.gb.bot)
    ms.servicebot.join $ms.config.get(numeric,%ms.gb.bot) $ms.config.get(adminchan,%ms.gb.bot)
  }
}

alias ms.stop.gamebot { 
  if ( %mServices.loaded.gamebot == true ) && ( $ms.config.get(configured,gamebot) == true ) { 
    ms.servicebot.despawn $ms.config.get(numeric,gamebot)
  }
}

alias ms.gamebot.privmsg {
  set %ms.gb.nick $1
  set %ms.gb.chan $2
  set %ms.gb.msg $remove($3,:) $4-
  ms.gb.3row %ms.gb.nick %ms.gb.chan %ms.gb.msg
  ms.gb.magic %ms.gb.nick %ms.gb.chan %ms.gb.msg
  return
}
