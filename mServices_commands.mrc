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
  ms.echo green[mServices mIRC Server] Stopping the server
  ms.stop.servicebots $mServices.config(servicebots)
  mServices.sraw SQ %mServices.serverName now :Server shutdown
  sockclose $sock(mServices) 
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
    var %ms.nc.srvnum $1
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
        var %ms.nc.num $11
        var %ms.nc.realname $mid($12-,2,99)
      }
      else {
        var %ms.nc.auth NONE
        var %ms.nc.base64ip $9
        var %ms.nc.num $10
        var %ms.nc.realname $mid($11-,2,99)
      }
    }
    else {
      var %ms.nc.modes NONE
      var %ms.nc.auth NONE
      var %ms.nc.base64ip $8
      var %ms.nc.num $9
      var %ms.nc.realname $mid($10-,2,99)
    }
    ms.db write c %ms.nc.num srvnum %ms.nc.srvnum
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),nick %ms.nc.nick,44)
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),hopcount %ms.nc.hopcount,44)
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),timestamp %ms.nc.timestamp,44)
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),user %ms.nc.user,44)
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),host %ms.nc.host,44)
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),modes %ms.nc.modes,44)
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),auth %ms.nc.auth,44)
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),base64ip %ms.nc.base64ip,44)
    ms.db write c %ms.nc.num $addtok($ms.db(read,c,%ms.nc.num),realname %ms.nc.realname,44)

    ; note the clients to it's server, not that important but might be useful
    ; AND this is bugy, max 5500 clients due to max line length in .ini files (dunno in hash)
    ; use $numtok and make list2, list3 etc, or abondon this idea and use $hget() instead to get number of clients (does not work with ini db)
    if (!$istok($ms.db(read,l,%ms.nc.srvnum),%ms.nc.num,44)) { 
      ms.db write l %ms.nc.srvnum $addtok($ms.db(read,l,%ms.nc.srvnum),%ms.nc.num,44)
    }
    if ( %ms.spybot.report == true ) { ms.spybot.report N %ms.nc.srvnum %ms.nc.nick %ms.nc.hopcount %ms.nc.timestamp %ms.nc.user %ms.nc.host %ms.nc.modes %ms.nc.auth %ms.nc.base64ip %ms.nc.num %ms.nc.realname }
  }
  elseif ( $ms.db(read,c,$1,nick) ) {
    var %ms.nc.num $1
    var %ms.nc.newnick $3
    var %ms.nc.timestamp $4
    ms.db write c %ms.nc.num $reptok($ms.db(read,c,%ms.nc.num),$gettok($ms.db(read,c,%ms.nc.num),2,44),nick %ms.nc.newnick,44)
    ms.db write c %ms.nc.num $reptok($ms.db(read,c,%ms.nc.num),$gettok($ms.db(read,c,%ms.nc.num),4,44),timestamp %ms.nc.timestamp,44)
  }
  return
}
; leaf <server numeric> S <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<desc>
; myhub SERVER <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<desc>
alias ms.newserver {
  if ( $1 === SERVER ) { 
    var %ms.ns.name $2
    var %ms.ns.hop $3
    var %ms.ns.starttime $iif($4 === 0,NULL,$4)
    var %ms.ns.linktime $5
    var %ms.ns.protocol $6
    var %ms.ns.num $mid($7,1,2)
    var %ms.ns.maxcon $mid($7,3,3)
    var %ms.ns.flags $iif($mid($8,2,3),$mid($8,2,3),none)
    var %ms.ns.desc $mid($9,2,99) $10-
    set %ms.myhub %ms.ns.num
  }
  elseif ( $2 === S ) { 
    var %ms.ns.servernumeric $1
    var %ms.ns.name $3
    var %ms.ns.hop $4
    var %ms.ns.starttime $iif($5 === 0,$5,NULL)
    var %ms.ns.linktime $6
    var %ms.ns.protocol $7
    var %ms.ns.num $mid($8,1,2)
    var %ms.ns.maxcon $mid($8,3,3)
    var %ms.ns.flags $iif($mid($9,2,3),$mid($9,2,3),none)
    var %ms.ns.desc $mid($10,2,99) $11-
  }

  ; Adding server to database
  ; ms.db write s $+(%ms.ns.num name %ms.ns.name,$chr(44),hop %ms.ns.hop,$chr(44),starttime %ms.ns.starttime,$chr(44),linktime %ms.ns.linktime,$chr(44),protocol %ms.ns.protocol,$chr(44),maxcon %ms.ns.maxcon,$chr(44),flags %ms.ns.flags,$chr(44),desc %ms.ns.desc)
  ms.db write s %ms.ns.num name %ms.ns.name
  ms.db write s %ms.ns.num $addtok($ms.db(read,s,%ms.ns.num),hop %ms.ns.hop,44)
  ms.db write s %ms.ns.num $addtok($ms.db(read,s,%ms.ns.num),starttime %ms.ns.starttime,44)
  ms.db write s %ms.ns.num $addtok($ms.db(read,s,%ms.ns.num),linktime %ms.ns.linktime,44)
  ms.db write s %ms.ns.num $addtok($ms.db(read,s,%ms.ns.num),protocol %ms.ns.protocol,44)
  ms.db write s %ms.ns.num $addtok($ms.db(read,s,%ms.ns.num),maxcon %ms.ns.maxcon,44)
  ms.db write s %ms.ns.num $addtok($ms.db(read,s,%ms.ns.num),flags %ms.ns.flags,44)
  ms.db write s %ms.ns.num $addtok($ms.db(read,s,%ms.ns.num),desc %ms.ns.desc,44)

  ; Is the server already in the database? whops that shouldnt happen :(
  if (!$istok($ms.db(read,l,servers),%ms.ns.num,44)) { ms.db write l servers $addtok($ms.db(read,l,servers),%ms.ns.num,44) }

  if ( %ms.spybot.report == true ) { ms.spybot.report S %ms.ns.num %ms.ns.name %ms.ns.hop %ms.ns.starttime %ms.ns.linktime %ms.ns.protocol %ms.ns.maxcon %ms.ns.flags %ms.ns.desc }
  return
}

; On burst on this server
; <Server numeric> B <chan> <createtime> [+chanmodes> [limit] [key]] AzAAE,BbACg,AoAAH:v,ABAAx:o,AzAAC,BdAAA,BWAAA:vo,AzAAA :%latest!*@* olderban!*@*

; On burst of other servers
; <Server numeric> B <chan> <createtime>
; <Server numeric> B <chan> <createtime> [nick numerics]
; <Server numeric> B <chan> <createtime> [chanmode] [nick numerics]

alias ms.burstchannels {
  var %ms.bc.chan $3
  var %ms.bc.createtime $4
  ; if + isin $3
  if ( $left($5,1) == $chr(43) ) { 
    var %ms.bc.chanmodes $5
    if ( l isin $5 ) && ( k !isin $5 ) {
      var %ms.bc.chanlimit $6
      var %ms.bc.chankey NONE
      var %ms.bc.clients $7
      var %ms.bc.bans $iif($8,$8-,NONE)
    }
    elseif ( k isin $5 ) && ( l !isin $5 ) {
      var %ms.bc.chanlimit NONE
      ; TODO: if someone sets NONE as key, will it be a problem?
      var %ms.bc.chankey $6
      var %ms.bc.clients $7
      var %ms.bc.bans $iif($8,$8-,NONE)
    }
    elseif ( k isin $5 ) && ( l isin $5 ) {
      ; TODO: if someone sets NONE as key, will it be a problem?
      var %ms.bc.chankey $7
      var %ms.bc.chanlimit $6
      var %ms.bc.clients $8
      var %ms.bc.bans $iif($9,$9-,NONE)
    }
    else { 
      var %ms.bc.chanlimit NONE
      var %ms.bc.chankey NONE
      var %ms.bc.clients $6
      var %ms.bc.bans $iif($7,$7-,NONE)
    }
  }
  else {
    var %ms.bc.chanmodes NONE 
    var %ms.bc.chanlimit NONE
    var %ms.bc.chankey NONE
    var %ms.bc.clients $5
    ; TODOO: Remove : from first ban
    var %ms.bc.bans $iif($6,$6-,NONE)
  }

  if (!$istok($ms.db(read,l,channels),%ms.bc.chan,44)) { ms.db write l channels $addtok($ms.db(read,l,channels),%ms.bc.chan,44) }
  ms.db write ch %ms.bc.chan createtime %ms.bc.createtime
  ms.db write ch %ms.bc.chan $addtok($ms.db(read,ch,%ms.bc.chan),chanmodes %ms.bc.chanmodes,44)
  ms.db write ch %ms.bc.chan $addtok($ms.db(read,ch,%ms.bc.chan),chanlimit %ms.bc.chanlimit,44)
  ms.db write ch %ms.bc.chan $addtok($ms.db(read,ch,%ms.bc.chan),chankey %ms.bc.chankey,44)
  ms.db write ch %ms.bc.chan $addtok($ms.db(read,ch,%ms.bc.chan),bans %ms.bc.bans,44)
  ms.db write l %ms.bc.chan %ms.bc.clients

  ; Loop clientnumerics and list then 
  var %i 1
  var %ms.bc.cnl $numtok(%ms.bc.clients,44)
  while ( %i <= %ms.bc.cnl ) {
    ; sort ops\voice\regular instead of client
    var %c $gettok(%ms.bc.clients,%i,44)

    ; mark voiced and oped clients if one client has v the rest is v until o, same with o and in the end vo
    if ( $gettok(%c,2,58) == v ) { var %ms.bc.voiced true }
    elseif ( $gettok(%c,2,58) == o ) { var %ms.bc.voiced false | var %ms.bc.oped true }
    elseif ( $gettok(%c,2,58) == vo ) { var %ms.bc.voiced false | var %ms.bc.oped false | var %ms.bc.voiceandop true }
    ; else regular user

    if ( %ms.bc.voiced == true ) && ( %ms.bc.oped != true ) { var %tmp.users $iif($gettok(%c,2,58) == v,$addtok(%tmp.users,%c,44),$addtok(%tmp.users,$+(%c,$chr(58),v),44)) }
    elseif ( %ms.bc.oped == true ) && ( %ms.bc.voiced != true ) { var %tmp.users $iif($gettok(%c,2,58) == o,$addtok(%tmp.users,%c,44),$addtok(%tmp.users,$+(%c,$chr(58),o),44))  }
    elseif ( %ms.bc.voiceandop == true ) { var %tmp.users $iif($gettok(%c,2,58) == vo,$addtok(%tmp.users,%c,44),$addtok(%tmp.users,$+(%c,$chr(58),vo),44)) }
    else { var %tmp.users $addtok(%tmp.users,%c,44) }
    ms.db write l $gettok(%c,1,58) $addtok($ms.db(read,l,%c),%ms.bc.chan,44)
    inc %i
  }
  ms.db write l %ms.bc.chan %tmp.users
  return
}

alias ms.channel.create {
  var %ms.cc.num $1
  var %ms.cc.chan $2
  var %c $numtok(%ms.cc.chan,44)
  while ( %c ) {
    var %ch $gettok(%ms.cc.chan,%c,44) 
    var %ms.cc.timestamp $3
    ms.db write ch %ch createtime %ms.cc.timestamp
    ms.db write ch %ch $addtok($ms.db(read,ch,%ch),$+(chanmodes NONE,$chr(44),chanlimit NONE,$chr(44),chankey NONE,$chr(44),bans NONE),44)
    ms.db write l %ch $+(%ms.cc.num,$chr(58),o)
    ms.db write l %ms.cc.num $addtok($ms.db(read,l,%ms.cc.num),%ch,44)

    if (!$istok($ms.db(read,l,channels),%ch,44)) { ms.db write l channels $addtok($ms.db(read,l,channels),%ch,44) }
    ms.echo blue [IAL DB] Client %ms.cc.num created %ch
    ms.servicebot.p10.chcreated %ms.cc.num %ch
    dec %c 
  }
  return
}

alias ms.client.join {
  var %ms.cj.num $1
  var %ms.cj.chan $2
  var %ms.cj.timestamp $3
  var %c $numtok(%ms.cj.chan,44)
  while ( %c ) {
    var %ch $gettok(%ms.cj.chan,%c,44) 

    ; Check if nick was already in the channel *whoops*
    if (!$istok($ms.db(read,l,%ch),%ms.cj.num,44) ) { 
      ms.db write l %ch $addtok($ms.db(read,l,%ch),%ms.cj.num,44)
      ms.db write l %ms.cj.num $addtok($ms.db(read,l,%ms.cj.num),%ch,44)
      ms.echo blue [IAL DB] Client %ms.cj.num joined %ch
    }

    dec %c
  }
  ms.servicebot.p10.chjoined %ms.cj.num %ms.cj.chan
  return
}

alias ms.client.part {
  var %ms.cl.num $1
  var %ms.cl.chan $2
  var %c $numtok(%ms.cl.chan,44)
  while ( %c ) {
    var %ch $gettok(%ms.cl.chan,%c,44)
    ; Check if client is the last one in the channel, if so remove the channel
    if ( $numtok($ms.db(read,l,%ch),44) <= 1 ) { 
      ms.db rem ch %ch
      ms.db rem l %ch
      ms.echo blue [IAL DB] Removed channel %ch
    }
    ; Part the client from channel
    else {
      var %n $ms.db(read,l,%ch)
      if ( $istok(%n,$+(%ms.cl.num,$chr(58),v),44) ) { ms.db write l %ch $remtok(%n,$+(%ms.cl.num,$chr(58),v),44) }
      elseif ( $istok(%n,$+(%ms.cl.num,$chr(58),o),44) ) { ms.db write l %ch $remtok(%n,$+(%ms.cl.num,$chr(58),o),44) }
      elseif ( $istok(%n,$+(%ms.cl.num,$chr(58),vo),44) ) { ms.db write l %ch $remtok(%n,$+(%ms.cl.num,$chr(58),vo),44) }
      else { ms.db write l %ch $remtok(%n,%ms.cl.num,44) }
    }
    ; Check if this was the last channel for the client
    if ( $istok($ms.db(read,l,%ms.cl.num),%ch,44) <= 1 ) { ms.db rem l %ms.cl.num }
    else { ms.db write l %ms.cl.num $remtok($ms.db(read,l,%ms.cl.num),%ch,44) }
    ms.db write l channels $remtok($ms.db(read,l,channels),%ch,44)
    ms.echo blue [IAL DB] Client %ms.cl.num parted channel %ch
    ms.servicebot.p10.chparted $1 %ch $iif($3,$3,$null)
    dec %c
  }
  return
}

alias ms.client.quit { 
  var %ms.cq.num $1
  var %ms.cq.chans $ms.db(read,l,%ms.cq.num)

  ; when join 0 the client is not quiting, i'm using this alias to part all channels
  if ( $2 == noquit ) { 
    var %c $numtok(%ms.cq.chans,44)
    while ( %c ) {
      ms.client.part %ms.cq.num $gettok(%ms.cq.chans,%c,44)
      dec %c
    }
  }
  else {
    set -u1 %ms.client.part.quiet. $+ %ms.cq.num true
    var %c $numtok(%ms.cq.chans,44)
    while ( %c ) {
      ms.client.part %ms.cq.num $gettok(%ms.cq.chans,%c,44)
      dec %c
    }
    if ( %ms.spybot.report == true ) { ms.spybot.report Q $1 $2- }
    var %ms.cq.srvnum $gettok($gettok($ms.db(read,c,%ms.cq.num),1,44),2,32)
    ms.db rem c %ms.cq.num
    if ( $numtok($ms.db(read,l,%ms.cq.srvnum),44) <= 1 ) { ms.db rem l %ms.cq.srvnum }
    else { ms.db write l %ms.cq.srvnum $remtok($ms.db(read,l,%ms.cq.srvnum),%ms.cq.num,44) }
    ms.echo blue [IAL DB] Removed client %ms.cq.num from server
  }
  return
}

; <client numeric> <channel> <:+-modes> <client numerics> <timestamp>
; <client numeric> <client nick> <:+-modes> 

alias ms.mode.client { 
  var %ms.mc.num $1
  var %ms.mc.nick $2
  var %ms.mc.modes $mid($3,2,99)
  ms.servicebot.p10.clientmode %ms.mc.num %ms.mc.nick %ms.mc.modes
  ms.change.client modes $1 %ms.mc.modes
  return
}
alias ms.mode.channel { 
  var %ms.mc.num $1
  var %ms.mc.chan $2
  var %ms.mc.modes $mid($3,2,99)
  var %ms.mc.clients $4
  var %ms.mc.timestamp $5

  ; Todo, find channel, loop clients and add\remove modes
  
  return
}


alias ms.db.reset {
  ms.echo green Resetting databases
  ms.db rem s
  ms.db rem c
  ms.db rem ch
  ms.db rem l
  if ( $hget(servers) ) { hfree servers | hmake -s servers 100 }
  else { hmake -s servers 100 }
  if ( $hget(clients) ) { hfree clients | hmake -s clients 10000 }
  else { hmake -s clients 10000 }
  if ( $hget(channels) ) { hfree channels | hmake -s channels 1000 }
  else { hmake -s channels 1000 }
  if ( $hget(list) ) { hfree list | hmake -s list 10000 }
  else { hmake -s list 10000 }
  ; reset client numeric
  set %ms.client.numeric 0
}

alias ms.get.client { 
  if ( $ms.db(read,c,$2) ) { 
    var %msgc $v1
    if ( $1 == server ) { return $gettok($gettok(%msgc,1,44),2,32) }
    elseif ( $1 = nick ) { return $gettok($gettok(%msgc,2,44),2,32) }
    elseif ( $1 == ident ) { return $gettok($gettok(%msgc,5,44),2,32) }
    elseif ( $1 == host ) { return $gettok($gettok(%msgc,6,44),2,32) }
    elseif ( $1 == modes ) { return $gettok($gettok(%msgc,7,44),2,32) }
    elseif ( $1 == auth ) { return $gettok($gettok(%msgc,8,44),2,32) }
    elseif ( $1 == base64ip ) { return $gettok($gettok(%msgc,9,44),2,32) }
    elseif ( $1 == realname ) { return $gettok($gettok(%msgc,10,44),2-,32) }
    else { return $null }
  }
}
alias ms.change.client {
  if ( $3 ) {
    if ( $ms.db(read,c,$2) ) { 
      var %ms.ch.c.data $v1
      if ( $1 == nick ) { ms.db write c $2 $puttok(%ms.ch.c.data,nick $3,2,44) }
      elseif ( $1 == ident ) { ms.db write c $2 $puttok(%ms.ch.c.data,ident $3,5,44) }
      elseif ( $1 == host ) { ms.db write c $2 $puttok(%ms.ch.c.data,host $3,6,44) }
      elseif ( $1 == modes ) { ms.db write c $2 $puttok(%ms.ch.c.data,modes $3,7,44) }
      elseif ( $1 == auth ) { ms.db write c $2 $puttok(%ms.ch.c.data,auth $3,8,44) }
      elseif ( $1 == base64ip ) { ms.db write c $2 $puttok(%ms.ch.c.data,base64ip $3,9,44) }
      elseif ( $1 == realname ) { ms.db write c $2 $puttok(%ms.ch.c.data,realname $3,10,44) }


      else { ms.echo red [Change client] $2 is not a valid argument }
    }
    else { ms.echo red [Change client] $1 is not a valid client numeric }
  }
  else { ms.echo red [Change client] Missing arguments }
}
alias ms.get.server { 
  if ( $ms.db(read,s,$2) ) { 
    var %msgs $v1
    if ( $1 == name ) { return $gettok($gettok(%msgs,1,44),2,32) }
    elseif ( $1 == hop ) { return $gettok($gettok(%msgs,2,44),2,32) }
    elseif ( $1 == starttime ) { return $gettok($gettok(%msgs,3,44),2,32) }
    elseif ( $1 == linktime ) { return $gettok($gettok(%msgs,4,44),2,32) }
    elseif ( $1 == protocol ) { return $gettok($gettok(%msgs,5,44),2,32) }
    elseif ( $1 == maxcon ) { return $gettok($gettok(%msgs,6,44),2,32) }
    elseif ( $1 == flags ) { return $gettok($gettok(%msgs,7,44),2,32) }
    elseif ( $1 == desc ) { return $gettok($gettok(%msgs,8,44),2-,32) }
    else { return $null }
  }
}

alias ms.db {
  ; $ms.db(read,s,arg1)
  ; /ms.db write ch arg1 arg2+
  ; /ms.db rem\del c [arg1]

  ; TODO: add  $ms.db(search,TEXT) to search for a specific value in the database in arg1 section 

  ; TODO: Remove .ini, numerics with [ interfere with the .ini file
  ; After testing move this variable to mServices_config.mrc and begin sql db testing ?
  var %ms.db.type hash
  if ( $2 ) {
    if ( $2 == s ) { var %db.file ms.ial.ini | var %db.topic servers | var %db.hash servers }
    elseif ( $2 == c ) { var %db.file ms.ial.ini | var %db.topic clients | var %db.hash clients }
    elseif ( $2 == ch ) { var %db.file ms.ial.ini | var %db.topic channels | var %db.hash channels }
    elseif ( $2 == l ) { var %db.file ms.ial.ini | var %db.topic list | var %db.hash list }
    else { var %db.file $+($2,.ini) | var %db.hash $2 }

    var %db.arg1 $3 ,%db.arg2 $4-

    if ( $1 = read ) {
      if ( %db.arg1 ) { 
        if ( %ms.db.type = ini ) { return $readini(%db.file,%db.topic,%db.arg1) }
        elseif ( %ms.db.type = hash ) { return $hget(%db.hash,%db.arg1) }
      }
      else { ms.echo red DB read error, missing arg1: $1- }
    }
    elseif ( $1 = write ) {
      if ( %db.arg2 ) { 
        if ( %ms.db.type = ini ) { writeini %db.file %db.topic %db.arg1 %db.arg2 }
        elseif ( %ms.db.type = hash ) { hadd %db.hash %db.arg1 %db.arg2 }
      }
      ; TODO it IS possible to write empty values, but it's not possible to read them, so we might want to write empty values as NONE ? *think*
      else { ms.echo red DB write error, missing arg2: $1- }
    }
    elseif ( $1 = rem ) || ( $1 = del ) { 
      if ( %db.arg1 ) { 
        if ( %ms.db.type = ini ) { remini %db.file %db.topic %db.arg1 }
        elseif ( %ms.db.type = hash ) { hdel %db.hash %db.arg1 }
      }
      else { remini %db.file %db.topic }
    }
    elseif ( $1 == search ) && ( %ms.db.type == hash ) {
      if ( $hfind($2,$+($chr(42),$3,$chr(42)),1,w).data ) { return $v1 }
      else { return $null }
    }
    else { ms.echo red DB error, missing read\write or rem\del: $1- }
  }

  elseif ( $1 == list ) && ( %ms.db.type == hash ) { 
    var %c $hget(clients,0).data
    echo $+(Total clients: %c)
    while (%c) { 
      echo -a %c $hget(clients,%c).item $hget(clients,%c).data
      dec %c
    }
    var %s $hget(servers,0).data
    echo $+(Total servers: %s)
    while (%s) { 
      echo -a %s $hget(servers,%s).item $hget(servers,%s).data
      dec %s
    }
    var %ch $hget(channels,0).data
    echo $+(Total channels: %ch)
    while (%ch) { 
      echo -a %ch $hget(channels,%ch).item $hget(channels,%ch).data
      dec %ch
    }
    var %l $hget(list,0).data
    echo $+(Total list: %l)
    while (%l) { 
      echo -a %l $hget(list,%l).item $hget(list,%l).data
      dec %l
    }
  }
  else { ms.echo red DB error, missing atleast topic: $1- }
}
