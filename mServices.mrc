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

on *:sockclose:mServices:{ ms.echo orange "Sockclose" $v1 [C]: $sockname closed }
on *:sockopen:mServices:{
  if ($sockerr > 0) {
    ms.echo orange "Sockopen" $v1 [E]: failed to open $sockname
    return
  }
  var %this.numeric = $inttobase64($mServices.config(numeric),2)
  mServices.raw PASS $+(:,$mServices.config(password))
  mServices.raw SERVER $mServices.config(serverName) 1 $ctime $ctime J10 $+(%this.numeric,]]]) $mServices.config(flags) $+(:,$mServices.config(info))

  mServices.raw %this.numeric EB
  ms.echo green "Server is now connected with serverName $mServices.config(serverName) ( %this.numeric )

}
on *:sockread:mServices:{
  var %mServices.sockRead = $null
  sockread %mServices.sockRead
  tokenize 32 %mServices.sockRead

  ms.echo orange "Sockread" $v1 [R]: $1-
  if ($sockerr > 0) {
    sockclose $sockname
    return
  }
  ; <numeric> <F|INFO> <server numeric>
  if ($istok(F INFO,$2,32) == $true) {
    mServices.sraw 371 $1 $+(:,$mServices.config(serverName))
    mServices.sraw 371 $1 $+(:,$mServices.config(info))
    mServices.sraw 374 $1 :End of /INFO list.
    return
  }
  ; <numeric> <G|PING> [:]<arg>
  if ($istok(G PING,$2,32) == $true) {
    mServices.sraw Z $3-
    return
  }
  ; <numeric> MO[TD] <server numeric>
  if ($istok(MO MOTD,$2,32) == $true) {
    mServices.sraw 422 $1 :MOTD File is missing
    return
  }
  ; <numeric> TI[ME] <server numeric>
  if ($istok(TI TIME,$2,32) == $true) {
    mServices.sraw 391 $1 $mServices.config(serverName) $ctime 0 $+(:,$asctime($ctime,dddd mmmm dd yyyy -- HH:nn:ss))
    return
  }
}