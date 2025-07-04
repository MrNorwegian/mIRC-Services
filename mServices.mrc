on *:unload:{ 
  sockclose mServices 
  unload -rs scripts/mIRC-Services/mServices_conf.mrc
  unload -rs scripts/mIRC-Services/mServices_base64.mrc
  unload -rs scripts/mIRC-Services/mServices_commands.mrc
  unload -rs scripts/mIRC-Services/mServices_botcommands.mrc
  ; Optional modules
  unload -rs scripts/mIRC-Services/mServices_funbots.mrc
  unload -rs scripts/mIRC-Services/mServices_gamebot.mrc
  unload -rs scripts/mIRC-Services/mServices_spybot.mrc

  ; Undernet GNUWorld services
  unload -rs scripts/mIRC-Services/mServices_cservice.mrc
  ; unload -rs scripts/mIRC-Services/mServices_ccontrol.mrc
  ; unload -rs scripts/mIRC-Services/mServices_chanfix.mrc

  ; Atheme services
  ; unload -rs scripts/mIRC-Services/mServices_operserv.mrc
  ; unload -rs scripts/mIRC-Services/mServices_nickserv.mrc
  ; unload -rs scripts/mIRC-Services/mServices_chanserv.mrc
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
  load -rs scripts/mIRC-Services/mServices_funbots.mrc
  load -rs scripts/mIRC-Services/mServices_gamebot.mrc
  load -rs scripts/mIRC-Services/mServices_spybot.mrc

  ; Undernet GNUWorld services
  load -rs scripts/mIRC-Services/mServices_cservice.mrc
  ; load -rs scripts/mIRC-Services/mServices_ccontrol.mrc
  ; load -rs scripts/mIRC-Services/mServices_chanfix.mrc

  ; Atheme services
  ; load -rs scripts/mIRC-Services/mServices_operserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_nickserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_chanserv.mrc
  ; load -rs scripts/mIRC-Services/mServices_newservQ.mrc
  ; load -rs scripts/mIRC-Services/mServices_newservL.mrc
  ms.echo green Finished loaded modules
}

on *:start:{ set %ms.status starting }
on *:exit:{ mServices.stop }

; TODO, if sockclose happens without a variable set, reconnect
; - Set variable %ms.status stopped
on *:sockclose:mServices:{ 
  if ( %ms.status != stopped ) { ms.echo orange [Sockclose] $sockname closed, reconnecting | mServices.start }
  else { ms.echo orange [Sockclose] $sockname closed }
}

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
  set %ms.clnum 1

  ; sending PASS, SERVER and burst
  ms.echo blue [mServices mIRC Server] Connection established to $+($mServices.config(hostname),$mServices.config(port))
  ms.echo blue [mServices mIRC Server] Sending PASS and SERVER
  mServices.raw PASS $+(:,$mServices.config(password))
  mServices.raw SERVER $mServices.config(serverName) 1 %ms.startime $ctime P10 $+(%ms.numeric,%ms.maxcon) $mServices.config(flags) $+(:,$mServices.config(info))
  ms.newserver SERVER $mServices.config(serverName) 1 %ms.startime $ctime P10 $+(%ms.numeric,%ms.maxcon) $mServices.config(flags) $+(:,$mServices.config(info))

  ms.echo blue [mServices mIRC Server] Connection established
}

on *:sockread:mServices:{
  var %mServices.sockRead = $null
  sockread %mServices.sockRead
  tokenize 32 %mServices.sockRead

  ; Just for debugging into console and #debug channel 
  if ( %mServices.ignore.PINGPONG == true ) { 
    if ( $istok(G RI TI,$2,32) != $true ) { ms.debug orange [Sockread Server] --> $1- }
  }

  if ($sockerr > 0) {
    ms.echo red [Sockread] : $sockname closed due to error ( $sockerr )
    set %ms.status failed to link
    sockclose $sockname
    halt
  }

  ; checking if password is correct, then checking servername
  ; <PASS> :<password>
  if ($istok(PASS,$1,32) == $true) { 
    set %ms.status checking password
    if ( $mid($2,2,99) == $mServices.config(password) ) { 
      ms.echo blue [mServices mIRC Server] Received response with PASS
      set %ms.status LinkingPass
      return
    }
    else { 
      ms.echo red [mServices mIRC Server] Password is incorrect, closing connection
      set %ms.status LinkingPass - Failed, wrong password
      sockclose mServices
      return
    }
  }

  ; <server numeric> <S|SERVER> <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<description>
  elseif ($istok(SERVER,$1,32) == $true) {
    ; TODO: check if server name is correct and server numeric doesnt crash with us
    ; set %ms.status checking password
    ; set %ms.status verified password
    ms.echo blue [mServices mIRC Server] Received response with SERVER, linked to $2 and waiting for burst
    ms.newserver $1-
    set %ms.status LinkingServer
    return
  }

  ; <server numric> S <server name> <hop> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :Desc
  elseif ($istok(S,$2,32) == $true) {
    if ( %ms.status == LinkingServer ) { set %ms.status BurstingServers | ms.echo blue [mServices mIRC Server] Bursting servers }
    ms.newserver $1-
    return
  }

  ; Sending Acknowledge the end of burst
  if ($istok(EB EOB_ACK,$2,32) == $true) && ( %ms.myhubnum == $1 ) {
    ; Burst the bots, chans and modes
    ms.echo blue [mServices mIRC Server] Received end of burst, bursting servicebots and channels

    ; Burst here

    ; Sending END_OF_BURST
    ms.echo blue [mServices mIRC Server] Sending Acknowledge
    mServices.sraw EB
    mServices.sraw EA
    set %ms.status Burst finished
    return
  }
  elseif ($istok(EB EOB_ACK,$2,32) == $true) && ( $1 != %ms.myhubnum ) {
    ; new server connected to another server on the network, do something ??? nah?
    return
  }

  ; Received Acknowledge the end of burst
  if ($istok(EA,$2,32) == $true) && ( %ms.myhubnum == $1 ) {
    ms.echo blue [mServices mIRC Server] Received Acknowledge of end of burst
    ms.echo blue [mServices mIRC Server] Starting to load services
    set %ms.status linked loading servicebots

    ; TODO, if bursting the service bots, skip this
    ms.start.servicebots $mServices.config(servicebots)
    return
  }

  elseif ($istok(EA,$2,32) == $true) && ( $1 != %ms.myhubnum) {
    ; new server connected to another server on the network, do something ??? nah?
    ; Yes, read todo
    return
  }

  ; <Server numeric> AC|ACCOUNT <client numeric> <account accountid>
  elseif ($istok(AC ACCOUNT,$2,32) == $true) {
    ; TODO, this is for account stuff
    ms.account $1-
    return
  }

  ; <server numeric> <N|NICK> <nick> <hop count> <timestamp> <user> <host> <modes> <base64 ip> <clientnumeric> :<real name>
  elseif ($istok(N NICK,$2,32) == $true) {

    ; TODO, need to check if %ms.status is BurstingServers or Bursting, need to test linking a single server and see if that is enough
    ; if ( %ms.status != BurstingClients ) { ms.echo blue [mServices mIRC Server] Bursting clients ;}

    ; This also applies to nickchanges
    ms.newclient $1-
    return
  }

  ; <server numeric> <B|BURST> <chan> <createtime??> <+chanmodes> BbACg,AoAAH,AzAAE,ABAAv:o,BWAAA,AzAAC,AzAAA,BdAAA
  elseif ($istok(B BURST,$2,32) == $true) {
    if ( %ms.status != BurstingChannels ) { ms.echo blue [mServices mIRC Server] Bursting channels }
    ms.burstchannels $1-
    return
  }

  ; <client numeric> <C|CREATE> <channel> <timestamp>
  elseif ($istok(C CREATE,$2,32) == $true) {
    ms.channel.create $1 $3 $4
    return
  }

  ; <client numeric> <J|JOIN> <channel> <timestamp> 
  ; <client numeric> <J|JOIN> [0] (/partall)
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

  ; <Server numeric> <DE|DESTRUCT> <channel> <timestamp>
  elseif ($istok(DE DESTRUCT,$2,32) == $true) {
    ;ms.channel.destroy $1 $3
    return
  }

  ; BbAC6 M #testchan -v+tnklo IAAAA code 123 BdAAA 1000000000
  ; <client numeric> <M|MODE> <channel> <+-modes> <arg1 arg2 arg3 arg4 etc> <timestamp>
  ; <client numeric> <M|MODE> <client nick> <:+-modes> 
  elseif ($istok(M MODE,$2,32) == $true) {
    ; echo ascii for #
    if ( $left($3,1) == $chr(35) ) { ms.mode.channel $1 $3 $4 $5- }
    else { ms.mode.client $1 $3 $4 }

    return
  }

  ; <client numeric> <T|TOPIC> <channel> *?* ctime :[topic]
  elseif ($istok(T TOPIC,$2,32) == $true) {
    ; TODO set topic
    return
  }

  ; <client numeric> <OM|OPMODE> <channel> <modes> <params\client numerics>
  elseif ($istok(OM OPMODE,$2,32) == $true) {
    if ( $left($3,1) == $chr(35) ) { ms.opmode.channel $1 $3 $4 $5- 0 }
    return
  }

  ; <numeric> <GL|GLINE> * <+-user@host> <TimeRemaining> 1728501501 1728504799 <:REASON>
  ; A2 GL * +*@1.2.3.4 3600 1739620520 1739624132 :Reason
  elseif ($istok(GL GLINE,$2,32) == $true) {
    ; TODO set\remove gline
    return
  }

  ; <client numeric> <K|KICK> <channel> <target nicknumeric> :reason
  elseif ($istok(K KICK,$2,32) == $true) {
    ms.servicebot.kicked $1 $3 $4
    ms.client.part $4 $3 kicked $1 $5-
    return
  }

  ; <client numeric> <P|Privmsg> <targetchan\targetclient numeric> :<message>
  elseif ($istok(P PRIVMSG,$2,32) == $true) {
    ms.servicebot.p10.privmsg $1 $3-
    return
  }

  ; <client numeric> <O|NOTICE> <targetclient numeric> :<message>
  elseif ($istok(O NOTICE,$2,32) == $true) {
    ms.servicebot.p10.privnotice $1 $3-
    return
  }

  ; <client numeric> <I|INVITE> <target nick> <target chan> <someID>
  elseif ($istok(I INVITE,$2,32) == $true) {
    ms.servicebot.p10.invited $1 $3 $4-
    return
  }

  ; <client numeric> <Q|QUIT> :<reason>
  elseif ($istok(Q QUIT,$2,32) == $true) {
    ms.client.quit $1 $3-
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
    mServices.sraw RO $ms.get.server(name,$1) $4-
    return
  }

  ; <numeric> MO[TD] <server numeric>
  elseif ($istok(MO MOTD,$2,32) == $true) {
    mServices.sraw 422 $1 :MOTD File is missing
    return
  }

  ; <numeric> <SQ|SQUIT> <server name> <time> :<reason>
  elseif ($istok(SQ SQUIT,$2,32) == $true) {
    if ( $1 == %ms.numeric ) { ms.echo green [mServices mIRC Server] Stopped server }
    ; Some server SQ, try find out who
    else { 
      set %ms.sq.server $3
      set %ms.sq.num 0
      set %ms.sq.servers $ms.db(read,l,servers)
      ; Sending /links to find out who is missing
      mServices.sraw LI
      ms.debug red [SQuit detected] - $1-
      ms.servicebot.p10.srvsplit $1 $3 $4 $5-
    }
    return
  }

  ; <numeric> <raw numeric> <my numeric> <leaf name> <hub name> :<Desc>
  if ($3 == IA ) && (%ms.sq.servers) {
    ; 
    if ( $2 == 364 ) { 
      set %ms.sq.alive $addtok(%ms.sq.alive,$ms.db(search,servers,name $4),44)
      set %ms.sq.servers $remtok(%ms.sq.servers,$ms.db(search,servers,name $4),44)
      inc %ms.sq.num
    }
    ; End of LA 
    elseif ( $2 == 365 ) { 
      if ( $numtok(%ms.sq.servers,44) >= 1 ) {
        ms.echo red [SQuit detected] Missing some servers - Expected: $ms.db(read,l,servers)
        ms.echo red [SQuit detected] Alive: %ms.sq.alive
        ms.echo red [SQuit detected] Dead: %ms.sq.servers 
        ms.debug red [SQuit detected] - Missing servers: %ms.sq.servers

        ; Loop thru all missing servers and remove all clients connected to the server
        var %ms.sq.i $numtok(%ms.sq.servers,44)
        while ( %ms.sq.i ) {
          ms.debug red [SQuit detected] Removing server: $gettok(%ms.sq.servers,%ms.sq.i,44)
          var %ms.sq.clients $ms.db(read,l,$gettok(%ms.sq.servers,%ms.sq.i,44))

          var %ms.sq.c $numtok(%ms.sq.clients,44)
          while ( %ms.sq.c ) {
            ms.debug red [SQuit detected] Removing client: $gettok(%ms.sq.clients,%ms.sq.c,44)
            ms.client.quit $gettok(%ms.sq.clients,%ms.sq.c,44) *.net *.split
            dec %ms.sq.c
          }
          ms.remserver $gettok(%ms.sq.servers,%ms.sq.i,44)
          dec %ms.sq.i
        }

      }
      unset %ms.sq.alive %ms.sq.servers %ms.sq.server %ms.sq.num 
    }
    return
  }

  elseif ($istok(WA,$2,32) == $true) {
    ; TODO, this is for wallops stuff
    return
  }

  ; <numeric> RI|V|R <server numeric> ; This is just som misc stuff
  elseif ($istok(V R A,$2,32) == $true) { return }

  ; <client numeric> W|WHOIS <target srvnum> :<target nick>
  elseif ( $istok(W,$2,32) == $true ) {
    var %tnick $mid($4,2,99)
    ms.servicebot.whois $1 $2 %tnick
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
