on *:load: { set %mServices.loaded.botcommands true | ms.echo green Loaded mServices_botcommands.mrc }
on *:unload: { unset %mServices.loaded.botcommands | ms.echo red Unloaded mServices_botcommands.mrc }

alias ms.servicebot.picknumeric { 
  var %tmpnumeric %ms.servicebot.numeric
  inc %ms.client.numeric
  return $+($inttobase64($mServices.config(numeric),2),$inttobase64(%tmpnumeric,3)) 
}

alias ms.start.servicebots { 
  var %ms.start.sb $numtok($1,44)
  while ( %ms.start.sb ) { 
    ms.start. $+ $gettok($1,%ms.start.sb,44)
    dec %ms.start.sb
  }
}
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
    ms.echo green [Service bot] Spawn $7 $+($1,!,$3,@,$4,$chr(32)) Ip: $6 with modes: $5
    mServices.sraw N $1 1 $2 $3 $4 $5 $inttobase64($longip($6),6) $7 $+(:,$8-)
    ms.newclient $inttobase64($mServices.config(numeric),2) N $1 1 $2 $3 $4 $5 $inttobase64($longip($6),6) $7 $+(:,$8-)

    if ( $mServices.config(ac,$1) != CHANGE_ME_TO_ENABLE ) { mServices.sraw AC %ms. [ $+ [ $1 ] ] [ $+ [ .numeric ] ] $v1 }
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

alias ms.servicebot.say {
  if ( $3 ) {
    sockwrite -nt mServices $1 P $2 : $+ $3-
  }
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
  if ( %mServices.loaded.funbots ) { ms.funbots.kicked $1- }
}

; <client numeric> <target srvnum> <target nick>
alias ms.servicebot.whois {
  var %tnick $3
  var %tnum %ms.fb. [ $+ [ $3 ] ] [ $+ [ .numeric ] ]
  mServices.sraw 311 $1 %tnick $mServices.config(user,%tnick) $mServices.config(host,%tnick) * $mServices.config(realname,%tnick)
  ; Move this to %mServices_funbots.mrc ? Showing channels of the bot
  if ( $istok(%ms.funbots.online,%tnum,44) ) { 
    mServices.sraw 319 $1 %tnick $replace($mServices.config(channels,%tnick),$chr(44),$chr(32))
  }
  mServices.sraw 312 $1 %tnick $mServices.config(serverName,%tnick) $mServices.config(info,%tnick)
  ; mServices.sraw 313 $1 %tnick :is an IRC Services bot
  if ( $mServices.config(ac,%tnick) != CHANGE_ME_TO_ENABLE ) { 
    mServices.sraw 330 $1 %tnick $v1 :is logged in as
  }
  mServices.sraw 317 $1 %tnick 0 %ms.startime :seconds idle, signon time
  mServices.sraw 318 $1 %tnick :End of /WHOIS list.
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
; <client numeric> <targetchan\targetclient numeric> :<message>
alias ms.servicebot.privmsg { 
  if ( %mServices.loaded.funbots == true ) { ms.funbots.privmsg $1- }
  if ( %mServices.loaded.spybot == true ) { ms.spybot.privmsg $1- } 
}