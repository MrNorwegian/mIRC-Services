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
  set %ms.status linking

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
    set %ms.status failed to link
    sockclose $sockname
  }
  if ( $mServices.config(rawdebug) == true ) { ms.echo orange [Sockread Server] --> $1- }

  ; Sending Acknowledge the end of burst
  if ($istok(EB EOB_ACK,$2,32) == $true) && ( %ms.myhub == $1 ) {
    mServices.sraw EA
    ms.echo blue [mServices mIRC Server] Received response with EB and sending EA
    set %ms.status burst finished
    return
  }
  elseif ($istok(EB EOB_ACK,$2,32) == $true) && ( $1 != %ms.myhub) {
    ; new server connected to another server on the network, do something ??? nah?
    return
  }

  ; Received Acknowledge the end of burst
  if ($istok(EA,$2,32) == $true) && ( %ms.myhub == $1 ) {
    ms.echo blue [mServices mIRC Server] Received Acknowledge the end of burst
    ms.echo blue [mServices mIRC Server] Starting to load services
    ms.load.servicebot spybot,fishbot,banana
    set %ms.status linked
    return
  }

  elseif ($istok(EA,$2,32) == $true) && ( $1 != %ms.myhub) {
    ; new server connected to another server on the network, do something ??? nah?
    return
  }

  ; <PASS> :<password>
  if ($istok(PASS,$1,32) == $true) { 
    if ( $mid($2,2,99) == $mServices.config(password) ) { 
      ms.echo blue [mServices mIRC Server] Received response with PASS
      set %ms.status identifying pass
      return
    }
    else { 
      ms.echo red [mServices mIRC Server] Password is incorrect, closing connection
      sockclose mServices
      return
    }
  }

  ; <server numeric> <S|SERVER> <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<description>
  elseif ($istok(SERVER,$1,32) == $true) {
    ; TODO: check if server name is correct and server numeric doesnt crash with us
    ms.echo blue [mServices mIRC Server] Received response with SERVER
    ms.newserver $1-
    set %ms.status bursting
    return
  }
  elseif ($istok(S,$2,32) == $true) {
    ms.newserver $1-
    return
  }
  ; <numeric> <SQ|SQUIT> <server name> <time> :<reason>
  elseif ($istok(SQ SQUIT,$2,32) == $true) {
    ; TODO remove clients connected to the server sending SQ, also all leaf servers for that server, sooo good luck with that
    ; Read SQuit, this might be a little related (use ms.client.quit or something)

    if ( $1 == %ms.numeric ) { ms.echo green [mServices mIRC Server] Stopped server }
    ; Some server sq, try find out who
    else { 
      set %ms.sq.server $3 | set %ms.sq.num 0 | set %ms.sq.servers $ms.db(read,l,servers)
      unset %ms.sq.alive 
      mServices.sraw LI
    }
    return
  }
  ; <numeric> <raw numeric> <my numeric> <leaf name> <hub name> :<Desc>
  elseif ($istok(IA,$3,32) == $true) {
    if ( $2 == 364 ) { 
      ;$ms.db(search,servers,name SERVER.NAME)
      if ( $4 == %mServices.serverName ) { return }
      set %ms.sq.alive $addtok(%ms.sq.alive,$ms.db(search,servers,name $4),32)
      set %ms.sq.servers $remtok(%ms.sq.servers,$ms.db(search,servers,name $4),32)
      inc %ms.sq.num
    }
    ; End of LA 
    elseif ( $2 == 365 ) { 
      if ( $numtok($ms.db(read,l,servers),32) <= %ms.sq.num ) { echo -a ALL SERVERS ARE ALIVE $numtok($ms.db(read,l,servers),32) <= %ms.sq.num }
      else { 
        echo -a NOT ALL SERVERS ARE ALIVE $numtok($ms.db(read,l,servers),32) <= %ms.sq.num
        echo Alive: %ms.sq.alive - DB: $ms.db(read,l,servers)
        echo Dead: %ms.sq.servers 
      }
      unset %ms.sq.alive %ms.sq.servers %ms.sq.server %ms.sq.num 
    }
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
    ms.burstchannels $1-
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
    ; if $3 is 0 then the user joined 0 (that's like /partall)
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

  ; <client numeric> <T|TOPIC> <channel> *?* ctime :[topic]
  elseif ($istok(T TOPIC,$2,32) == $true) {
    ; TODO set topic
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
    ms.client.part $4 $3 kicked
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
    if ((%mServices.fishbot.loaded == true) && ($3 == fishbot)) || ((%mServices.banana.loaded == true) && ($3 == banana)) { 
      ms.servicebot.invited $1 $3 $4
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
  elseif ($istok(RI RPING,$2,32) == $true) {
    ; mServices.sraw RO $3-
    return
  }

  ; <numeric> MO[TD] <server numeric>
  elseif ($istok(MO MOTD,$2,32) == $true) {
    mServices.sraw 422 $1 :MOTD File is missing
    return
  }

  ; <numeric> RI|V|R <server numeric> ; This is just som misc stuff
  elseif ($istok(V R A,$2,32) == $true) { return }

  ; <client numeric> W|WHOIS <target srvnum> :<target nick>
  elseif ( $istok(W,$2,32) == $true ) {
    mServices.sraw 311 $1 $mid($4,2,99) %ms. [ $+ [ $mid($4,2,99) ] ] [ $+ [ .user ] ] %ms. [ $+ [ $mid($4,2,99) ] ] [ $+ [ .host ] ] %ms. [ $+ [ $mid($4,2,99) ] ] [ $+ [ .realname ] ]
    ; mServices.sraw 313 $1 $mid($4,2,99) :is an IRC Operator
    if ( $mid($4,2,99) == %ms.fishbot.nick ) || ( $mid($4,2,99) == %ms.banana.nick ) { 
      mServices.sraw 319 $1 $mid($4,2,99) $ms.db(read,l,%ms. [ $+ [ $mid($4,2,99) ] ] [ $+ [ .numeric ] ])
    }
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