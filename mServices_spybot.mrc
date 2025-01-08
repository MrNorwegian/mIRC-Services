on *:load: { set %mServices.loaded.spybot true | ms.echo green Loaded mServices_spybot.mrc }
on *:unload: { unset %mServices.loaded.spybot | ms.echo red Unloaded mServices_spybot.mrc }

alias ms.spybot.makeconfig {

  ; ACCOUNT can be disabled by setting it to CHANGE_ME_TO_ENABLE

  writeini -n %mServices.config spybot configured false
  writeini -n %mServices.config spybot load spybot

  writeini -n %mServices.config spybot numeric AAB
  writeini -n %mServices.config spybot nick spybot
  writeini -n %mServices.config spybot user spybot
  writeini -n %mServices.config spybot host is.here.to.spy.on.you
  writeini -n %mServices.config spybot ip 127.0.0.1
  writeini -n %mServices.config spybot realname Nothing to see here
  writeini -n %mServices.config spybot modes +ki
  writeini -n %mServices.config spybot account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config spybot chan #spychan
  writeini -n %mServices.config spybot debugchan #debug
  writeini -n %mServices.config spybot debug false
  writeini -n %mServices.config spybot report true
}

alias ms.spybot.remconfig { writeini -n %mServices.config configured spybot false | remini %mServices.config spybot }

alias ms.sb.get { 
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
    ; debug and report are used alot, so we cache them in variables
    if ( $1 == chan ) { 
      if ( %ms.spybot.chan ) { return $v1 } 
      else { set %ms.spybot.chan $readini(%mServices.config,$2,chan) | return %ms.spybot.chan }
    }
    if ( $1 == debugchan ) { 
      if ( %ms.spybot.debugchan ) { return $v1 } 
      else { set %ms.spybot.debugchan $readini(%mServices.config,$2,debugchan) | return %ms.spybot.debugchan }
    }
    if ( $1 == debug ) { 
      if ( %ms.spybot.debug ) { return $v1 } 
      else { set %ms.spybot.debug $readini(%mServices.config,$2,debug) | return %ms.spybot.debug }
    }
    if ( $1 == report ) { 
      if ( %ms.spybot.report ) { return $v1 } 
      else { set %ms.spybot.report $readini(%mServices.config,$2,report) | return %ms.spybot.report }
    }
  }
}


alias ms.start.spybot {
  if ( %mServices.loaded.spybot == true ) && ( $readini(%mServices.config,spybot,configured) == true ) { 
    var %ms.sb.bot $ms.config.get(load,spybot)
    ms.echo blue [mServices mIRC Services] Launching spybot: %ms.sb.bot

    ; Setting permanent variables because i think i'm going to use them a lot and it's easier to use.
    set %ms.sb. $+ %ms.sb.bot $+ .numeric $ms.sb.get(numeric,%ms.sb.bot)
    set %ms.sb. $+ %ms.sb.bot $+ .nick $ms.sb.get(nick,%ms.sb.bot)
    set %ms.sb. $+ $ms.sb.get(numeric,%ms.sb.bot) $ms.sb.get(nick,%ms.sb.bot)

    ms.servicebot.spawn $ms.config.get(nick,%ms.sb.bot) $ctime $ms.config.get(user,%ms.sb.bot) $ms.config.get(host,%ms.sb.bot) $ms.config.get(modes,%ms.sb.bot) $ms.config.get(account,%ms.sb.bot) $ms.config.get(ip,%ms.sb.bot) $ms.config.get(numeric,%ms.sb.bot) $ms.config.get(realname,%ms.sb.bot)
    ms.servicebot.join $ms.sb.get(numeric,%ms.sb.bot) $+($ms.sb.get(chan,%ms.sb.bot),$chr(44),$ms.sb.get(debugchan,%ms.sb.bot))
  }
}

alias ms.stop.spybot { 
  if ( %mServices.loaded.spybot == true ) && ( $readini(%mServices.config,spybot,configured) == true ) { 
    ms.servicebot.despawn %ms.spybot.numeric 
  }
}

alias ms.spybot.report { 
  ; remember: %ms.status 
  ; %spr. == spybotreport * note to self *
  if ( $istok(%ms.servicebots.online,%ms.sb.spybot.nick,44)) && ( $ms.sb.get(report,spybot) == true ) && ( %ms.status == linked finished ) {

    ; S %ms.ns.num %ms.ns.name %ms.ns.hop %ms.ns.starttime %ms.ns.linktime %ms.ns.protocol %ms.ns.maxcon %ms.ns.flags %ms.ns.desc
    if ( $1 === S ) { 
      return
    }

    ; N %ms.nc.num %ms.nc.nick %ms.nc.hopcount %ms.nc.timestamp %ms.nc.user %ms.nc.host %ms.nc.modes %ms.nc.auth %ms.nc.base64ip %ms.nc.num %ms.nc.realname
    elseif ( $1 === N ) { 
      ; TODO, remove network.domain from spr.sn
      var %spr.sn $+($chr(91),$gettok($gettok($ms.db(read,s,$2),1,44),2,32),$chr(93)) 
      var %spr.cn $3
      var %spr.idhost $+($chr(40),$6,@,$7,$chr(41))
      var %spr.base64ip $+($chr(91),$base64toip($10),$chr(93))
      ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(chan,spybot) User $ms.orange(%spr.cn %spr.idhost) %spr.base64ip * $12- Connected to $ms.yellow(%spr.sn)
      return
    }

    ; AC
    elseif ( $1 === AC ) { 
      return
    }

    ; C clientnum channel
    elseif ( $1 === C ) { 
      var %spr.cn $ms.get.client(nick,$2) $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
      var %spr.ch $3
      ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(chan,spybot) User %spr.cn created channel: %spr.ch
      return
    }
    ; J %ms.cj.num %ms.cj.chan
    elseif ( $1 === J ) { 
      var %spr.jn $ms.get.client(nick,$2) $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
      var %spr.ch $3
      ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(chan,spybot) User %spr.jn joined channel: %spr.ch
      return
    }
    ; L %ms.cl.num %ms.cl.chan
    elseif ( $1 === L ) && ( %ms.client.part.quiet. [ $+ [ $2 ] ] != true ) { 
      var %spr.pn $ms.get.client(nick,$2)  $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
      var %spr.ch $3
      ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(chan,spybot) User %spr.pn parted channel: %spr.ch
      return
    }
    ; Q clientnum reason
    elseif ( $1 === Q ) { 
      var %spr.sn $+($chr(91),$ms.get.server(name,$ms.get.client(server,$2)),$chr(93)) 
      var %spr.cn $ms.get.client(nick,$2)
      var %spr.idhost $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
      var %spr.base64ip $+($chr(91),$base64toip($ms.get.client(base64ip,$2)),$chr(93))
      ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(chan,spybot) User $ms.orange(%spr.cn %spr.idhost) %spr.base64ip * $ms.get.client(realname,$2) Disconnected from $ms.yellow(%spr.sn) With reason: $3-
      return
    }
    ; K %ms.ck.num %ms.ck.chan %ms.ck.reason
    ; <client numeric> <K|KICK> <channel> <target nicknumeric> :reason
    ; K num chan kicked bynum reason
    elseif ( $1 === K ) { 
      var %spr.kn $ms.get.client(nick,$2) $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
      var %spr.chan $3
      var %spr.kby $ms.get.client(nick,$5) $+($chr(40),$ms.get.client(ident,$5),@,$ms.get.client(host,$5),$chr(41))
      ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(chan,spybot) User %spr.kn was kicked from %spr.chan by %spr.kby with reason: $6-
      return
    }

    ; M <client numeric> <channel> <+-modes> <arg1 arg2 arg3 arg4 etc> <timestamp>
    elseif ( $1 === M ) && ($5) {  
      var %spr.mnum $2
      var %spr.mnick $ms.get.client(nick,$2)
      var %spr.midhost $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
      var %spr.mchan $3
      var %spr.mmodes $4

      ; Removing "timestamp" from args and saving it to own variable
      var %spr.mc.i $numtok($4-,32)
      var %spr.mc.x 1
      while ( %spr.mc.i > %spr.mc.x ) {
        if ( $gettok($5-,%spr.mc.x,32) = 1000000000 ) { var %spr.mtimestamp $gettok($5-,%spr.mc.x,32) }
        elseif ( $ms.get.client(nick,$gettok($5-,%spr.mc.x,32)) ) { var %spr.margs $addtok(%spr.margs,$v1,32) }
        else { var %spr.mextraargs $addtok(%spr.mextraargs,$gettok($5-,%spr.mc.x,32),32) }
        inc %spr.mc.x
      }
      ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(chan,spybot) User %spr.mnick %spr.midhost set modes: %spr.mmodes %spr.margs $iif(%spr.mextraargs,Args: %spr.mextraargs,$null) in %spr.mchan
      return
    }
    ; M <client numeric> <target nick> <modes>
    elseif ( $1 === M ) && (!$5) {  
      var %spr.mnum $2
      var %spr.mnick $3
      var %spr.midhost $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
      var %spr.mnewmodes $ms.get.client(modes,$2)
      var %spr.mmodes $4
      ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(chan,spybot) User %spr.mnick %spr.midhost set modes: %spr.mmodes $+($chr(40),%spr.mnewmodes,$chr(41))
      return
    }
  }
}

; Spybot debug channel reporting
alias ms.spybot.debug { 
  if ( $ms.sb.get(report,spybot) == true ) && ( %ms.status == linked finished ) { 
    ms.servicebot.say %ms.sb.spybot.numeric $ms.sb.get(debugchan,spybot) $1-
  }
}

; Spybot privmsg and channel commands
alias ms.spybot.privmsg { 
  return
}
