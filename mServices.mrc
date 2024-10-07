on *:unload:{ 
  sockclose mServices 
  unload -rs scripts/mIRC-Services/mServices_conf.mrc
  unload -rs scripts/mIRC-Services/mServices_base64.mrc
  unload -rs scripts/mIRC-Services/mServices_commands.mrc
}
on *:load:{ 
  load -rs scripts/mIRC-Services/mServices_conf.mrc
  load -rs scripts/mIRC-Services/mServices_base64.mrc
  load -rs scripts/mIRC-Services/mServices_commands.mrc
  echo -at Loaded mServices.mrc mServices_base64.mrc, mServices_conf.mrc and mServices_commands.mrc
}

on *:sockclose:mServices:{ ms.echo orange [Sockclose] $sockname closed }
on *:sockopen:mServices:{
  if ($sockerr > 0) {
    ms.echo orange [Sockopen] Failed to open $sockname ( $sockerr )
    return
  }
  set %ms.numeric $inttobase64($mServices.config(numeric),2)
  mServices.raw PASS $+(:,$mServices.config(password))
  mServices.raw SERVER $mServices.config(serverName) 1 $ctime $ctime J10 $+(%ms.numeric,]]]) $mServices.config(flags) $+(:,$mServices.config(info))

  ; Here burst where the bots if any should have op, this excludes hack4 messages for opers

  ; Sending END_OF_BURST
  mServices.raw %ms.numeric EB
  ms.echo green "Server is now connected with serverName $mServices.config(serverName) ( %ms.numeric )

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
  ; <numeric> <EB|EOB_ACK> <server numeric>
  if ($istok(EB EOB_ACK,$2,32) == $true) {
    mServices.sraw EA
    return
  }

  ; <SERVER> <server name> <hop count> <start time> <link time> <protocol> <server numeric\maxconn> [+flags] :<description>
  elseif ($istok(SERVER,$1,32) == $true) {
    ; This is my hub server, next S|SERVER is hop2+++ servers
    return
  }
  ; <numeric> <S|SERVER> <server name> <hop count> <start time> <link time> <protocol> <server numeric\maxconn> [+flags] :<description>
  elseif ($istok(S SERVER,$2,32) == $true) {
    ; Other servers than hub
    return
  }
 
  ; <numeric> <N|NICK> <server numeric> <nick> <hop count> <timestamp> <user> <host> <modes> <base64 ip> <numeric> :<real name>
  elseif ($istok(N NICK,$2,32) == $true) {
    ; numeric ($1) is what server the client is on
    return
  }
  ; <numeri> <B|BURST> <chan> <createtime??> <+chanmodes> BbACg,AoAAH,AzAAE,ABAAv:o,BWAAA,AzAAC,AzAAA,BdAAA
  elseif ($istok(B BURST,$2,32) == $true) {
    return
  }
  ; <client numeric> <C|CREATE> <channel> <timestamp>
  elseif ($istok(C CREATE,$2,32) == $true) {
    return
  }
  ; <client numeric> <J|JOIN> <channel> <timestamp>
  elseif ($istok(J JOIN,$2,32) == $true) {
    return
  }
  ; <client numeric> <L|LEAVE> <channel> :<reason>
  elseif ($istok(L PART,$2,32) == $true) {
    return
  }
  ; <client numeric> <M|MODE> <channel> <modes> <params\client numerics>
  elseif ($istok(M MODE,$2,32) == $true) {
    return
  }
  ; <client numeric> <K|KICK> <channel> :<kicked client numeric> (unable to show reason)
  elseif ($istok(K KICK,$2,32) == $true) {
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
  ; <numeric> TI[ME] <server numeric>
  elseif ($istok(TI TIME,$2,32) == $true) {
    mServices.sraw 391 $1 $mServices.config(serverName) $ctime 0 $+(:,$asctime($ctime,dddd mmmm dd yyyy -- HH:nn:ss))
    return
  }
}