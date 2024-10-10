on *:load: { ms.echo green Loaded mServices_commands.mrc }
on *:unload: { ms.echo red Unloaded mServices_commands.mrc }

alias mServices.raw {
  if ($sock(mServices) != $null) { sockwrite -nt mServices $1- | ms.echo orange [Sockwrite Client] <-- $1- }
  else { ms.echo red [Sockwrite Client] <-- Server is not running | return }
}
alias mServices.sraw {
  if ($sock(mServices) != $null) { sockwrite -nt mServices $inttobase64($mServices.config(numeric),2) $1- | ms.echo orange [Sockwrite Server] <-- $inttobase64($mServices.config(numeric),2) $1- }
  else { ms.echo red [Sockwrite Server] <-- Server is not running | return }
}

alias mServices.start {
  if ( $mServices.config(configured) == NO ) { ms.echo red Server is not configured. Please check mServices.* variables before starting the server. ( Alt + R ) | halt }
  if ($sock(mServices) != $null) { ms.echo orange Server is already running | return }
  sockopen mServices $mServices.config(hostname) $mServices.config(port)
  ms.echo green [mServices IRC Server] Starting server
  ms.echo green Using servername: $mServices.config(serverName) and linking to hostname: $mServices.config(hostname) port: $mServices.config(port) with ctime: $ctime
}
alias mServices.stop {
  if ($sock(mServices) == $null) { ms.echo orange Server is not running | return }
  if ( %mServices.fishbot.loaded == true ) { ms.unload.fishbot }
  if ( %mServices.banana.loaded == true ) { ms.unload.banana }
  if ( %mServices.spybot.loaded == true ) { ms.unload.spybot }
  mServices.sraw SQ %mServices.serverName now :Server shutdown
  sockclose $sock(mServices) 

  ms.echo green Stopping the server
}
alias ms.echo { 
  var %ms.echo.name <mServices> 
  if ( $1 == red ) { var %echo.color 4 }
  elseif ( $1 == green ) { var %echo.color 3 }
  elseif ( $1 == blue ) { var %echo.color 12 }
  elseif ( $1 == orange ) { var %echo.color 7 }
  elseif ( $1 == yellow ) { var %echo.color 8 }
  else { var %echo.color 14 }

  if ($window($mServices.config(window)) != $null) { echo %echo.color -t $mServices.config(window) %ms.echo.name $2- }
  else { echo %echo.color -at %ms.echo.name $2- }
}

; <server numeric> <N|NICK> <nick> <hop count> <timestamp> <user> <host> [<modes> [auth if +r]] <base64 ip> <clientnumeric> :<real name>
; <nick numeric> <N|NICK> <newnick> <timestamp> ; nick change
alias ms.newclient {
  if ( $5 ) { 
    var %ms.nc.servernumeric $1
    var %ms.nc.nick $3
    var %ms.nc.hopcount $4
    var %ms.nc.timestamp $5
    var %ms.nc.user $6
    var %ms.nc.host $7
    if ( + isin $8 ) { 
      var %ms.nc.modes $8
      if ( r isin %ms.nc.modes ) {
        var %ms.nc.auth $gettok($9,1,58)
        var %ms.nc.base64ip $10
        var %ms.nc.clientnumeric $11
        var %ms.nc.realname $mid($12,2,99)
      }
      else {
        var %ms.nc.auth NONE
        var %ms.nc.base64ip $9
        var %ms.nc.clientnumeric $10
        var %ms.nc.realname $mid($11,2,99)
      }
    }
    else {
      var %ms.nc.modes NONE
      var %ms.nc.auth NONE
      var %ms.nc.base64ip $8
      var %ms.nc.clientnumeric $9
      var %ms.nc.realname $mid($10,2,99)
    }

    ; Some debug stuff
    ; echo -a ctime from N msg %ms.nc.nick ( %ms.nc.clientnumeric ) ctime: %ms.nc.timestamp Calc: $calc($ctime - %ms.nc.timestamp)
    ; echo -a CLIENT NUMERIC: $base64toint(%ms.nc.base64ip) c: %ms.nc.clientnumeric and: $base64toint($mid(%ms.nc.clientnumeric,2,9999))
    ; Check if client is already in the database (shouldn't happen, but just in case) (might be there if squit didnt remove it)
    if (!$istok($ms.db(read,c,clients,list),%ms.nc.clientnumeric,32)) { 
      ms.db write c clients list $addtok($ms.db(read,c,clients,list),%ms.nc.clientnumeric,32)
    }
    ms.db write c %ms.nc.clientnumeric servernumeric %ms.nc.servernumeric
    ms.db write c %ms.nc.clientnumeric nick %ms.nc.nick
    ms.db write c %ms.nc.clientnumeric hopcount %ms.nc.hopcount
    ms.db write c %ms.nc.clientnumeric timestamp %ms.nc.timestamp
    ms.db write c %ms.nc.clientnumeric user %ms.nc.user
    ms.db write c %ms.nc.clientnumeric host %ms.nc.host
    ms.db write c %ms.nc.clientnumeric modes %ms.nc.modes
    ms.db write c %ms.nc.clientnumeric auth %ms.nc.auth
    ms.db write c %ms.nc.clientnumeric base64ip %ms.nc.base64ip
    ms.db write c %ms.nc.clientnumeric realname %ms.nc.realname

    ; note the clients to it's server
    ms.db write s %ms.nc.servernumeric clients $addtok($ms.db(read,s,%ms.nc.servernumeric,clients),%ms.nc.clientnumeric,32)
  }
  elseif ( $ms.db(read,c,$1,nick) ) {
    var %ms.nc.clientnumeric $1
    var %ms.nc.newnick $3
    var %ms.nc.timestamp $4
    ms.db write c %ms.nc.clientnumeric nick %ms.nc.newnick
    ms.db write c %ms.nc.clientnumeric timestamp %ms.nc.timestamp
  }
  return
}
; leaf <server numeric> S <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<description>
; myhub SERVER <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<description>
alias ms.newserver {
  if ( $1 === SERVER ) { 
    var %ms.ns.servername $2
    var %ms.ns.hopcount $3
    var %ms.ns.starttime $iif($4 === 0,NULL,$4)
    var %ms.ns.linktime $5
    var %ms.ns.protocol $6
    var %ms.ns.servernumeric $mid($7,1,2)
    var %ms.ns.maxconn $mid($7,3,3)
    var %ms.ns.flags $iif($mid($8,2,3),$mid($8,2,3),none)
    var %ms.ns.description $mid($9,2,99) $10-
    set %ms.myhub %ms.ns.servernumeric
   ; echo -a DEBUG our ctime: $ctime and servers start and link %ms.ns.starttime %ms.ns.linktime
  }
  elseif ( $2 === S ) { 
    var %ms.ns.servernumeric $1
    var %ms.ns.servername $3
    var %ms.ns.hopcount $4
    var %ms.ns.starttime $iif($5 === 0,$5,NULL)
    var %ms.ns.linktime $6
    var %ms.ns.protocol $7
    var %ms.ns.servernumeric $mid($8,1,2)
    var %ms.ns.maxconn $mid($8,3,3)
    var %ms.ns.flags $iif($mid($9,2,3),$mid($9,2,3),none)
    var %ms.ns.description $mid($10,2,99) $11-
  }
  ms.db write s servers list $addtok($ms.db(read,s,servers,list),%ms.ns.servernumeric,32)
  ms.db write s %ms.ns.servernumeric servername %ms.ns.servername
  ms.db write s %ms.ns.servernumeric hopcount %ms.ns.hopcount
  ms.db write s %ms.ns.servernumeric starttime %ms.ns.starttime
  ms.db write s %ms.ns.servernumeric linktime %ms.ns.linktime
  ms.db write s %ms.ns.servernumeric protocol %ms.ns.protocol
  ms.db write s %ms.ns.servernumeric maxconn %ms.ns.maxconn
  ms.db write s %ms.ns.servernumeric flags %ms.ns.flags
  ms.db write s %ms.ns.servernumeric description %ms.ns.description
  return
}

; <chan> <createtime??> [+chanmodes> [limit] [key]] AzAAE,BbACg,AoAAH:v,ABAAx:o,AzAAC,BdAAA,BWAAA:vo,AzAAA :%latest!*@* olderban!*@*
; reg,voiced,oped,voiceandoped 
alias ms.burstchannels {
  var %ms.bc.channel $1
  var %ms.bc.createtime $2
  ; if + isin $3
  if ( $left($3,1) == $chr(43) ) { 
    var %ms.bc.chanmodes $3
    if ( l isin $3 ) && ( k !isin $3 ) {
      var %ms.bc.chanlimit $4
      var %ms.bc.chankey NONE
      var %ms.bc.clients $5
      var %ms.bc.bans $iif($6,$6-,NONE)
    }
    elseif ( k isin $3 ) && ( l !isin $3 ) {
      var %ms.bc.chanlimit NONE
      var %ms.bc.chankey $4
      var %ms.bc.clients $5
      var %ms.bc.bans $iif($6,$6-,NONE)
    }
    elseif ( k isin $3 ) && ( l isin $3 ) {
      var %ms.bc.chankey $5
      var %ms.bc.chanlimit $4
      var %ms.bc.clients $6
      var %ms.bc.bans $iif($7,$7-,NONE)
    }
    else { 
      var %ms.bc.chanlimit NONE
      var %ms.bc.chankey NONE
      var %ms.bc.clients $4
      var %ms.bc.bans $iif($5,$5-,NONE)
    }
  }
  else {
    var %ms.bc.chanmodes NONE 
    var %ms.bc.chanlimit NONE
    var %ms.bc.chankey NONE
    var %ms.bc.clients $3
    var %ms.bc.bans $iif($4,$4-,NONE)
  }

  ms.db write ch channels list $addtok($ms.db(read,ch,channels,list),%ms.bc.channel,32)
  ms.db write ch %ms.bc.channel createtime %ms.bc.createtime
  ms.db write ch %ms.bc.channel chanmodes %ms.bc.chanmodes
  ms.db write ch %ms.bc.channel chanlimit %ms.bc.chanlimit
  ms.db write ch %ms.bc.channel chankey %ms.bc.chankey
  ms.db write ch %ms.bc.channel bans $mid($remove(%ms.bc.bans,$chr(37)),1,999)

  ; Loop clientnumerics
  var %i 1
  var %ms.bc.cnl $numtok(%ms.bc.clients,44)
  while ( %i <= %ms.bc.cnl ) {
    ; sort ops\voice\regular instead of client
    var %c $gettok(%ms.bc.clients,%i,44)
    ms.db write ch %ms.bc.channel clients %ms.bc.cnl
    ms.db write ch %ms.bc.channel clientlist $addtok($ms.db(read,ch,%ms.bc.channel,clientlist),$gettok(%c,1,58),32)
    ms.db write c $gettok(%c,1,58) channels $addtok($ms.db(read,c,$gettok(%c,1,58),channels),%ms.bc.channel,32)

    ; mark voiced and oped clients if one client has v the rest until o also is v, same with o and in the end vo
    if ( $gettok(%c,2,58) == v ) { var %ms.bc.voiced true }
    elseif ( $gettok(%c,2,58) == o ) { var %ms.bc.voiced false | var %ms.bc.oped true }
    elseif ( $gettok(%c,2,58) == vo ) { var %ms.bc.voiced false | var %ms.bc.oped false | var %ms.bc.voiceandop true }
    ; else regular user

    if ( %ms.bc.voiced == true ) || ( %ms.bc.voiceandop == true ) {
      ms.db write ch %ms.bc.channel voiced $addtok($ms.db(read,ch,%ms.bc.channel,voiced),$gettok(%c,1,58),32)
    }
    elseif ( %ms.bc.oped == true ) || ( %ms.bc.voiceandop == true ) {
      ms.db write ch %ms.bc.channel oped $addtok($ms.db(read,ch,%ms.bc.channel,oped),$gettok(%c,1,58),32)
    }
    else {
      ; ms.db write ch %ms.bc.channel regular $addtok($ms.db(read,ch,%ms.bc.channel,regular),%c,32)
    }
    inc %i
  }
  return
}
; placeholder
alias ms.channel.create {
  var %ms.cc.clientnumeric $1
  var %ms.cc.channel $2
  var %c $numtok(%ms.cc.channel,44)
  while ( %c ) {
    var %ms.cc.timestamp $3
    ms.db write ch channels list $addtok($ms.db(read,ch,channels,list),$gettok(%ms.cc.channel,%c,44),32)
    ms.db write ch $gettok(%ms.cc.channel,%c,44) createtime %ms.cc.timestamp
    ms.db write ch $gettok(%ms.cc.channel,%c,44) clientlist %ms.cc.clientnumeric
    ms.db write ch $gettok(%ms.cc.channel,%c,44) clients 1
    ms.db write ch $gettok(%ms.cc.channel,%c,44) oped %ms.cc.clientnumeric
    ms.db write c %ms.cc.clientnumeric channels $addtok($ms.db(read,c,%ms.cc.clientnumeric,channels),$gettok(%ms.cc.channel,%c,44),32)
    ms.echo blue [IAL DB] Client %ms.cc.clientnumeric created $gettok(%ms.cc.channel,%c,44)
    dec %c 
  }
  return
}
alias ms.client.join {
  var %ms.cj.clientnumeric $1
  var %ms.cj.channel $2
  var %ms.cj.timestamp $3
  var %c $numtok(%ms.cj.channel,44)
  while ( %c ) {
    ; Check if channel really exists
    if ( $ms.db(read,ch,$gettok(%ms.cj.channel,%c,44),clientlist) ) { 
      ms.db write ch $gettok(%ms.cj.channel,%c,44) clientlist $addtok($ms.db(read,ch,$gettok(%ms.cj.channel,%c,44),clientlist),%ms.cj.clientnumeric,32)
      ms.db write ch $gettok(%ms.cj.channel,%c,44) clients $calc($ms.db(read,ch,$gettok(%ms.cj.channel,%c,44),clients) +1)
      ms.echo blue [IAL DB] Client %ms.cj.clientnumeric joined $gettok(%ms.cc.channel,%c,44)
    }
    else {
      ms.db write ch $gettok(%ms.cj.channel,%c,44) timestamp %ms.cj.timestamp
      ms.db write ch $gettok(%ms.cj.channel,%c,44) clientlist %ms.cj.clientnumeric
      ms.db write ch $gettok(%ms.cj.channel,%c,44) clients 1
      ms.db write ch $gettok(%ms.cj.channel,%c,44) oped %ms.cj.clientnumeric
      ms.echo blue [IAL DB] Client %ms.cj.clientnumeric created $gettok(%ms.cc.channel,%c,44)
    }
    ms.db write c %ms.cj.clientnumeric channels $addtok($ms.db(read,c,%ms.cj.clientnumeric,channels),$gettok(%ms.cj.channel,%c,44) ,32)
    dec %c
  }

  return
}

; Gather part and kicked to one alias
; dec $ms.db(read,ch,%ms.cj.channel,clieclients)
; remove channel if empty
; remove client from voiced or oped

alias ms.client.part {
  var %ms.cl.clientnumeric $1
  var %ms.cl.channel $2
  var %c $numtok(%ms.cl.channel,44)
  while ( %c ) {
    var %ms.cl.tmpch $gettok(%ms.cl.channel,%c,44)
    ; Check if client is the last one in the channel, if so remove the channel
    if ( $numtok($ms.db(read,ch,%ms.cl.tmpch,clientlist),32) <= 1 ) { 
      ms.db rem ch %ms.cl.tmpch
      ms.echo blue [IAL DB] Removed channel %ms.cl.tmpch
    }
    ; Part the client from channel
    else {
      ms.db write ch %ms.cl.tmpch clientlist $remtok($ms.db(read,ch,%ms.cl.tmpch,clientlist),%ms.cl.clientnumeric,32)
      ms.db write ch %ms.cl.tmpch clients $calc($ms.db(read,ch,%ms.cl.tmpch,clients) -1)

      if ( $ms.db(read,ch,%ms.cl.tmpch,voiced) ) { var %ms.tmp.voiced $v1 }
      if ( $ms.db(read,ch,%ms.cl.tmpch,oped) ) { var %ms.tmp.oped $v1 }

      if ( %ms.tmp.voiced ) && ( $istok(%ms.tmp.voiced,%ms.cl.clientnumeric,32) ) {
        ; Check if client is last voiced
        if ( $numtok(%ms.tmp.voiced,32) <= 1 ) { ms.db rem ch %ms.cl.tmpch voiced }
        else { ms.db write ch %ms.cl.tmpch voiced $remtok(%ms.tmp.voiced,%ms.cl.clientnumeric,32) }
      }
      if ( %ms.tmp.oped ) && ( $istok(%ms.tmp.oped,%ms.cl.clientnumeric,32) ) {
        ; Check if client is last oped
        if ( $numtok(%ms.tmp.oped,32) <= 1 ) { ms.db rem ch %ms.cl.tmpch oped }
        else { ms.db write ch %ms.cl.tmpch oped $remtok(%ms.tmp.oped,%ms.cl.clientnumeric,32) }
      }
    }
    ms.echo blue [IAL DB] Client %ms.cl.clientnumeric parted channel %ms.cl.tmpch
    ; Remove channel from client's db
    ; First check if client is on 1 or less channels
    if ( $numtok($ms.db(read,c,%ms.cl.clientnumeric,channels),32) <= 1 ) {
      ms.db rem c %ms.cl.clientnumeric channels
      ms.echo blue [IAL DB] Client %ms.cl.clientnumeric parted it's last channel
    }
    ; Removing channel from client's db
    else { ms.db write c %ms.cl.clientnumeric channels $remtok($ms.db(read,c,%ms.cl.clientnumeric,channels),%ms.cl.tmpch,32) }
    dec %c
  }
  return
}

alias ms.client.quit { 
  var %ms.cq.clientnumeric $1
  var %ms.cq.chans $ms.db(read,c,%ms.cq.clientnumeric,channels,32)
  var %c $numtok(%ms.cq.chans,32)
  while ( %c ) {
    ms.client.part %ms.cq.clientnumeric $gettok(%ms.cq.chans,%c,32)
    dec %c
  }
  ; when join 0 the client is not quiting, i'm using this alias to part all channels
  if ( $2 != noquit ) { 
    ; Remove client from server
    var %ms.cq.srvnum $ms.db(read,c,%ms.cq.clientnumeric,servernumeric)
    var %ms.cq.clients $ms.db(read,s,%ms.cq.srvnum,clients)
    ; Check if this was the last client
    if ( $numtok(%ms.cq.clients,32) <= 1 ) { ms.db rem s %ms.cq.srvnum clients }
    else {
      ms.db write s %ms.cq.srvnum clients $remtok(%ms.cq.clients,%ms.cq.clientnumeric,32)
    }
    ; remove client from clients list
    ms.db rem c %ms.cq.clientnumeric
    ms.db write c clients list $remtok($ms.db(read,c,clients,list),%ms.cq.clientnumeric,32)
    ms.echo blue [IAL DB] Removed client %ms.cq.clientnumeric from server
  }
  return
}

alias ms.db.reset {
  ms.echo green Resetting databases
  var %s $numtok($ms.db(read,s,servers,list),32)
  var %c $numtok($ms.db(read,c,clients,list),32)
  var %ch $numtok($ms.db(read,ch,channels,list),32)
  while ( %s ) {
    ms.db rem s $gettok($ms.db(read,s,servers,list,32),%s,32)
    dec %s
  }
  while ( %c ) {
    ms.db rem c $gettok($ms.db(read,c,clients,list,32),%c,32)
    dec %c
  }
  while ( %ch ) {
    ms.db rem ch $gettok($ms.db(read,ch,channels,list,32),%ch,32)
    dec %ch
  }
  ms.db rem s servers list
  ms.db rem c clients list
  ms.db rem ch channels list
  ; reset client numeric
  set %ms.client.numeric 0
}
alias ms.db {
  ; $ms.db(read,file,topic,arg1)
  ; /ms.db write file topic arg1 arg2
  ; /ms.db rem\del file topic
  ; TODO use hashtables as db and readini as "long storage" 
  if ( $3 ) {
    if ( $2 == s ) { var %db.file ms.servers.ini }
    elseif ( $2 == c ) { var %db.file ms.clients.ini }
    elseif ( $2 == ch ) { var %db.file ms.channels.ini }
    else { var %db.file $+($2,.ini) }
    var %db.topic $3
    var %db.arg1 $4
    var %db.arg2 $5-

    if ( $1 = read ) {
      if ( %db.arg1 ) { return $readini(%db.file,%db.topic,%db.arg1) }
      else { ms.echo red DB read error: $1- }
    }
    elseif ( $1 = write ) {
      if ( %db.arg2 ) { writeini -n %db.file %db.topic %db.arg1 %db.arg2 }
      else { ms.echo red DB write error, missing arg2: $1- }
    }
    elseif ( $1 = rem ) || ( $1 = del ) { 
      if ( %db.arg1 ) { remini %db.file %db.topic %db.arg1 }
      else { remini %db.file %db.topic }
    }
    else { ms.echo red DB error, missing read\write or rem\del: $1- }
  }
  else { ms.echo red DB error, missing atleast topic: $1- }
}