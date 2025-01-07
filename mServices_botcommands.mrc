on *:load: { set %mServices.loaded.botcommands true | ms.echo green Loaded mServices_botcommands.mrc }
on *:unload: { unset %mServices.loaded.botcommands | ms.echo red Unloaded mServices_botcommands.mrc }

alias ms.servicebot.picknumeric { 
  var %tmpnumeric %ms.servicebot.numeric
  return $+($inttobase64($mServices.config(numeric),2),$inttobase64(%tmpnumeric,3)) 
}

; /ms.start.servicebots cservice,spybot,funbots
alias ms.start.servicebots { 
  var %ms.start.sb $numtok($1,44)
  while ( %ms.start.sb ) { 
    ms.start. $+ $gettok($1,%ms.start.sb,44)
    set %ms.status linked starting $gettok($1,%ms.start.sb,44)
    dec %ms.start.sb
  }
  set %ms.status linked finished
}

; /ms.stop.servicebots cservice,spybot,funbots
alias ms.stop.servicebots { 
  var %ms.stop.sb $numtok($1-,44)
  while ( %ms.stop.sb ) { 
    ms.stop. $+ $gettok($1-,%ms.stop.sb,44)
    dec %ms.stop.sb
  }
}

alias ms.servicebot.spawn {
  if ( $ms.db(read,c,$7) ) { ms.echo red [Service bot] $1 is already spawned, skipping. | return }
  else {
    ms.echo green [Service bot] Spawn $7 $+($1,!,$3,@,$4,$chr(32)) Auth: $6 Ip: $7 with modes: $8
    mServices.sraw N $1 1 $2 $3 $4 $5 $inttobase64($longip($7),6) $8 $+(:,$9-)
    ms.newclient $inttobase64($mServices.config(numeric),2) N $1 1 $2 $3 $4 $5 $inttobase64($longip($7),6) $8 $+(:,$9-)
    if ( $6 != CHANGE_ME_TO_ENABLE ) { 
      mServices.sraw AC $8 $replace($6,:,$chr(32))
      ms.account %ms.numeric AC $8 $replace($6,:,$chr(32))
    }

    set %ms.servicebots.online $addtok(%ms.servicebots.online,$1,44)
  }
}

alias ms.servicebot.despawn {
  if ($ms.db(read,c,$1)) { 
    ms.echo green [Service bot] Despawn $1
    mServices.raw $1 Q :Service bot is leaving the server
    ms.client.quit $1 Service bot is leaving the server
    set %ms.servicebots.online $remtok(%ms.servicebots.online,$1,44)
  }
  else { ms.echo red [Service bot] $1 is not spawned, skipping. | return }
}

; Add\remove channels from the bot (public channels, so channels the bots have been invited or joined by regular users)
alias ms.servicebot.addchan { 
  if ( $2 ) { 
    writeini -n %mServices.config $1 channels $addtok($ms.config.get(channels,$1),$2,44)
  }
}
alias ms.servicebot.remchan { 
  if ( $2 ) { 
    if ( $numtok($ms.config.get(channels,$1),44) >= 1 ) { writeini -n %mServices.config $1 channels $remtok($ms.config.get(channels,$1),$2,44) }
    else { remini %mServices.config $1 channels }
  }
}

; ms.servicebot.say <numeric> <target> <message>
; For some reason, the mirc craches when using mServices.raw here
; mServices.raw $1 P $2 : $+ $3-
alias ms.servicebot.say {
  if ( $3 ) { sockwrite -nt mServices $1 P $2 : $+ $3- }
}

alias ms.servicebot.notice {
  if ( $3 ) { sockwrite -nt mServices $1 NOTICE $2 : $+ $3- }
}

alias ms.servicebot.join { 
  if ( $numtok($2,44) >= 2 ) {
    var %c $numtok($2,44)
    while ( %c ) { 
      if ( $istok($ms.db(read,l,$1),$gettok($2,%c,44),32) ) { 
        ms.echo red [Servicebot join] $1 is already in $gettok($2,%c,44), skipping.
      }
      else { 
        mServices.raw $1 J $gettok($2,%c,44) $ctime
        ms.client.join $1 $gettok($2,%c,44) $ctime
      }
      dec %c
    } 
  }
  else { 
    mServices.raw $1 J $2 $ctime
    ms.client.join $1 $2 $ctime
  }
}

; Passing p10 messages to modules

; <client numeric> <target nick> <target chan>
alias ms.servicebot.invited {
  if ( %mServices.loaded.funbots ) { ms.funbots.invited $1- }
}

; client numeric> <channel> <target numeric>
alias ms.servicebot.kicked {
  ; Need to another way to check if kicked bot is a funbot,gamebot or servicebot like spybot,x,euworld what cannot be kicked but was
  if ( %mServices.loaded.funbots ) { 
    if ( $istok(%ms.servicebots.online,$ms.get.client(nick,$3),44) ) { ms.funbots.kicked $1- }
  }
}

; <client numeric> <target srvnum> <target nick>
alias ms.servicebot.whois {
  var %ms.sbwh.num $ms.get.client(numeric,$3)
  mServices.sraw 311 $1 $3 $ms.get.client(ident,%ms.sbwh.num) $ms.get.client(host,%ms.sbwh.num) * $ms.get.client(realname,%ms.sbwh.num)
  ; Move this to %mServices_funbots.mrc ? Showing channels of the bot
  if ( $istok(%ms.funbots.online,%tnum,44) ) { 
    mServices.sraw 319 $1 $3 $replace($ms.get.client(channels,%ms.sbwh.num),$chr(44),$chr(32))
  }
  mServices.sraw 312 $1 $3 $ms.get.server(name,$ms.get.client(server,%ms.sbwh.num)) $ms.get.server(desc,$ms.get.client(server,%ms.sbwh.num)) 
  ; mServices.sraw 313 $1 %tnick :is an IRC Services bot
  if ( $ms.get.client(account,%ms.sbwh.num) != CHANGE_ME_TO_ENABLE ) { 
    mServices.sraw 330 $1 $3 $v1 :is logged in as
  }
  mServices.sraw 317 $1 $3 0 $ms.get.client(timestamp,%ms.sbwh.num) :seconds idle, signon time
  mServices.sraw 318 $1 $3 :End of /WHOIS list.
}

; <server numeric> <client numeric> <account id>
alias ms.servicebot.p10.account { 
  if ( %mServices.loaded.spybot == true ) { ms.spybot.report AC $1- }
}

; 
alias ms.servicebot.p10.srvcreated { 
  if ( %mServices.loaded.spybot == true ) { ms.spybot.report S $1- }
}

; <client numeric> <target chan>
alias ms.servicebot.p10.chcreated { 
  if ( %mServices.loaded.spybot == true ) { ms.spybot.report C $1- }
}

; <client numeric> <target chan>
alias ms.servicebot.p10.chjoined { 
  if ( %mServices.loaded.spybot == true ) { ms.spybot.report J $1- }
}

; <target numeric> <target chan> [kicked <client numeric> <reason>]
alias ms.servicebot.p10.chparted { 
  if ( %mServices.loaded.spybot == true ) { 
    if ( $3 != kicked ) { ms.spybot.report L $1- }
    else { ms.spybot.report K $1- }
  }
}

; <client numeric> <target client numeric> <modes>
alias ms.servicebot.p10.clientmode { 
  if ( %mServices.loaded.spybot == true ) { ms.spybot.report M $1- }
}

; <client numeric> <target client numeric> <modes> <nick1 nick2 etc> <timestamp>
alias ms.servicebot.p10.chanmode { 
  if ( %mServices.loaded.spybot == true ) { ms.spybot.report M $1- }
}

; <client numeric> <targetchan\targetclient numeric> :<message>
alias ms.servicebot.p10.privmsg { 
  if ( $3 == $+(:,$chr(1),VERSION,$chr(1)) ) { ms.servicebot.notice $2 $1 $+($chr(1),VERSION,$chr(1)) msl-Services alpha v0.00000001 by naka }
  if ( $3 == $+(:,$chr(1),PING) ) { ms.servicebot.notice $2 $1 $+($chr(1),PING $4,$chr(1)) }
  else {
    if ( %mServices.loaded.funbots == true ) { ms.funbots.privmsg $1- }
    if ( %mServices.loaded.gamebot == true ) { ms.gamebot.privmsg $1- }
    if ( %mServices.loaded.spybot == true ) { ms.spybot.privmsg $1- } 
    if ( %mServices.loaded.cservice == true ) { ms.cservice.privmsg $1- }
  }
}