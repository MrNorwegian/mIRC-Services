on *:load: { set %mServices.loaded.spybot true | ms.echo green Loaded mServices_spybot.mrc }
on *:unload: { unset %mServices.loaded.spybot | ms.echo red Unloaded mServices_spybot.mrc }

alias ms.spybot.makeconfig {

  ; ACCOUNT can be disabled by setting it to CHANGE_ME_TO_ENABLE

  writeini -n %mServices.config spybot configured false
  writeini -n %mServices.config spybot load spybot

  writeini -n %mServices.config spybot numeric AAB
  writeini -n %mServices.config spybot nick spybot
  writeini -n %mServices.config spybot user spybot
  writeini -n %mServices.config spybot host is.here.to.spy.on.you
  writeini -n %mServices.config spybot ip 127.0.0.1
  writeini -n %mServices.config spybot realname Nothing to see here
  writeini -n %mServices.config spybot modes +ki
  writeini -n %mServices.config spybot account CHANGE_ME_TO_ENABLE
  writeini -n %mServices.config spybot chan #spychan
  writeini -n %mServices.config spybot debugchan #debug
  writeini -n %mServices.config spybot debug false
  writeini -n %mServices.config spybot report true
  writeini -n %mServices.config spybot ignoredserver ExampleServer.myDomain.com
  writeini -n %mServices.config spybot ignorednick ExampleNickName
  writeini -n %mServices.config spybot ignoredchan #ExampleChannelName
}

alias ms.spybot.remconfig { writeini -n %mServices.config configured spybot false | remini %mServices.config spybot }

alias ms.start.spybot {
  if ( %mServices.loaded.spybot == true ) && ( $readini(%mServices.config,spybot,configured) == true ) { 
    var %ms.sb.bot $ms.config.get(load,spybot)
    ms.echo blue [mServices mIRC Services] Launching spybot: %ms.sb.bot

    ; Setting permanent variables because i think i'm going to use them a lot and it's easier to use.
    set %ms.sb. $+ %ms.sb.bot $+ .numeric $ms.config.get(numeric,%ms.sb.bot)
    set %ms.sb. $+ %ms.sb.bot $+ .nick $ms.config.get(nick,%ms.sb.bot)
    set %ms.sb. $+ $ms.config.get(numeric,%ms.sb.bot) $ms.config.get(nick,%ms.sb.bot)

    ms.servicebot.spawn $ms.config.get(nick,%ms.sb.bot) $ctime $ms.config.get(user,%ms.sb.bot) $ms.config.get(host,%ms.sb.bot) $ms.config.get(modes,%ms.sb.bot) $ms.config.get(account,%ms.sb.bot) $ms.config.get(ip,%ms.sb.bot) $ms.config.get(numeric,%ms.sb.bot) $ms.config.get(realname,%ms.sb.bot)
    ms.servicebot.join $ms.config.get(numeric,%ms.sb.bot) $+($ms.config.get(chan,%ms.sb.bot),$chr(44),$ms.config.get(debugchan,%ms.sb.bot))
  }
}

alias ms.stop.spybot { 
  if ( %mServices.loaded.spybot == true ) && ( $readini(%mServices.config,spybot,configured) == true ) { 
    ms.servicebot.despawn %ms.spybot.numeric 
  }
}

; TODO 
alias ms.spybot.isignored { 
  ; TODO, for now i'm doing lots of the same ifchecks
}
alias ms.spybot.report { 
  ; remember: %ms.status 
  ; %spr. == spybotreport * note to self *
  if ( $istok(%ms.servicebots.online,%ms.sb.spybot.nick,44)) && ( $ms.config.get(report,spybot) == true ) && ( %ms.status == linked finished ) {

    ; S %ms.ns.num %ms.ns.name %ms.ns.hop %ms.ns.starttime %ms.ns.linktime %ms.ns.protocol %ms.ns.maxcon %ms.ns.flags %ms.ns.desc
    if ( $1 === S ) { 
      return
    }

    ; N %ms.nc.num %ms.nc.nick %ms.nc.hopcount %ms.nc.timestamp %ms.nc.user %ms.nc.host %ms.nc.modes %ms.nc.auth %ms.nc.base64ip %ms.nc.num %ms.nc.realname
    elseif ( $1 === N ) { 

      ; Setting variable for servername and nick 
      var %spr.sn $gettok($gettok($ms.db(read,s,$2),1,44),2,32)
      var %spr.cn $3

      ; Checking if the server or nickname is on the ignorelist
      if ($istok($ms.config.get(ignoredserver,spybot),%spr.sn,44)) { return }
      elseif ($istok($ms.config.get(ignorednick,spybot),%spr.cn,44)) { return }
      else {
        ; Reuse %spr.sn variable to add ()
        var %spr.sn $+($chr(91),%spr.sn,$chr(93)) 

        ; Setting variable for ident@host and IP
        var %spr.idhost $+($chr(40),$6,@,$7,$chr(41))
        var %spr.base64ip $+($chr(91),$base64toip($10),$chr(93))

        ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User $ms.orange(%spr.cn %spr.idhost) %spr.base64ip * $12- Connected to $ms.yellow(%spr.sn)
      }

      ; Server is on the ignorelist, do nothing for now
      else { return }
    }

    ; <client numeric> <new nick>
    elseif ( $1 === NewNick ) { 
      var %spr.nn $3
      var %spr.cn $ms.get.client(oldnick,$2)
      var %spr.sn $ms.get.server(name,$left($2,2))

      ; Checking if the server or nickname is on the ignorelist
      if ($istok($ms.config.get(ignoredserver,spybot),%spr.sn,44)) { return }
      elseif ($istok($ms.config.get(ignorednick,spybot),%spr.cn,44)) || ($istok($ms.config.get(ignorednick,spybot),%spr.nn,44)) { return }
      else {
        var %spr.idhost $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
        ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User %spr.cn %spr.idhost changed nick to: %spr.nn
        return
      }
    }

    ; <Server numeric> <client numeric> <account accountid>
    elseif ( $1 === AC ) { 
      echo -a DEBUG $1-
      var %spr.sn $2
      var %spr.cn $3
      var %spr.acc $4
      var %spr.nick $ms.get.client(nick,%spr.cn)
      var %spr.idhost $+($chr(40),$ms.get.client(ident,%spr.cn),@,$ms.get.client(host,%spr.cn),$chr(41))
      var %spr.base64ip $+($chr(91),$base64toip($ms.get.client(base64ip,%spr.cn)),$chr(93))
      ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User %spr.nick %spr.idhost %spr.base64ip * $ms.get.client(realname,%spr.cn) Authenticated as: %spr.acc
      return
    }

    ; C <client numeric> <channel>
    elseif ( $1 === C ) {

      ; Setting variable for servername, nick, channel $gettok($gettok($ms.db(read,s,$2),1,44),2,32)
      var %spr.cn $ms.get.client(nick,$2)
      var %spr.sn $ms.get.server(name,$left($2,2))
      var %spr.ch $3

      ; Checking if the server or nickname is on the ignorelist
      if ($istok($ms.config.get(ignoredchan,spybot),%spr.sn,44)) { return }
      elseif ($istok($ms.config.get(ignorednick,spybot),%spr.cn,44)) { return }
      else {
        ; Ident@host
        var %spr.idhost $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
        ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User %spr.cn %spr.idhost created channel: %spr.ch
        return
      }
    }

    ; J %ms.cj.num %ms.cj.chan
    elseif ( $1 === J ) { 

      ; Setting variable for servername, nick, channel
      var %spr.cn $ms.get.client(nick,$2)
      var %spr.sn $ms.get.server(name,$left($2,2))
      var %spr.ch $3

      ; Checking if the servername, nickname or channelname is on the ignorelist
      if ($istok($ms.config.get(ignoredserver,spybot),%spr.sn,44)) { return }
      elseif ($istok($ms.config.get(ignorednick,spybot),%spr.cn,44)) { return }
      elseif ($istok($ms.config.get(ignoredchan,spybot),%spr.ch,44)) { return }

      ; Not in ignorelist
      else {
        var %spr.jn $ms.get.client(nick,$2) $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
        ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User %spr.jn joined channel: %spr.ch
      }

      ; Server,channelname or nickname is on the ignorelist, do nothing for now
      else { return }

    }

    ; L %ms.cl.num %ms.cl.chan
    elseif ( $1 === L ) && ( %ms.client.part.quiet. [ $+ [ $2 ] ] != true ) { 

      ; Setting variable for servername, nick, channel
      var %spr.cn $ms.get.client(nick,$2)
      var %spr.sn $ms.get.server(name,$left($2,2))
      var %spr.ch $3

      ; Checking if the servername, nickname or channelname is on the ignorelist
      if ($istok($ms.config.get(ignoredserver,spybot),%spr.sn,44)) { return }
      elseif ($istok($ms.config.get(ignorednick,spybot),%spr.cn,44)) { return }
      elseif ($istok($ms.config.get(ignoredchan,spybot),%spr.ch,44)) { return }

      ; Not in ignorelist
      else {
        var %spr.pn $ms.get.client(nick,$2) $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
        ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User %spr.pn parted channel: %spr.ch
      }

      ; Server,channelname or nickname is on the ignorelist, do nothing for now
      else { return }
    }

    ; Q clientnum reason
    elseif ( $1 === Q ) { 

      ; Setting variable for servername, nick, channel
      var %spr.sn $ms.get.server(name,$ms.get.client(server,$2))
      var %spr.cn $ms.get.client(nick,$2)

      ; Checking if the servername or nickname is on the ignorelist
      if ($istok($ms.config.get(ignoredserver,spybot),%spr.sn,44)) { return }
      elseif ($istok($ms.config.get(ignorednick,spybot),%spr.cn,44)) { return }

      ; Not in ignorelist
      else {
        ; Reusing %spr.sn to add some ()
        var %spr.sn $+($chr(91),%spr.sn,$chr(93)) 

        ; Setting variable for ident@host and IP
        var %spr.idhost $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
        var %spr.base64ip $+($chr(91),$base64toip($ms.get.client(base64ip,$2)),$chr(93))

        ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User $ms.orange(%spr.cn %spr.idhost) %spr.base64ip * $ms.get.client(realname,$2) Disconnected from $ms.yellow(%spr.sn) With reason: $3-
      }
      ; Server or nickname is on the ignorelist, do nothing for now
      else { return }
    }
    ; K %ms.ck.num %ms.ck.chan %ms.ck.reason
    ; <client numeric> <K|KICK> <channel> <target nicknumeric> :reason
    ; K num chan kicked bynum reason
    elseif ( $1 === K ) { 

      ; Setting variable for servername, nick, channel
      var %spr.sn $ms.get.server(name,$ms.get.client(server,$2))
      var %spr.cn $ms.get.client(nick,$5)
      var %spr.ch $3

      ; Checking if the servername, nickname or channelname is on the ignorelist
      if ($istok($ms.config.get(ignoredserver,spybot),%spr.sn,44)) { return }
      elseif ($istok($ms.config.get(ignorednick,spybot),%spr.cn,44)) { return }
      elseif ($istok($ms.config.get(ignoredchan,spybot),%spr.ch,44)) { return }

      ; Not in ignore list
      else { 
        var %spr.kn $ms.get.client(nick,$2) $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
        var %spr.chan $3
        var %spr.kby $ms.get.client(nick,$5) $+($chr(40),$ms.get.client(ident,$5),@,$ms.get.client(host,$5),$chr(41))
        ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User %spr.kn was kicked from %spr.chan by %spr.kby with reason: $6-
        return
      }
    }

    ; M <client numeric> <channel> <+-modes> <arg1 arg2 arg3 arg4 etc> <timestamp>
    elseif ( $1 === M ) && ($5) {

      ; Setting variable for servername, nick, channel
      ; ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) $2 ison $ms.get.client(server,$2) num: $ms.get.server(name,$ms.get.client(server,$2))

      if ( $ms.get.client(nick,$2) ) { 
        var %spr.cn $v1
        var %spr.idhost $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
        var %spr.sn $ms.get.server(name,$ms.get.client(server,$2))
      }
      elseif ( $ms.get.server(name,$2) ) { var %spr.msrv $v1 }
      else { ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) naka I dont know what to do!! - $1- | return }      

      var %spr.ch $3

      ; Checking if the servername, nickname or channelname is on the ignorelist
      if ($istok($ms.config.get(ignoredserver,spybot),%spr.sn,44)) { return }
      elseif ($istok($ms.config.get(ignorednick,spybot),%spr.cn,44)) { return }
      elseif ($istok($ms.config.get(ignoredchan,spybot),%spr.ch,44)) { return }

      ; Extra check for checking servername setting mode
      elseif ($istok($ms.config.get(ignoredserver,spybot),%spr.msrv,44)) { return }

      ; Not in ignorelist
      else {
        var %spr.mnum $2
        var %spr.mchan $3
        var %spr.mmodes $4
        var %spr.newmodes $ms.get.channel(modes,$3)

        ; Removing "timestamp" from args and saving it to own variable
        var %spr.mc.i $numtok($4-,32)
        var %spr.mc.x 1
        while ( %spr.mc.i > %spr.mc.x ) {
          if ( $gettok($5-,%spr.mc.x,32) = 1000000000 ) { var %spr.mtimestamp $gettok($5-,%spr.mc.x,32) }
          elseif ( $ms.get.client(nick,$gettok($5-,%spr.mc.x,32)) ) { var %spr.margs $addtok(%spr.margs,$v1,32) }
          else { var %spr.mextraargs $addtok(%spr.mextraargs,$gettok($5-,%spr.mc.x,32),32) }
          inc %spr.mc.x
        }
        if ( %spr.cn ) { ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User %spr.cn %spr.idhost set modes: %spr.mmodes %spr.margs $iif(%spr.mextraargs,Args: %spr.mextraargs,$null) $+($chr(40),%spr.newmodes,$chr(41)) in %spr.mchan }
        elseif ( %spr.msrv ) { ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) Server %spr.msrv set modes: %spr.mmodes %spr.margs $iif(%spr.mextraargs,Args: %spr.mextraargs,$null) $+($chr(40),%spr.newmodes,$chr(41)) in %spr.mchan }
      }
    }
    ; M <client numeric> <target nick> <modes>
    elseif ( $1 === M ) && (!$5) {  
      var %spr.mnum $2
      var %spr.cn $3
      var %spr.idhost $+($chr(40),$ms.get.client(ident,$2),@,$ms.get.client(host,$2),$chr(41))
      var %spr.mnewmodes $ms.get.client(modes,$2)
      var %spr.mmodes $4
      ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(chan,spybot) User %spr.cn %spr.idhost set modes: %spr.mmodes $+($chr(40),%spr.mnewmodes,$chr(41))
      return
    }
  }
}

; Spybot debug channel reporting
alias ms.spybot.debug { 
  if ( $ms.config.get(report,spybot) == true ) && ( %ms.status == linked finished ) { 
    ms.servicebot.say %ms.sb.spybot.numeric $ms.config.get(debugchan,spybot) $1-
  }
}

; <client numeric> <targetchan\targetclient numeric> :<message>
alias ms.spybot.privmsg { 
  if ( $ms.config.get(chan,spybot) == $2 ) {
    var %ms.sp.pmsg.cmd $mid($3,2,9999)
    var %ms.sp.pmsg.msg $4-

    ; todo rename nickchan to something shorter
    var %ms.sp.pmsg.nickchan %ms.sb.spybot.numeric $2

    ; !report ignored add\rem\del\list <name>
    ; use $ms.config.write(ignorednick,nick) 
    if ( $istok(!report,%ms.sp.pmsg.cmd,32) ) { 
      var %ms.sp.ignore.errormsg Use !report ignore
      if ( $gettok(%ms.sp.pmsg.msg,1,32) == ignore ) {
        var %ms.sp.ignore.errormsg Missing <name> - Use !report ignore list\add\remove server\chan\nick <name> 
        if ( $istok(server servers,$gettok(%ms.sp.pmsg.msg,3,32),32) ) { var %ms.sp.ignore.arg2 ignoredserver ,%ms.sp.ignore.type Server }
        elseif ( $istok(chan channel chans,$gettok(%ms.sp.pmsg.msg,3,32),32) ) { var %ms.sp.ignore.arg2 ignoredchan ,%ms.sp.ignore.type Channel }
        elseif ( $istok(nick nicks,$gettok(%ms.sp.pmsg.msg,3,32),32) ) { var %ms.sp.ignore.arg2 ignorednick ,%ms.sp.ignore.type Nick }
        else { ms.servicebot.say %ms.sp.pmsg.nickchan %ms.sp.ignore.errormsg | return }

        ; Check if we are dealing with a server, channel or nick
        if ( $gettok(%ms.sp.pmsg.msg,4,32) ) {
          var %ms.sp.is.arg4 $v1
          if ( $gettok(%ms.sp.pmsg.msg,2,32) == add ) { 
            ; Check if already added
            if (!$istok($ms.config.get(%ms.sp.ignore.arg2,spybot),%ms.sp.is.arg4,44)) {
              ms.config.write %ms.sp.ignore.arg2 spybot $+($ms.config.get(%ms.sp.ignore.arg2,spybot),$chr(44),%ms.sp.is.arg4)
              ms.config.cache.reload spybot
              ms.servicebot.say %ms.sp.pmsg.nickchan %ms.sp.ignore.type %ms.sp.is.arg4 added to ignorelist.

              ; Loop through all ignored servers,channels,nicks and display them
              var %ms.sp.is.num $numtok($ms.config.get(%ms.sp.ignore.arg2,spybot),44)
              ms.servicebot.say %ms.sp.pmsg.nickchan Total ignored $+(%ms.sp.ignore.type,:) %ms.sp.is.num
              while ( %ms.sp.is.num ) {
                var %ms.sp.is.targ4 $gettok($ms.config.get(%ms.sp.ignore.arg2,spybot),%ms.sp.is.num,44)
                ms.servicebot.say %ms.sp.pmsg.nickchan Ignored $+(%ms.sp.ignore.type,:) %ms.sp.is.targ4
                dec %ms.sp.is.num
              }
            }
            else { ms.servicebot.say %ms.sp.pmsg.nickchan %ms.sp.ignore.type %ms.sp.is.arg4 already in ignorelist. }
          }
          elseif ( $istok(rem remove del delete,$gettok(%ms.sp.pmsg.msg,2,32),32) ) { 
            ; Check if already added
            if ($istok($ms.config.get(%ms.sp.ignore.arg2,spybot),%ms.sp.is.arg4,44)) {
              ms.config.write %ms.sp.ignore.arg2 spybot $remtok($ms.config.get(%ms.sp.ignore.arg2,spybot),%ms.sp.is.arg4,44)
              ms.config.cache.reload spybot
              ms.servicebot.say %ms.sp.pmsg.nickchan %ms.sp.ignore.type %ms.sp.is.arg4 removed from ignorelist.

              ; Loop through all ignored servers,channels,nicks and display them
              var %ms.sp.is.num $numtok($ms.config.get(%ms.sp.ignore.arg2,spybot),44)
              ms.servicebot.say %ms.sp.pmsg.nickchan Total ignored $+(%ms.sp.ignore.type:) %ms.sp.is.num
              while ( %ms.sp.is.num ) {
                var %ms.sp.is.targ4 $gettok($ms.config.get(%ms.sp.ignore.arg2,spybot),%ms.sp.is.num,44)
                ms.servicebot.say %ms.sp.pmsg.nickchan Ignored $+(%ms.sp.ignore.type:) %ms.sp.is.targ4
                dec %ms.sp.is.num
              }
            }
            else { ms.servicebot.say %ms.sp.pmsg.nickchan %ms.sp.ignore.type %ms.sp.is.srv not in ignorelist. }
          }
          else { ms.servicebot.say %ms.sp.pmsg.nickchan %ms.sp.ignore.errormsg | return }
        }
        elseif ( $gettok(%ms.sp.pmsg.msg,2,32) == list ) { 
          ; Loop through all ignored servers,channels,nicks and display them
          var %ms.sp.is.num $numtok($ms.config.get(%ms.sp.ignore.arg2,spybot),44)
          ms.servicebot.say %ms.sp.pmsg.nickchan Total ignored $+(%ms.sp.ignore.type:) %ms.sp.is.num
          while ( %ms.sp.is.num ) {
            var %ms.sp.is.tsrv $gettok($ms.config.get(%ms.sp.ignore.arg2,spybot),%ms.sp.is.num,44)
            ms.servicebot.say %ms.sp.pmsg.nickchan Ignored $+(%ms.sp.ignore.type:) %ms.sp.is.tsrv
            dec %ms.sp.is.num
          }
        }
        else { ms.servicebot.say %ms.sp.pmsg.nickchan %ms.sp.ignore.errormsg }
      }
      else { ms.servicebot.say %ms.sp.pmsg.nickchan What ? }
    }

    ; Nickhistory
    if ( $istok(!nickhistory !nh,%ms.sp.pmsg.cmd,32) ) { 
      if ( %ms.sp.pmsg.msg ) { 
        ; If arg1 is nick
        if ( $ms.get.client(numeric,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.nh.num $v1
          var %ms.sb.nh.i $numtok($ms.db(read,nh,$v1),44)
        }
        ; elseif arg1 is nicknumeric
        elseif ( $ms.get.client(nick,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.nh.num %ms.sp.pmsg.msg
          var %ms.sb.nh.i $numtok($ms.db(read,nh,%ms.sp.pmsg.msg),44)
        }
        if (%ms.sb.nh.num) { 
          ms.servicebot.say %ms.sp.pmsg.nickchan Nick history for: $ms.get.client(nick,%ms.sb.nh.num) $+($chr(40),%ms.sb.nh.num,$chr(41))
          ms.servicebot.say %ms.sp.pmsg.nickchan Number of nicks: %ms.sb.nh.i
          while ( %ms.sb.nh.i ) {
            ms.servicebot.say %ms.sp.pmsg.nickchan Nick: $gettok($gettok($ms.db(read,nh,%ms.sb.nh.num),%ms.sb.nh.i,44),1,32) at $asctime($gettok($gettok($ms.db(read,nh,%ms.sb.nh.num),%ms.sb.nh.i,44),2,32),dd mmm yyyy hh:mm:ss)
            dec %ms.sb.nh.i
          }
        }
        else { ms.servicebot.say %ms.sp.pmsg.nickchan No such nick or nicknumeric found in database | return }
      }
      else { ms.servicebot.say %ms.sp.pmsg.nickchan Use !nickhistory <nick\nicknumeric> to get the nick history of a user }
    }

    ; Chanhistory !ch or !chanhistory <nick> use $ms.db(read,chanhistory,%ms.sp.pmsg.msg) to get channels
    if ( $istok(!chanhistory !ch,%ms.sp.pmsg.cmd,32) ) { 
      if ( %ms.sp.pmsg.msg ) { 
        ; If arg1 is nick
        if ( $ms.get.client(numeric,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.ch.num $v1
          var %ms.sb.ch.i $numtok($ms.db(read,chanhistory,$v1),44)
        }
        ; elseif arg1 is nicknumeric
        elseif ( $ms.get.client(nick,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.ch.num %ms.sp.pmsg.msg
          var %ms.sb.ch.i $numtok($ms.db(read,chanhistory,%ms.sp.pmsg.msg),44)
        }
        if (%ms.sb.ch.num) { 
          ms.servicebot.say %ms.sp.pmsg.nickchan Channel history for: $ms.get.client(nick,%ms.sb.ch.num) $+($chr(40),%ms.sb.ch.num,$chr(41))
          ms.servicebot.say %ms.sp.pmsg.nickchan Number of channels: %ms.sb.ch.i
          while ( %ms.sb.ch.i ) {
            ms.servicebot.say %ms.sp.pmsg.nickchan Channel: $gettok($gettok($ms.db(read,chanhistory,%ms.sb.ch.num),%ms.sb.ch.i,44),1,32) at $asctime($gettok($gettok($ms.db(read,chanhistory,%ms.sb.ch.num),%ms.sb.ch.i,44),2,32),dd mmm yyyy hh:mm:ss)
            dec %ms.sb.ch.i
          }
        }
        else { ms.servicebot.say %ms.sp.pmsg.nickchan No such nick or nicknumeric found in database | return }
      }
      else { ms.servicebot.say %ms.sp.pmsg.nickchan Use !chanhistory <nick\nicknumeric> to get the channel history of a user }
    } 

    ; whois
    if ( $istok(!whois !w,%ms.sp.pmsg.cmd,32) ) { 
      if ( %ms.sp.pmsg.msg ) { 
        if ( $ms.get.client(numeric,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.wn.num $v1
        }
        elseif ( $ms.get.client(nick,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.wn.num %ms.sp.pmsg.msg
        }
        if ( %ms.sb.wn.num ) { 
          var %ms.sb.wn.chans $ms.db(read,l,%ms.sb.wn.num)
          var %ms.sb.wn.i $numtok(%ms.sb.wn.chans,44)
          ; check if +s mode is set on every channel
          while ( %ms.sb.wn.i ) {
            var %c $gettok(%ms.sb.wn.chans,%ms.sb.wn.i,44)
            var %m $ms.get.channel(modes,%c)

            ; For now, nothing more is done, but in the future after modes is saved to the database, we can check if +s is set on every channel and display it in the whois
            dec %ms.sb.wn.i
          }
          ms.servicebot.say %ms.sp.pmsg.nickchan Whois info for: $ms.get.client(nick,%ms.sb.wn.num) $+($chr(40),%ms.sb.wn.num,$chr(41))
          ms.servicebot.say %ms.sp.pmsg.nickchan Userinfo: $+($ms.get.client(ident,%ms.sb.wn.num),@,$ms.get.client(host,%ms.sb.wn.num)) $+($chr(40),$base64toip($ms.get.client(base64ip,%ms.sb.wn.num)),$chr(41))
          ms.servicebot.say %ms.sp.pmsg.nickchan Realname: $ms.get.client(realname,%ms.sb.wn.num)
          ms.servicebot.say %ms.sp.pmsg.nickchan Channels: $replace($ms.db(read,l,%ms.sb.wn.num),$chr(44),$chr(32))
          ms.servicebot.say %ms.sp.pmsg.nickchan Server: $ms.get.server(name,$ms.get.client(server,%ms.sb.wn.num)) $+($chr(40),$ms.get.client(server,%ms.sb.wn.num),$chr(41))
          ms.servicebot.say %ms.sp.pmsg.nickchan Modes: $ms.get.client(modes,%ms.sb.wn.num)
          ms.servicebot.say %ms.sp.pmsg.nickchan Account: $ms.get.client(account,%ms.sb.wn.num)
        }
        else { ms.servicebot.say %ms.sp.pmsg.nickchan No such nick or nicknumeric found in database | return }

      }
      else { ms.servicebot.say %ms.sp.pmsg.nickchan Use !whois <nick\nicknumeric> to get the whois information of a user }
    }

    ; who #chan
    if ( $istok(!who,%ms.sp.pmsg.cmd,32) ) { 
      if ( %ms.sp.pmsg.msg ) { 

        ; Check if we are doing !who server or !who #channel
        if ( $ms.get.channel(createtime,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.who.chan %ms.sp.pmsg.msg
          var %ms.sb.who.nicks $ms.db(read,l,%ms.sb.who.chan)
          var %ms.sb.who.i $numtok(%ms.sb.who.nicks,44)
          while (%ms.sb.who.i) {
            if ( $gettok($gettok(%ms.sb.who.nicks,%ms.sb.who.i,44),2,58) == vo ) {
              var %ms.sb.who.nicknum $gettok($gettok(%ms.sb.who.nicks,%ms.sb.who.i,44),1,58)
              var %ms.sb.who.nickchmode voicedoped
            }
            elseif ( $gettok($gettok(%ms.sb.who.nicks,%ms.sb.who.i,44),2,58) == o ) {
              var %ms.sb.who.nicknum $gettok($gettok(%ms.sb.who.nicks,%ms.sb.who.i,44),1,58)
              var %ms.sb.who.nickchmode oped
            }
            elseif ( $gettok($gettok(%ms.sb.who.nicks,%ms.sb.who.i,44),2,58) == v ) {
              var %ms.sb.who.nicknum $gettok($gettok(%ms.sb.who.nicks,%ms.sb.who.i,44),1,58)
              var %ms.sb.who.nickchmode voiced
            }
            else { 
              var %ms.sb.who.nicknum $gettok(%ms.sb.who.nicks,%ms.sb.who.i,44)
              var %ms.sb.who.nickchmode normal
            }
            var %ms.sb.who.nick $+($replace(%ms.sb.who.nickchmode,voicedoped,@+,oped,@,voiced,+,normal,$null),$ms.get.client(nick,%ms.sb.who.nicknum))
            var %ms.sb.who.identhost $+($ms.get.client(ident,%ms.sb.who.nicknum),@,$ms.get.client(host,%ms.sb.who.nicknum))
            var %ms.sb.who.base64ip $base64toip($ms.get.client(base64ip,%ms.sb.who.nicknum))
            var %ms.sb.who.realname $ms.get.client(realname,%ms.sb.who.nicknum)
            var %ms.sb.who.modes $ms.get.client(modes,%ms.sb.who.nicknum)
            var %ms.sb.who.account $ms.get.client(account,%ms.sb.who.nicknum)
            ms.servicebot.say %ms.sp.pmsg.nickchan User %ms.sb.who.i $+ : %ms.sb.who.nick $+($chr(40),%ms.sb.who.nicknum,$chr(41)) %ms.sb.who.identhost $+($chr(40),%ms.sb.who.base64ip,$chr(41)) * %ms.sb.who.realname Modes: %ms.sb.who.modes Account: %ms.sb.who.account
            dec %ms.sb.who.i
          }
        }
        elseif ( $ms.get.server(numeric,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.who.srvnum $v1
          var %ms.sb.who.server %ms.sp.pmsg.msg
          var %ms.sb.who.nicks $ms.db(read,l,%ms.sb.who.srvnum)
          var %ms.sb.who.i $numtok(%ms.sb.who.nicks,44)
          while (%ms.sb.who.i) {
            var %ms.sb.who.nicknum $gettok($gettok(%ms.sb.who.nicks,%ms.sb.who.i,44),1,32)
            var %ms.sb.who.nick $ms.get.client(nick,%ms.sb.who.nicknum)
            var %ms.sb.who.identhost $+($ms.get.client(ident,%ms.sb.who.nicknum),@,$ms.get.client(host,%ms.sb.who.nicknum))
            var %ms.sb.who.base64ip $base64toip($ms.get.client(base64ip,%ms.sb.who.nicknum))
            var %ms.sb.who.realname $ms.get.client(realname,%ms.sb.who.nicknum)
            var %ms.sb.who.modes $ms.get.client(modes,%ms.sb.who.nicknum)
            var %ms.sb.who.account $ms.get.client(account,%ms.sb.who.nicknum)
            ms.servicebot.say %ms.sp.pmsg.nickchan User %ms.sb.who.i $+ : %ms.sb.who.nick $+($chr(40),%ms.sb.who.nicknum,$chr(41)) %ms.sb.who.identhost $+($chr(40),%ms.sb.who.base64ip,$chr(41)) * %ms.sb.who.realname Modes: %ms.sb.who.modes Account: %ms.sb.who.account
            dec %ms.sb.who.i
          }
        }

        ; TODO !who * for all clients on the network
        elseif ( $istok(*,%ms.sp.pmsg.msg,32) ) { 
          ms.servicebot.say %ms.sp.pmsg.nickchan Not implemented yet
        }
        else { ms.servicebot.say %ms.sp.pmsg.nickchan No such channel found in database | return }
      }
      else { ms.servicebot.say %ms.sp.pmsg.nickchan Use !who <#channel\servername> to get the who information of a channel }
    }

    ; !list server\client\channels
    elseif ( $istok(!list,%ms.sp.pmsg.cmd,32) ) { 

      if ( %ms.sp.pmsg.msg == servers ) { 
        var %ms.sb.l.servers $ms.db(read,l,servers)
        var %ms.sb.l.i $numtok(%ms.sb.l.servers,44)
        while ( %ms.sb.l.i ) {
          var %ms.sb.l.srvnum $gettok(%ms.sb.l.servers,%ms.sb.l.i,44)
          var %ms.sb.l.srvname $ms.get.server(name,%ms.sb.l.srvnum)
          ms.servicebot.say %ms.sp.pmsg.nickchan Server: %ms.sb.l.srvname $+($chr(40),%ms.sb.l.srvnum,$chr(32),$base64toint(%ms.sb.l.srvnum),$chr(41))
          dec %ms.sb.l.i
        }
      }

      elseif ( %ms.sp.pmsg.msg == channels ) { 
        var %ms.sb.l.channels $ms.db(read,l,channels)
        var %ms.sb.l.i $numtok(%ms.sb.l.channels,44)
        while ( %ms.sb.l.i ) {
          var %ms.sb.l.chan $gettok(%ms.sb.l.channels,%ms.sb.l.i,44)
          var %ms.sb.l.channame $ms.get.channel(name,%ms.sb.l.chan)
          ms.servicebot.say %ms.sp.pmsg.nickchan Channel: %ms.sb.l.channame $+($chr(40),%ms.sb.l.chan,$chr(41))
          dec %ms.sb.l.i
        }
      }

      elseif ( %ms.sp.pmsg.msg == clients ) {
        echo OK
        var %ms.sb.l.i $hget(clients,0).data
        while ( %ms.sb.l.i ) {
          var %ms.sb.l.tmp $hget(clients,%ms.sb.l.i).item
          var %ms.sb.l.clientnum %ms.sb.l.tmp
          var %ms.sb.l.clientnick $ms.get.client(nick,%ms.sb.l.tmp)
          var %ms.sb.l.clientidenthost $+($ms.get.client(ident,%ms.sb.l.tmp),@,$ms.get.client(host,%ms.sb.l.tmp))
          var %ms.sb.l.clientbase64ip $base64toip($ms.get.client(base64ip,%ms.sb.l.tmp))
          var %ms.sb.l.clientrealname $ms.get.client(realname,%ms.sb.l.tmp)
          var %ms.sb.l.clientmodes $ms.get.client(modes,%ms.sb.l.tmp)
          var %ms.sb.l.clientaccount $ms.get.client(account,%ms.sb.l.tmp)
          var %ms.sb.l.clientserver $ms.get.server(name,$ms.get.client(server,%ms.sb.l.tmp))
          ms.servicebot.say %ms.sp.pmsg.nickchan Client: $+($chr(40),%ms.sb.l.clientnum,$chr(41)) %ms.sb.l.clientnick %ms.sb.l.clientidenthost $+($chr(40),%ms.sb.l.clientbase64ip,$chr(41)) * %ms.sb.l.clientrealname Modes: %ms.sb.l.clientmodes Account: %ms.sb.l.clientaccount Server: %ms.sb.l.clientserver
          dec %ms.sb.l.i
        }
      }
    }
    if ( $istok(!chaninfo,%ms.sp.pmsg.cmd,32) ) { 
      if ( %ms.sp.pmsg.msg ) { 
        if ( $ms.get.channel(createtime,%ms.sp.pmsg.msg) ) { 
          var %ms.sb.ci.chan %ms.sp.pmsg.msg
          var %ms.sb.ci.created $ms.get.channel(createtime,%ms.sp.pmsg.msg)
          var %ms.sb.ci.chanmodes $ms.get.channel(modes,%ms.sp.pmsg.msg)
          var %ms.sb.ci.chanusers $ms.db(read,l,%ms.sp.pmsg.msg)

          ; var %ms.sb.ci.chanusers $ms.db(read,l,%ms.sb.ci.chan)
          ms.servicebot.say %ms.sp.pmsg.nickchan Channel: %ms.sb.ci.chan $+($chr(40),%ms.sb.ci.chan,$chr(41)) Created: $asctime(%ms.sb.ci.created,dd mmm yyyy hh:mm:ss)
          ms.servicebot.say %ms.sp.pmsg.nickchan Modes set: %ms.sb.ci.chanmodes
          ; Count number of users with :o and :v, plus without :* 
          var %ms.sb.ci.i $numtok(%ms.sb.ci.chanusers,44)
          var %ms.sb.ci.o 0
          var %ms.sb.ci.v 0
          var %ms.sb.ci.r 0
          while ( %ms.sb.ci.i ) {
            if ( $gettok($gettok(%ms.sb.ci.chanusers,%ms.sb.ci.i,44),2,58) == o ) { inc %ms.sb.ci.o }
            elseif ( $gettok($gettok(%ms.sb.ci.chanusers,%ms.sb.ci.i,44),2,58) == v ) { inc %ms.sb.ci.v }
            else { inc %ms.sb.ci.r }
            dec %ms.sb.ci.i
          }
          ms.servicebot.say %ms.sp.pmsg.nickchan Users: $numtok(%ms.sb.ci.chanusers,44) Ops: %ms.sb.ci.o Voices: %ms.sb.ci.v Normals: %ms.sb.ci.r
        }
        else { ms.servicebot.say %ms.sp.pmsg.nickchan No such channel }
      }
      else { ms.servicebot.say %ms.sp.pmsg.nickchan Use !chaninfo <#channel> to get the channel information }
    }
    return
  }
}
