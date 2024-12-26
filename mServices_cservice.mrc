on *:load: { set %mServices.loaded.cservice true | ms.echo green Loaded mServices_cservice.mrc }
on *:unload: { unset %mServices.loaded.cservice | ms.echo red Unloaded mServices_cservice.mrc }

alias ms.cservice.makeconfig {

  ; ACCOUNT can be disabled by setting it to CHANGE_ME_TO_ENABLE

  writeini -n %mServices.config cservice configured false
  writeini -n %mServices.config cservice load cservice

  writeini -n %mServices.config cservice numeric AAA
  writeini -n %mServices.config cservice nick X
  writeini -n %mServices.config cservice user cservice
  writeini -n %mServices.config cservice host example.org
  writeini -n %mServices.config cservice ip 127.0.0.1
  writeini -n %mServices.config cservice realname /msg X help
  writeini -n %mServices.config cservice modes +k
  writeini -n %mServices.config cservice account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config cservice adminchan #admin
}

alias ms.cservice.remconfig { writeini -n %mServices.config configured cservice false | remini %mServices.config cservice }

alias ms.start.cservice {
  if ( %mServices.loaded.cservice == true ) && ( $ms.config.get(configured,cservice) == true ) { 
    var %ms.cs.bot $ms.config.get(load,cservice)
    ms.echo blue [mServices mIRC Services] Launching cservice: %ms.cs.bot

    ms.servicebot.spawn $ms.config.get(nick,%ms.cs.bot) $ctime $ms.config.get(user,%ms.cs.bot) $ms.config.get(host,%ms.cs.bot) $ms.config.get(modes,%ms.cs.bot) $ms.config.get(account,%ms.cs.bot) $ms.config.get(ip,%ms.cs.bot) $ms.config.get(numeric,%ms.cs.bot) $ms.config.get(realname,%ms.cs.bot)
    ms.servicebot.join $ms.config.get(numeric,%ms.cs.bot) $ms.config.get(adminchan,%ms.cs.bot)
  }
}

alias ms.stop.cservice { 
  if ( %mServices.loaded.cservice == true ) && ( $ms.config.get(configured,cservice) == true ) { 
    ms.servicebot.despawn $ms.config.get(numeric,cservice)
  }
}

alias ms.cservice.privmsg { 
  return
}