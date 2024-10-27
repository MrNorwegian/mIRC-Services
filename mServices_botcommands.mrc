on *:load: { set %mServices.botcommands.loaded true | ms.echo green Loaded mServices_botcommands.mrc }
on *:unload: { unset %mServices.botcommands.loaded | ms.echo red Unloaded mServices_botcommands.mrc }

alias ms.load.servicebot { 
  var %lsb $numtok($1,44)
  while ( %lsb ) { 
    ms.load. $+ $gettok($1,%lsb,44)
    dec %lsb
  }
}
alias ms.servicebot.spawn {
  if ( $ms.db(read,c,$1,numeric) ) { ms.echo red [Service bot] $1 is already spawned, skipping. | return }
  else {
    ms.echo green [Service bot] Spawn $7 $+($1,!,$3,@,$4,$chr(32),:,$7,$chr(32)) Ip: $6 with modes: $5
    mServices.sraw N $1 1 $2 $3 $4 $5 $inttobase64($longip($6),6) $7 $+(:,$8)
    ms.newclient $inttobase64($mServices.config(numeric),2) N $1 1 $2 $3 $4 $5 $inttobase64($longip($6),6) $7 $+(:,$8)
  }
}

alias ms.servicebot.despawn {
  if ($ms.db(read,c,$1,nick)) { 
    ms.echo green [Service bot] Despawn $1
    mServices.raw $1 Q :Service bot is leaving the server
    ms.client.quit $1 Service bot is leaving the server
  }
  else { ms.echo red [Service bot] $1 is not spawned, skipping. | return }
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
;%ms.fishbot.numeric
; <client numeric> <servicebot numeric> <channel>
alias ms.servicebot.invited {
  var %ms.sb.clientnum $1
  var %ms.sb.chan $3
  var %ms.sb.num %ms. [ $+ [ $2 ] ] [ $+ [ .numeric ] ]
  var %ms.sb.chans %ms. [ $+ [ $2 ] ] [ $+ [ .channels ] ]
  if ($istok(%ms.sb.chans,%ms.sb.num,44)) { ms.servicebot.join %ms.sb.num %ms.sb.chan }
  else { set %ms. [ $+ [ $2 ] ] [ $+ [ .channels ] ] $addtok(%ms.sb.chans,%ms.sb.chan,44) | ms.servicebot.join %ms.sb.num %ms.sb.chan }
  echo -a DEBUG $1- %ms.sb.num
}

; <kicked numeric> <channel>
alias ms.servicebot.kicked {
  var %ms.sb.nick $gettok($gettok($ms.db(read,c,$1),2,44),2,32)
  var %ms.sb.chans %ms. [ $+ [ %ms.sb.nick ] ] [ $+ [ .channels ] ]
  if ($istok(%ms.sb.chans,$2,44)) { set %ms. [ $+ [ %ms.sb.nick ] ] [ $+ [ .channels ] ] $remtok(%ms.sb.chans,$2,44) }
}

; placeholder, this two aliases are going to be used for text and command response of the bots 
alias ms.servicebot.text { return }
alias ms.servicebot.privmsg { return }