on *:unload:{ 
  sockclose mServices 
  unload -rs scripts/mIRC-Services/mServices_conf.mrc
  unload -rs scripts/mIRC-Services/mServices_base64.mrc
  unload -rs scripts/mIRC-Services/mServices_commands.mrc
  unload -rs scripts/mIRC-Services/mServices_botcommands.mrc
  ; Optional modules
  unload -rs scripts/mIRC-Services/mServices_fishbot.mrc
  unload -rs scripts/mIRC-Services/mServices_spybot.mrc
  ; unload -rs scripts/mIRC-Services/mServices_chanfix.mrc
  ; unload -rs scripts/mIRC-Services/mServices_operserv.mrc
  ; unload -rs scripts/mIRC-Services/mServices_nickserv.mrc
  ; unload -rs scripts/mIRC-Services/mServices_chanserv.mrc
  ; unload -rs scripts/mIRC-Services/mServices_gnuworldX.mrc
  ; unload -rs scripts/mIRC-Services/mServices_newservQ.mrc
  ; unload -rs scripts/mIRC-Services/mServices_newservL.mrc
  ; TODO remove db files if any
  ms.echo green Finished unloaded modules
}
on *:load:{ 
  load -rs scripts/mIRC-Services/mServices_conf.mrc
  load -rs scripts/mIRC-Services/mServices_base64.mrc
  load -rs scripts/mIRC-Services/mServices_commands.mrc
  load -rs scripts/mIRC-Services/mServices_botcommands.mrc
  ; Optional modules
  load -rs scripts/mIRC-Services/mServices_fishbot.mrc
  load -rs scripts/mIRC-Services/mServices_spybot.mrc
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
  var %ms.maxcon $inttobase64($mServices.config(maxcon),3)
  set %ms.startime $ctime

  ms.echo blue [mServices mIRC Server] Connecting to $mServices.config(serverName) ( %ms.numeric )
  mServices.raw PASS $+(:,$mServices.config(password))
  mServices.raw SERVER $mServices.config(serverName) 1 %ms.startime $ctime P10 $+(%ms.numeric,%ms.maxcon) $mServices.config(flags) $+(:,$mServices.config(info))

  ; Here burst the bots, chans and modes (remember that timestamp must be modified)

  ; Sending END_OF_BURST
  mServices.sraw EB
  ms.echo blue [mServices mIRC Server] Sendt end of burst, waiting for response

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

  ; Sending Acknowledge the end of burst
  if ($istok(EB EOB_ACK,$2,32) == $true) && ( %ms.myhub == $1 ) {
    mServices.sraw EA
    ms.echo blue [mServices mIRC Server] Received response with EB and sending EA
    return
  }

  ; Received Acknowledge the end of burst
  if ($istok(EA,$2,32) == $true) && ( %ms.myhub == $1 ) {
    ms.echo blue [mServices mIRC Server] Received Acknowledge the end of burst
    ms.echo blue [mServices mIRC Server] Starting to load services
    ; TODO: make /ms.load.servicebot <fishbot|spybot|banana> 
    ms.load.spybot
    ms.load.fishbot
    ms.load.banana
    return
  }

  ; <PASS> :<password>
  if ($istok(PASS,$1,32) == $true) { 
    ; TODO: check if password is correct
  }

  ; <server numeric> <S|SERVER> <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<description>
  elseif ($istok(S SERVER,$2,32) == $true) || ($istok(SERVER,$1,32) == $true) {
    ; TODO: check if server name is correct and server numeric doesnt crash
    ms.echo blue [mServices mIRC Server] Received response with SERVER
    ms.newserver $1-
    return
  }

  ; <numeric> <SQ|SQUIT> <server name> <time> :<reason>
  elseif ($istok(SQ SQUIT,$2,32) == $true) {
    ; TODO remove clients connected to the server sending SQ, also all leaf servers for that server, sooo good luck with that
    ; Read SQuit, this might be a little related (use ms.client.quit or something)
    return
  }

  ; <server numeric> <AC|ACCOUNT>
  elseif ($istok(AC ACCOUNT,$2,32) == $true) {
    ; TODO, this is for account stuff
    return
  }
  ; <server numeric> <N|NICK> <nick> <hop count> <timestamp> <user> <host> <modes> <base64 ip> <clientnumeric> :<real name>
  elseif ($istok(N NICK,$2,32) == $true) {
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
    ms.channel.create $1 $3 $4
    return
  }

  ; <client numeric> <J|JOIN> <channel> <timestamp> 
  elseif ($istok(J JOIN,$2,32) == $true) {
    if ( $3 !isnum ) { ms.client.join $1 $3 $4 }
    ; if $3 is 0 it's a quit message i think, it seems like it's a quit message
    else { ms.client.quit $1 noquit }
    return
  }

  ; <client numeric> <L|LEAVE> <channel> :<reason>
  elseif ($istok(L PART,$2,32) == $true) {
    ms.client.part $1 $3
    return
  }
  ; <client numeric> <M|MODE> <channel> <:+-modes> <client numerics> <timestamp>
  ; <client numeric> <M|MODE> <client nick> <:+-modes> 
  elseif ($istok(M MODE,$2,32) == $true) {
    ; TODO set modes, NOTE: this is for channels AND clients !
    return
  }
  ; <client numeric> <OM|OPMODE> <channel> <modes> <params\client numerics>
  elseif ($istok(OM OPMODE,$2,32) == $true) {
    ; TODO set modes, NOTE: this is for channels AND clients !, use same alias as mode above?
    return
  }
  ; <numeric> <GL|GLINE> * <+-user@host> <TimeRemaining> 1728501501 1728504799 <:REASON>
  elseif ($istok(GL GLINE,$2,32) == $true) {
    ; TODO set\remove gline
    return
  }
  ; <client numeric> <K|KICK> <channel> <kicked client numeric> :reason
  elseif ($istok(K KICK,$2,32) == $true) {
    if ((%mServices.fishbot.loaded == true) && ($4 == %ms.fishbot.numeric)) || ((%mServices.banana.loaded == true) && ($4 == %ms.banana.numeric)) { 
      ms.servicebot.kicked $4 $3
    }
    ms.client.part $4 $3
    return
  }

  ; <client numeric> <P|Privmsg> <targetchan\targetclient numeric> :<message>
  elseif ($istok(P PRIVMSG,$2,32) == $true) {
    if ( %mServices.fishbot.loaded == true ) && ( $istok(%ms.fishbot.channels,$3,44) ) { 
      ms.servicebot.text $1-
    }
    elseif ( %mServices.fishbot.loaded == true ) && ( %ms.fishbot.numeric == $3 ) { 
      ms.servicebot.privmsg $1-
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
    ms.client.quit $1
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
  ; T = topic, TODO: make a topic command
  elseif ($istok(RI V R A T,$2,32) == $true) { return }

  ; <client numeric> W|WHOIS <target numeric> :<target nick>
  elseif ( $istok(W,$2,32) == $true ) {
    mServices.sraw 311 $1 $mid($4,2,99) %ms. [ $+ [ $mid($4,2,99) ] ] [ $+ [ .user ] ] %ms. [ $+ [ $mid($4,2,99) ] ] [ $+ [ .host ] ] %ms. [ $+ [ $mid($4,2,99) ] ] [ $+ [ .realname ] ]
    ; mServices.sraw 313 $1 $mid($4,2,99) :is an IRC Operator
    mServices.sraw 312 $1 $mid($4,2,99) nakaservices.deepnet.chat A mIRC Services server
    ; mServices.sraw 330 $1 $mid($4,2,99) AUTHNAME :is logged in as
    mServices.sraw 317 $1 $mid($4,2,99) 0 %ms.startime :seconds idle, signon time
    mServices.sraw 318 $1 $mid($4,2,99) :End of /WHOIS list.
    return
  }

  ; <numeric> TI[ME] <server numeric> BWAAA 1728383433 29005 :<No client start time>
  elseif ($istok(TI TIME,$2,32) == $true) {
    mServices.sraw 391 $1 $mServices.config(serverName) $ctime 0 $+(:,$asctime($ctime,dddd mmmm dd yyyy -- HH:nn) +02:00)
    return
  }
  else {
    ms.echo red [Sockread] Unknown command received: $1-
    return
  }
}