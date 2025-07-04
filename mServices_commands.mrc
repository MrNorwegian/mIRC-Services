on *:load: { ms.echo green Loaded mServices_commands.mrc }
on *:unload: { ms.echo red Unloaded mServices_commands.mrc }

alias mServices.raw {
  if ($sock(mServices) != $null) { 
    sockwrite -nt mServices $1-
    if ( $mServices.config(rawdebug) == true ) { 
      ms.debug orange [Sockwrite Client] <-- $1-
    }
  }
  else { ms.echo red [Sockwrite Client] <-- Server is not running | return }
}
alias mServices.sraw {
  if ($sock(mServices) != $null) { 
    sockwrite -nt mServices $inttobase64($mServices.config(numeric),2) $1-
    if ( $mServices.config(rawdebug) == true ) { 
      ; Just for debugging into console and #debug channel 
      if ( %mServices.ignore.PINGPONG == true ) { 
        if ( $istok(Z RO,$1,32) != $true ) { ms.debug orange [Sockwrite Server] <-- $inttobase64($mServices.config(numeric),2) $1- }
      }
    }
  }
  else { ms.debug red [Sockwrite Server] <-- Server is not running | return }
}

alias mServices.start {
  if ( $mServices.config(configured) == NO ) { ms.echo red Server is not configured. Please check mServices.* variables before starting the server. ( Alt + R ) | halt }
  if ($sock(mServices) != $null) { ms.echo orange Server is already running | return }

  ; First stage, open a connection to the server
  sockopen mServices $mServices.config(hostname) $mServices.config(port)
  ms.echo green [mServices IRC Server] Starting server
  ms.echo green Using servername: $mServices.config(serverName) and linking to hostname: $mServices.config(hostname) port: $mServices.config(port) with ctime: $ctime
}

alias mServices.stop {
  if ($sock(mServices) == $null) { ms.echo orange Server is not running | return }
  ms.echo green [mServices mIRC Server] Stopping the server

  set %ms.status stopped
  ; TODO, servicebots is not quiting properly, need to fix this
  ms.stop.servicebots $mServices.config(servicebots)
  mServices.sraw SQ %mServices.serverName now :Server shutdown
  sockclose $sock(mServices) 
}

; Not that debug, this is echo debug in console and #debug channel if spybot is enabled
alias ms.debug {
  if ( $mServices.config(rawdebug) == true ) { ms.echo $1 $2- }
  if ( %mServices.loaded.spybot ) { ms.spybot.debug $2- }
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

; TODO, redo game.* to ms.* in mServices_gb.*, use alias to add ( ) ? example under:
;alias ms.greenp { return $+($chr(40),00,03,$1,00,03,$chr(41)) ;}
alias game.green { return 00,03 }
alias game.red { return 00,04 }
alias game.blue { return 00,02 }

alias ms.white { return 00 $+ $1- $+  }
alias ms.black { return 01 $+ $1- $+  }
alias ms.blue { return 02 $+ $1- $+  }
alias ms.green { return 03 $+ $1- $+  }
alias ms.red { return 04 $+ $1- $+  }
alias ms.darkred { return 05 $+ $1- $+  }
alias ms.purple { return 06 $+ $1- $+  }
alias ms.orange { return 07 $+ $1- $+  }
alias ms.yellow { return 08 $+ $1- $+  }
alias ms.lightgreen { return 09 $+ $1- $+  }
alias ms.cyan { return 10 $+ $1- $+  }
alias ms.lightblue { return 11 $+ $1- $+  }
alias ms.blue { return 12 $+ $1- $+  }
alias ms.pink { return 13 $+ $1- $+  }
alias ms.grey { return 14 $+ $1- $+  }
alias ms.lightgrey { return 15 $+ $1- $+  }


; <server numeric> <N|NICK> <nick> <hop count> <timestamp> <user> <host> [<modes> [auth if +r]] <base64 ip> <clientnumeric> :<real name>
; <nick numeric> <N|NICK> <newnick> <timestamp>
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

      ; +rz auth tlsfingerprint
      ; +zr tlsfingerprint auth
      ; +z tlsfingerprint-only
      ; +r auth-only
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
    ; Build up the client line for the database
    var %ms.nc.client $+(srvnum %ms.nc.srvnum,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,nick %ms.nc.nick,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,hopcount %ms.nc.hopcount,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,timestamp %ms.nc.timestamp,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,user %ms.nc.user,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,host %ms.nc.host,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,modes %ms.nc.modes,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,auth %ms.nc.auth,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,base64ip %ms.nc.base64ip,$chr(44))
    var %ms.nc.client $+(%ms.nc.client,realname %ms.nc.realname,$chr(44))

    ms.db write c %ms.nc.num %ms.nc.client
    ms.db write nh %ms.nc.num %ms.nc.nick %ms.nc.timestamp

    ; Add the client to server's list of clients
    if (!$istok($ms.db(read,l,%ms.nc.srvnum),%ms.nc.num,44)) { 
      ms.db write l %ms.nc.srvnum $addtok($ms.db(read,l,%ms.nc.srvnum),%ms.nc.num,44)
    }
    ms.servicebot.p10.Newclient %ms.nc.srvnum %ms.nc.nick %ms.nc.hopcount %ms.nc.timestamp %ms.nc.user %ms.nc.host %ms.nc.modes %ms.nc.auth %ms.nc.base64ip %ms.nc.num %ms.nc.realname
    ms.echo blue [IAL DB] Client %ms.nc.num connected to server %ms.nc.srvnum as %ms.nc.nick

    echo -a New Client: %ms.clnum %ms.nc.num %ms.nc.nick
    inc %ms.clnum
  }

  ; Handle nickchange
  ; <nick numeric> <N|NICK> <newnick> <timestamp>
  elseif ( $ms.db(read,c,$1,nick) ) {
    var %ms.nc.num $1
    var %ms.nc.newnick $3
    var %ms.nc.timestamp $4
    ms.change.client nick %ms.nc.num %ms.nc.newnick
    ms.db write nh %ms.nc.num $addtok($ms.db(read,nh,%ms.nc.num),$+($ms.get.client(nick,%ms.nc.num) %ms.nc.timestamp),44)
    ms.servicebot.p10.nick %ms.nc.num %ms.nc.newnick 
    ms.echo blue [IAL DB] Client %ms.nc.num changed nick to %ms.nc.newnick
  }
  return
}

; <Server numeric> AC <client numeric> <account accountid>
alias ms.account {
  var %ms.ac.srvnum $1
  var %ms.ac.client $3
  var %ms.ac.account $4 $5
  ms.change.client account %ms.ac.client %ms.ac.account
  ms.servicebot.p10.account %ms.ac.srvnum %ms.ac.client %ms.ac.account
  return
}

; leaf <hubserver numeric> S <server name> <hop count> <start time> <link time> <protocol> <server numeric(2)+maxconn(3)> [+flags] :<desc>
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
    set %ms.myhubnum %ms.ns.num
    set %ms.myhubname %ms.ns.name
  }
  elseif ( $2 === S ) { 
    var %ms.ns.hubservernum $1
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

  if ( %ms.spybot.report == true ) { ms.servicebot.p10.srvcreated %ms.ns.hubservernum %ms.ns.name %ms.ns.hop %ms.ns.starttime %ms.ns.linktime %ms.ns.protocol %ms.ns.maxcon %ms.ns.flags %ms.ns.desc }
  return
}

alias ms.remserver {
  if ($ms.db(read,s,$1)) { ms.db rem s $1 }
  if ($istok($ms.db(read,l,servers),$1,44)) { ms.db write l servers $remtok($ms.db(read,l,servers),$1,44) }
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

  ; TODO If only createtime is sent, this needs to be handled later maby ?
  if (!$5) { return }

  ; if + isin $3
  elseif ( $left($5,1) == $chr(43) ) { 
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
    var %ms.bc.nnum $gettok(%c,1,58)
    ms.db write l %ms.bc.nnum $addtok($ms.db(read,l,%ms.bc.nnum),%ms.bc.chan,44)
    ms.db write chhi %ms.bc.nnum $addtok($ms.db(read,chhi,%ms.bc.nnum),$+(%ms.bc.chan $ctime),44)
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
    ms.db write chhi %ms.cc.num $addtok($ms.db(read,chhi,%ms.cc.num),$+(%ch %ms.cc.timestamp),44)

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
      ms.db write chhi %ms.cj.num $addtok($ms.db(read,chhi,%ms.cj.num),$+(%ch %ms.cj.timestamp),44)
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
    if ( $numtok($ms.db(read,l,%ms.cl.num),44) <= 1 ) { ms.db rem l %ms.cl.num }
    else { ms.db write l %ms.cl.num $remtok($ms.db(read,l,%ms.cl.num),%ch,44) }
    ms.db write l channels $remtok($ms.db(read,l,channels),%ch,44)
    ms.echo blue [IAL DB] Client %ms.cl.num parted channel %ch
    ms.servicebot.p10.chparted $1 %ch $iif($3,$3,$null) $4 $5-
    dec %c
  }
  return
}

; <client numeric> :<reason>
; <client numeric> noquit
alias ms.client.quit { 
  if ( $ms.get.client(nick,$1) ) {
    var %ms.cq.num $1
    ; Check if we client is on any chans and part them 
    if ( $ms.db(read,l,%ms.cq.num) ) { var %ms.cq.chans $v1 }
    if ( %ms.cq.chans ) {
      ; when join 0 the client is not quiting, i'm using this alias to part all channels
      if ( $2 == noquit ) { 
        var %c $numtok(%ms.cq.chans,44)
        while ( %c ) {
          ms.client.part %ms.cq.num $gettok(%ms.cq.chans,%c,44)
          dec %c
        }
      }
      else {
        ; Set variable to stop spybot from reporting this client
        set -u1 %ms.client.part.quiet. $+ %ms.cq.num true
        var %c $numtok(%ms.cq.chans,44)
        while ( %c ) {
          ms.client.part %ms.cq.num $gettok(%ms.cq.chans,%c,44)
          dec %c
        }
      }
      ; Else not on any chans 
    }

    ms.servicebot.p10.quit $1 $2-

    ; Remove client and nick hisotry from database
    ms.db rem c %ms.cq.num
    ms.db rem nh %ms.cq.num

    ; var %ms.cq.srvnum $gettok($gettok($ms.db(read,c,%ms.cq.num),1,44),2,32)
    var %ms.cq.srvnum $left(%ms.cq.num,2)
    var %ms.sq.srvnum.clients $ms.db(read,l,%ms.cq.srvnum)

    ; Count number of users left on server, if this was the last one, remove list section to the server, it wil be added again when a new client joins
    if ( $numtok(%ms.sq.srvnum.clients,44) <= 1 ) { ms.db rem l %ms.cq.srvnum }
    else { ms.db write l %ms.cq.srvnum $remtok(%ms.sq.srvnum.clients,%ms.cq.num,44) }

    ms.echo blue [IAL DB] Removed client %ms.cq.num from server
  }
  else { ms.echo red [IAL DB] Client %ms.cq.num not found in database | return }
  return
}

; <client numeric> <channel> <+-modes> <arg1 arg2 arg3 arg4 etc> <timestamp>
alias ms.mode.channel { 
  var %ms.mc.num $1
  var %ms.mc.chan $2
  var %ms.mc.modes $3
  var %ms.mc.args $4-

  ms.change.channel modes %ms.mc.num %ms.mc.chan %ms.mc.modes %ms.mc.args
  ms.servicebot.p10.chanmode %ms.mc.num %ms.mc.chan %ms.mc.modes %ms.mc.args
  return
}
; <client numeric> <channel> <+-modes> <arg1 arg2 arg3 arg4 etc> <timestamp>
alias ms.opmode.channel { 
  var %ms.mc.num $1
  var %ms.mc.chan $2
  var %ms.mc.modes $3
  var %ms.mc.args $4-

  ms.change.channel modes %ms.mc.num %ms.mc.chan %ms.mc.modes %ms.mc.args
  ms.servicebot.p10.opmode %ms.mc.num %ms.mc.chan %ms.mc.modes %ms.mc.args
  return
}
; BbAC6 #testchan -v+tnklo IAAAA code 123 BdAAA 1000000000
; BdAAA #testchan +m 1000000000
; BdAAA #testchan +o IAAAX 1000000000
; BdAAA #testchan +b test!test@test.lame 1000000000
; BdAAA #testchan -mb+lo test!test@test.lame 123 BbAAC 1000000000
; modes <client numeric> <channel> <+-modes> <arg1 arg2 arg3 arg4 etc> <timestamp?>
alias ms.change.channel {
  if ( $1 == modes ) {
    if ($4) {

      var %ms.cc.num $2
      var %ms.cc.chan $3
      var %ms.cc.modes $4
      var %ms.cc.args $5-
      var %nextarg 1

      var %ms.cc.data $ms.db(read,ch,%ms.cc.chan)

      var %ms.cc.oldmode $ms.get.channel(modes,%ms.cc.chan)
      var %ms.cc.mode.new $ms.get.channel(modes,%ms.cc.chan)
      var %i 1
      var %len $len(%ms.cc.modes)

      while (%i <= %len) {

        ; Pick next char
        var %char $mid(%ms.cc.modes,%i,1)

        ; Check if next mode is + or - and set action
        if (%char == +) { var %action add }
        elseif (%char == -) { var %action remove }

        ; TODO Sometime, get modes supported from linked server somehow
        if ( %char isincs imnpstrDdRcCMPkl ) { 
          if (%action == add) { 
            ; Check if channel does not have any modes set, else add more modes
            if ( %ms.cc.oldmode == NONE ) { var %ms.cc.mode.new $+($chr(43),%char) | var %ms.cc.oldmode %ms.cc.mode.new }
            else { var %ms.cc.mode.new $+(%ms.cc.mode.new,%char) }
          }
          elseif (%action == remove) { 
            if ( $len(%ms.cc.mode.new) <= 2 ) { var %ms.cc.mode.new NONE }
            else { var %ms.cc.mode.new $remove(%ms.cc.mode.new,%char) }
          }
        }
        if ( %char === k ) {
          var %ms.cc.mode.newkey $iif(%action == add,$gettok(%ms.cc.args,%nextarg,32),NONE)
          inc %nextarg
        }
        if ( %char === l ) {
          ; Check if limit is set, ONLY then inc %nextarg, this is because -l doesnt have an arg
          if ( %action == add ) { var %ms.cc.mode.newlimit $gettok(%ms.cc.args,%nextarg,32) | inc %nextarg }
          elseif ( %action == remove ) { var %ms.cc.mode.newlimit NONE }
        }

        if ( %char === b ) {

          ; This one needs work, need to check if ban exist just to be sure, AND for now multple bans are not supported
          var %ms.cc.mode.newbans $iif(%action == add,$gettok(%ms.cc.args,%nextarg,32),NONE)
          inc %nextarg
        }
        ; ov we can check if nick exist, just to be sure
        if ( %char === o ) {
          inc %nextarg
          ; TODO update ops for client
        }
        if ( %char === v ) {
          inc %nextarg
          ; TODO update voices for client
        }
        inc %i
      }
      var %ms.cc.mode.ts $gettok(%ms.cc.args,%nextarg,32)

      ; Save key,limit,bans to the database
      if ( %ms.cc.mode.newkey ) { var %ms.cc.data $puttok(%ms.cc.data,chankey %ms.cc.mode.newkey,4,44) }
      if ( %ms.cc.mode.newlimit ) { var %ms.cc.data $puttok(%ms.cc.data,chanlimit %ms.cc.mode.newlimit,3,44) }
      if ( %ms.cc.mode.newbans ) { var %ms.cc.data $puttok(%ms.cc.data,bans %ms.cc.mode.newbans,5,44) }

      ; Finally write the new modes to the database
      ms.db write ch %ms.cc.chan $puttok(%ms.cc.data,chanmodes %ms.cc.mode.new,2,44)
      var %ms.cc.args $4
      var %ms.cc.timestamp $5
      return
    }
  }
}

; <client numeric> <client nick> <:+-modes> 
alias ms.mode.client { 
  var %ms.mc.num $1
  var %ms.mc.nick $2
  var %ms.mc.modes $mid($3,2,99)
  ms.change.client modes $1 %ms.mc.modes
  ms.servicebot.p10.clientmode %ms.mc.num %ms.mc.nick %ms.mc.modes
  return
}

; /ms.change.client nick\ident\host\modes\ac\account\auth\baseip64\realname\newnick nick-numeric <args>
alias ms.change.client {
  if ( $3 ) {
    if ( $ms.db(read,c,$2) ) { 
      var %ms.ch.c.data $v1
      if ( $1 == nick ) { ms.db write c $2 $puttok(%ms.ch.c.data,nick $3,2,44) }
      elseif ( $1 == ident ) { ms.db write c $2 $puttok(%ms.ch.c.data,ident $3,5,44) }
      elseif ( $1 == host ) { ms.db write c $2 $puttok(%ms.ch.c.data,host $3,6,44) }
      elseif ( $1 == modes ) { 
        var %ms.ch.c.mode.old $gettok($gettok(%ms.ch.c.data,7,44),2,32)
        var %ms.ch.c.mode.new %ms.ch.c.mode.old
        var %i 1
        var %len $len($3)
        while (%i <= %len) {
          var %char $mid($3,%i,1)
          if (%char == +) { var %action add }
          elseif (%char == -) { var %action remove }
          else {
            if (%action == add) { 
              if ( %ms.ch.c.mode.new == NONE ) { var %ms.ch.c.mode.new $+(+,%char) }
              else { var %ms.ch.c.mode.new $+(%ms.ch.c.mode.new,%char) }
            }
            elseif (%action == remove) { 
              if ( $len(%ms.ch.c.mode.new) <= 2 ) { var %ms.ch.c.mode.new NONE }
              else { var %ms.ch.c.mode.new $remove(%ms.ch.c.mode.new,%char,32) }
            }
          }
          inc %i
        }
        ms.db write c $2 $puttok(%ms.ch.c.data,modes %ms.ch.c.mode.new,7,44)
      }
      elseif ( $1 == ac ) { ms.db write c $2 $puttok(%ms.ch.c.data,auth $3,8,44) }
      elseif ( $1 == account ) { ms.db write c $2 $puttok(%ms.ch.c.data,auth $3,8,44) }
      elseif ( $1 == auth ) { ms.db write c $2 $puttok(%ms.ch.c.data,auth $3,8,44) }
      elseif ( $1 == base64ip ) { ms.db write c $2 $puttok(%ms.ch.c.data,base64ip $3,9,44) }
      elseif ( $1 == realname ) { ms.db write c $2 $puttok(%ms.ch.c.data,realname $3,10,44) }
      else { ms.echo red [Change client] $2 is not a valid argument }
    }
    else { ms.echo red [Change client] $1 is not a valid client numeric }
  }
  else { ms.echo red [Change client] Missing arguments }
}

; $ms.get.client(nick,clientNUMERIC) $ms.get.client(modes,clientNUMERIC) $ms.get.client(numeric,clientNICK) etc
alias ms.get.client {
  if ( $1 == numeric ) && ( $2 ) { 
    var %ms.get.clnum.i $hfind(clients,$+($chr(42),nick $2,$chr(42)),0,w).data

    ; Search for the client numeric
    while ( %ms.get.clnum.i ) {
      var %ms.get.clnum $hfind(clients,$+($chr(42),nick $2,$chr(42)),%ms.get.clnum.i,w).data
      var %ms.get.clnick $gettok($gettok($ms.db(read,c,%ms.get.clnum),2,44),2,32)

      ; Confirm we found the right nick
      if ( %ms.get.clnick == $2 ) { return %ms.get.clnum }
      dec %ms.get.clnum.i
    }
  }
  if ( $1 == oldnick ) && ( $2 ) { 
    var %ms.get.nhnum $numtok($ms.db(read,nh,$2),44)
    if ( %ms.get.nhnum >= 2 ) { return $gettok($gettok($ms.db(read,nh,$2),$calc(%ms.get.nhnum - 1),44),1,32) }
    else { return $null } 
    ; no nick history (never changed nick)
  }
  elseif ( $ms.db(read,c,$2) ) { 
    var %msgc $v1
    if ( $1 == server ) { return $gettok($gettok(%msgc,1,44),2,32) }
    elseif ( $1 = nick ) { return $gettok($gettok(%msgc,2,44),2,32) }
    elseif ( $1 == ident ) { return $gettok($gettok(%msgc,5,44),2,32) }
    elseif ( $1 == host ) { return $gettok($gettok(%msgc,6,44),2,32) }
    elseif ( $1 == modes ) { return $gettok($gettok(%msgc,7,44),2,32) }
    elseif ( $1 == ac ) { return $gettok($gettok(%msgc,8,44),2,32) }
    elseif ( $1 == account ) { return $gettok($gettok(%msgc,8,44),2,32) }
    elseif ( $1 == auth ) { return $gettok($gettok(%msgc,8,44),2,32) }
    elseif ( $1 == base64ip ) { return $gettok($gettok(%msgc,9,44),2,32) }
    elseif ( $1 == realname ) { return $gettok($gettok(%msgc,10,44),2-,32) }
    else { return $null }
  }
}

; $ms.get.channel(createtime,#chan) $ms.get.channel(chanmodes,#chan) etc
alias ms.get.channel {
  if ( $ms.db(read,ch,$2) ) { 
    var %msgc $v1
    if ( $1 == createtime ) { return $gettok($gettok(%msgc,1,44),2,32) }
    elseif ( $1 == chanmodes ) { return $gettok($gettok(%msgc,2,44),2,32) }
    elseif ( $1 == modes ) { return $gettok($gettok(%msgc,2,44),2,32) }
    elseif ( $1 == chanlimit ) { return $gettok($gettok(%msgc,3,44),2,32) }
    elseif ( $1 == limit ) { return $gettok($gettok(%msgc,3,44),2,32) }
    elseif ( $1 == chankey ) { return $gettok($gettok(%msgc,4,44),2,32) }
    elseif ( $1 == key ) { return $gettok($gettok(%msgc,4,44),2,32) }
    elseif ( $1 == bans ) { return $gettok($gettok(%msgc,5,44),2,32) }
    else { return $null }
  }
}

; 
alias ms.get.mode {
  return
}

; $ms.is(numeric\nick,#chan,on,op,voice,reg)
alias ms.is {
  if ( $1 ) {
    if ( $ms.get.channel(createtime,$2) ) { 
      if ( $ms.get.client(numeric,$1) ) { var %ms.ison.num $v1 }
      elseif ( $ms.get.client(nick,$1) ) { var %ms.ison.num $1 }
      else { ms.echo red [IsOn] $1 is not a valid client numeric or nick | return }
      var %ms.ison.nicks $ms.db(read,l,$2)
      var %ms.ison.i $numtok(%ms.ison.nicks,44)
      while ( %ms.ison.i ) {

        ; is on\op\voice\regular user check
        if ( $gettok($gettok(%ms.ison.nicks,%ms.ison.i,44),1,58) === %ms.ison.num ) {
          if ( $3 == on ) { var %ms.ison.result true }
          elseif ( $3 == op ) && ( $gettok($gettok(%ms.ison.nicks,%ms.ison.i,44),2,58) == o ) || ( $gettok($gettok(%ms.ison.nicks,%ms.ison.i,44),2,58) == vo ) { var %ms.ison.result true }
          elseif ( $3 == voice ) && ( $gettok($gettok(%ms.ison.nicks,%ms.ison.i,44),2,58) == v ) || ( $gettok($gettok(%ms.ison.nicks,%ms.ison.i,44),2,58) == vo ) { var %ms.ison.result true }
          elseif ( $3 == reg ) &&( $gettok($gettok(%ms.ison.nicks,%ms.ison.i,44),2,58) != o ) && ( $gettok($gettok(%ms.ison.nicks,%ms.ison.i,44),2,58) != v ) { var %ms.ison.result true }
        }
        dec %ms.ison.i
      }
      if ( %ms.ison.result == true ) { return true }
      else { return false }
    }
    else { ms.echo red [Is] $2 is not a existing channel | return }
  }
}

alias ms.get.server { 
  if ( $1 == numeric ) && ( $2 ) { 
    var %ms.get.srvnum.i $hfind(servers,$+($chr(42),name $2,$chr(42)),0,w).data

    ; Search for the server numeric
    while ( %ms.get.srvnum.i ) {
      var %ms.get.srvnum $hfind(servers,$+($chr(42),name $2,$chr(42)),%ms.get.srvnum.i,w).data
      var %ms.get.srvname $gettok($gettok($ms.db(read,s,%ms.get.srvnum),1,44),2,32)

      ; Confirm we found the right server
      if ( %ms.get.srvname == $2 ) { return %ms.get.srvnum }
      dec %ms.get.srvnum.i
    }
  }
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

alias ms.ison.chan {
  if ( $2 ) { 
    if ( $ms.get.client(numeric,$1) ) { var %ms.isonchan.num $v1 }
    else { var %ms.isonchan.num $1 }
    if ( $istok($ms.db(read,l,%ms.isonchan.num),$2,44) ) { return true }
    else { return false }
  }
}
alias ms.db.reset {
  ms.echo green Resetting databases
  ms.db rem s
  ms.db rem c
  ms.db rem ch
  ms.db rem l
  ms.db rem nh
  ms.db rem config
  if ( $hget(servers) ) { hfree servers | hmake -s servers 100 }
  else { hmake -s servers 100 }
  if ( $hget(clients) ) { hfree clients | hmake -s clients 10000 }
  else { hmake -s clients 10000 }
  if ( $hget(channels) ) { hfree channels | hmake -s channels 1000 }
  else { hmake -s channels 1000 }
  if ( $hget(list) ) { hfree list | hmake -s list 10000 }
  else { hmake -s list 10000 }
  if ( $hget(nickhistory) ) { hfree nickhistory | hmake -s nickhistory 10000 }
  else { hmake -s nickhistory 10000 }
  if ( $hget(chanhistory) ) { hfree chanhistory | hmake -s chanhistory 10000 }
  else { hmake -s chanhistory 10000 }
  if ( $hget(config) ) { hfree config | hmake -s config 100 }
  else { hmake -s config 100 }
  if ( $hget(fb) ) { hfree fb | hmake -s fb 1000 }
  else { hmake -s fb 1000 }
  if ( $hget(gb) ) { hfree gb | hmake -s gb 1000 }
  else { hmake -s gb 1000 }
}

alias ms.db {
  ; $ms.db(read,s,arg1)
  ; /ms.db write ch arg1 arg2+
  ; /ms.db rem\del c [arg1]
  ; TODO: add  $ms.db(search,c,num,TEXT) to search for a specific value in the database in arg1 section 
  ; TODO: Make sql support and move this variable to ms.config.ini
  var %ms.db.type hash

  if ( $2 ) {
    if ( $2 == s ) { var %db.file ms.ial.ini | var %db.topic servers | var %db.hash servers }
    elseif ( $2 == c ) { var %db.file ms.ial.ini | var %db.topic clients | var %db.hash clients }
    elseif ( $2 == ch ) { var %db.file ms.ial.ini | var %db.topic channels | var %db.hash channels }
    elseif ( $2 == l ) { var %db.file ms.ial.ini | var %db.topic list | var %db.hash list }
    elseif ( $2 == nh ) { var %db.file ms.ial.ini | var %db.topic nickhistory | var %db.hash nickhistory | var %db.history ms.history.ini }
    elseif ( $2 == chhi ) { var %db.file ms.ial.ini | var %db.topic chanhistory | var %db.hash chanhistory | var %db.history ms.history.ini }
    elseif ( $2 == config ) { var %db.file ms.ial.ini | var %db.topic config | var %db.hash config }
    elseif ( $2 == fb ) { var %db.file ms.fb.ini | var %db.topic fb | var %db.hash fb }
    elseif ( $2 == gb ) { var %db.file ms.gb.ini | var %db.topic gb | var %db.hash gb }
    else { var %db.file $+($2,.ini) | var %db.hash $2 }

    var %db.arg1 $3 ,%db.arg2 $4-

    if ( $1 = read ) {
      if ( %db.arg1 ) { 
        if ( %ms.db.type = sql ) { return $readini(%db.file,%db.topic,%db.arg1) }
        elseif ( %ms.db.type = hash ) { return $hget(%db.hash,%db.arg1) }
      }
      else { ms.echo red DB read error, missing arg1: $1- }
    }
    elseif ( $1 = write ) {
      if ( %db.arg2 ) { 
        if ( %ms.db.type = sql ) { writeini %db.file %db.topic %db.arg1 %db.arg2 }
        elseif ( %ms.db.type = hash ) { hadd %db.hash %db.arg1 %db.arg2 }

        ; This is for longterm storage of nickhistory and chanhistory, read TODO before enabling
        ;if ( $istok(chhi nh,$2,32) ) { writeini %db.history %db.topic %db.arg1 %db.arg2 ;}
      }
      ; TODO it IS possible to write empty values, but it's not possible to read them, so we might want to write empty values as NONE ? *think*
      else { ms.echo red DB write error, missing arg2: $1- }
    }
    elseif ( $1 = rem ) || ( $1 = del ) { 
      if ( %db.arg1 ) { 
        if ( %ms.db.type = sql ) { remini %db.file %db.topic %db.arg1 }
        elseif ( %ms.db.type = hash ) { hdel %db.hash %db.arg1 }
      }
      else { remini %db.file %db.topic }
    }
    elseif ( $1 == search ) {
      if ( %ms.db.type == sql ) { return }
      if ( %ms.db.type == hash ) {
        if ( $3 == num ) { return $hfind(%db.hash,$+($chr(42),$3,$chr(42)),1,w).item }
        elseif ( $hfind($2,$+($chr(42),$3,$chr(42)),1,w).data ) { return $v1 }
        else { return $null }
      }
    }
    else { ms.echo red DB error, missing read\write or rem\del: $1- }
  }

  elseif ( $1 == list ) {
    if ( %ms.db.type == sql ) { return }
    if ( %ms.db.type == hash ) { 
      var %c $hget(clients,0).data
      echo 7 $+(Total clients: %c)
      while (%c) { 
        echo -a %c $hget(clients,%c).item $hget(clients,%c).data
        dec %c
      }
      var %s $hget(servers,0).data
      echo 7 $+(Total servers: %s)
      while (%s) { 
        echo -a %s $hget(servers,%s).item $hget(servers,%s).data
        dec %s
      }
      var %ch $hget(channels,0).data
      echo 7 $+(Total channels: %ch)
      while (%ch) { 
        echo -a %ch $hget(channels,%ch).item $hget(channels,%ch).data
        dec %ch
      }

      var %l $hget(list,0).data
      echo 7 $+(Total list: %l)
      while (%l) { 
        echo -a %l $hget(list,%l).item $hget(list,%l).data
        dec %l
      }
      var %nh $hget(nickhistory,0).data
      echo 7 $+(Total nickhistory: %nh)
      while (%nh) { 

        ; TODO konvert nicknumeric from int to base64
        echo -a %nh $hget(nickhistory,%nh).item $hget(nickhistory,%nh).data
        dec %nh
      }
      var %chhistory $hget(chanhistory,0).data
      echo 7 $+(Total chanhistory: %chhistory)
      while (%chhistory) { 
        echo -a %chhistory $hget(chanhistory,%chhistory).item $hget(chanhistory,%chhistory).data
        dec %chhistory
      }
      var %l $hget(config,0).data
      echo 7 $+(Total config: %l)
      while (%l) { 
        echo -a %l $hget(config,%l).item $hget(config,%l).data
        dec %l
      }
      var %fb $hget(fb,0).data
      echo 7 $+(Total fb: %fb)
      while (%fb) { 
        echo -a %fb $hget(fb,%fb).item $hget(fb,%fb).data
        dec %fb
      }
      var %gb $hget(gb,0).data
      echo 7 $+(Total gb: %gb)
      while (%gb) { 
        echo -a %gb $hget(gb,%gb).item $hget(gb,%gb).data
        dec %gb
      }
    }
  }
  else { ms.echo red DB error, missing atleast topic: $1- }
}
