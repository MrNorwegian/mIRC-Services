on *:unload:{ 
  sockclose mServices 
  unload -rs scripts/mIRC-Services/mServices_conf.mrc
  unload -rs scripts/mIRC-Services/mServices_base64.mrc
  unload -rs scripts/mIRC-Services/mServices_commands.mrc
  ; Optional modules
  unload -rs scripts/mIRC-Services/mServices_fishbot.mrc
  unload -rs scripts/mIRC-Services/mServices_spybot.mrc
  ; load -rs scripts/mIRC-Services/mServices_banana.mrc
  ; load -rs scripts/mIRC-Services/mServices_chanfix.mrc
  ; load -rs scripts/mIRC-Services/mServices_operserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_nickserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_chanserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_gnuworldX.mrc
  ; load -rs scripts/mIRC-Services/mServices_newservQ.mrc
  ; load -rs scripts/mIRC-Services/mServices_newservL.mrc
  ; TODO remove db files if any
  ms.echo green Finished unloaded modules
}
on *:load:{ 
  load -rs scripts/mIRC-Services/mServices_conf.mrc
  load -rs scripts/mIRC-Services/mServices_base64.mrc
  load -rs scripts/mIRC-Services/mServices_commands.mrc
  ; Optional modules
  load -rs scripts/mIRC-Services/mServices_fishbot.mrc
  load -rs scripts/mIRC-Services/mServices_spybot.mrc
  ; load -rs scripts/mIRC-Services/mServices_banana.mrc
  ; load -rs scripts/mIRC-Services/mServices_chanfix.mrc
  ; load -rs scripts/mIRC-Services/mServices_operserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_nickserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_chanserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_gnuworldX.mrc
  ; load -rs scripts/mIRC-Services/mServices_newservQ.mrc
  ; load -rs scripts/mIRC-Services/mServices_newservL.mrc
  ms.echo green Finished loaded modules
}

on *:sockclose:mServices:{ ms.echo orange [Sockclose] $sockname closed }
on *:sockopen:mServices:{
  if ($sockerr > 0) {
    ms.echo orange [Sockopen] Failed to open $sockname ( $sockerr )
    return
  }
  ms.db.reset 
  set %ms.numeric $inttobase64($mServices.config(numeric),2)
  mServices.raw PASS $+(:,$mServices.config(password))
  mServices.raw SERVER $mServices.config(serverName) 1 $ctime $ctime J10 $+(%ms.numeric,$inttobase64(64,3)) $mServices.config(flags) $+(:,$mServices.config(info))

  ; Here burst where the bots if any should have op, this excludes hack4 messages for opers

  ; Sending END_OF_BURST
  mServices.raw %ms.numeric EB
  ms.echo green Server is now connected with serverName $mServices.config(serverName) ( %ms.numeric )

}
on *:sockread:mServices:{
  var %mServices.sockRead = $null
  sockread %mServices.sockRead
  tokenize 32 %mServices.sockRead

  if ($sockerr > 0) {
    ms.echo red [Sockread] : $sockname closed due to error ( $sockerr )
    sockclose $sockname
  }
  if ( $mServices.config(rawdebug) == true ) { ms.echo orange [Sockread Server] --> $1- }

  ; Acknowledge the end of burst
  if ($istok(EB EOB_ACK,$2,32) == $true) {
    mServices.sraw EA
    return
  }

  ; Receive Acknowledge the end of burst
  if ($istok(EA,$2,32) == $true) {
    .timer_load_spybot 1 1 ms.load.spybot
    .timer_load_fishbot 1 4 ms.load.fishbot
    return
  }

  ; <PASS> :<password>
  if ($istok(PASS,$1,32) == $true) { return }

  ; <SERVER> <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<description>
  elseif ($istok(SERVER,$1,32) == $true) {
    ms.newserver $2-
    return
  }

  ; <server numeric> <S|SERVER> <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<description>
  elseif ($istok(S SERVER,$2,32) == $true) {
    ; In the future, send $1, first numeric is sending this message, for now it's not important
    ms.newserver $3-
    return
  }
  
  ; <numeric> <SQ|SQUIT> <server name> <time> :<reason>
  elseif ($istok(SQ SQUIT,$2,32) == $true) {
    ; TODO remove clients connected to this server
    return
  }
  ; <server numeric> <N|NICK> <nick> <hop count> <timestamp> <user> <host> <modes> <base64 ip> <clientnumeric> :<real name>
  elseif ($istok(N NICK,$2,32) == $true) {
    ; Note to self server numeric ($1) is what server the client is on
    ; This also applies to nickchanges
    ms.newclient $1-
    return
  }

  ; <server numeric> <B|BURST> <chan> <createtime??> <+chanmodes> BbACg,AoAAH,AzAAE,ABAAv:o,BWAAA,AzAAC,AzAAA,BdAAA
  elseif ($istok(B BURST,$2,32) == $true) {
    ms.burstchannels $3-
    return
  }

  ; <client numeric> <C|CREATE> <channel> <timestamp>
  elseif ($istok(C CREATE,$2,32) == $true) {
    return
  }

  ; <client numeric> <J|JOIN> <channel> <timestamp>
  elseif ($istok(J JOIN,$2,32) == $true) {
    ms.client.join $1 $3 $4
  }

  ; <client numeric> <L|LEAVE> <channel> :<reason>
  elseif ($istok(L PART,$2,32) == $true) {
    ms.client.part $1 $3 $4
  }

  ; <client numeric> <M|MODE> <channel> <modes> <params\client numerics>
  elseif ($istok(M MODE,$2,32) == $true) {
    return
  }

  ; <client numeric> <K|KICK> <channel> <kicked client numeric> :reason
  elseif ($istok(K KICK,$2,32) == $true) {
    if ( %mServices.fishbot.loaded == true ) && ( $4 == %ms.fishbot.numeric ) { 
      ms.fishbot.kicked $3
    }
    return
  }

  ; <client numeric> <P|Privmsg> <targetchan\targetclient numeric> :<message>
  elseif ($istok(P PRIVMSG,$2,32) == $true) {
    if ( %mServices.fishbot.loaded == true ) && ( $istok(%ms.fishbot.channels,$3,44) ) { 
      ms.fishbot.text $1-
    }
    elseif ( %mServices.fishbot.loaded == true ) && ( %ms.fishbot.numeric == $3 ) { 
      ms.spybot.privmsg $1-
    }
    return
  }
  ; <client numeric> <I|INVITE> <target nick> <target chan> <someID>
  elseif ($istok(I INVITE,$2,32) == $true) {
    if ( %mServices.fishbot.loaded == true ) { 
      ms.fishbot.invite $1 $3 $4
    }
    return
  }
  ; <client numeric> <Q|QUIT> :<reason>
  elseif ($istok(Q QUIT,$2,32) == $true) {
    return
  }

  ; <numeric> <F|INFO> <server numeric>
  elseif ($istok(F INFO,$2,32) == $true) {
    mServices.sraw 371 $1 $+(:,$mServices.config(serverName))
    mServices.sraw 371 $1 $+(:,$mServices.config(info))
    mServices.sraw 374 $1 :End of /INFO list.
    return
  }

  ; <numeric> <G|PING> [:]<arg>
  elseif ($istok(G PING,$2,32) == $true) {
    mServices.sraw Z $3-
    return
  }

  ; <numeric> MO[TD] <server numeric>
  elseif ($istok(MO MOTD,$2,32) == $true) {
    mServices.sraw 422 $1 :MOTD File is missing
    return
  }

  ; <numeric> RI|V|R <server numeric> ; This is just som misc stuff
  elseif ($istok(RI V R A,$2,32) == $true) { return }

  ; <client numeric> W|WHOIS <target numeric> :<target nick> ; this is called when a user /whois nick nick for extended whois
  elseif ( $istok(W,$2,32) == $true ) {
    return
  }
  ; <numeric> TI[ME] <server numeric> BWAAA 1728383433 29005 :<No client start time>
  elseif ($istok(TI TIME,$2,32) == $true) {
    mServices.sraw 391 $1 $mServices.config(serverName) $ctime 0 $+(:,$asctime($ctime,dddd mmmm dd yyyy -- HH:nn:ss))
    return
  }
  else {
    ms.echo red [Sockread] Unknown command received: $1-
  }
}