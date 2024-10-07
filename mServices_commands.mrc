; /mServices.raw <args>
alias mServices.raw {
  if ($sock(mServices) != $null) { sockwrite -nt mServices $1- | ms.echo orange [Sockwrite Client] <-- $1- }
  else { ms.echo red [Sockwrite Client] <-- Server is not running | return }
}
; /mServices.sraw <args>
alias mServices.sraw {
  if ($sock(mServices) != $null) { sockwrite -nt mServices $inttobase64($mServices.config(numeric),2) $1- | ms.echo orange [Sockwrite Server] <-- $inttobase64($mServices.config(numeric),2) $1- }
  else { ms.echo red [Sockwrite Server] <-- Server is not running | return }
}

alias mServices.start {
  if ( $mServices.config(configured) == NO ) { ms.echo red Server is not configured. Please check mServices.* variables before starting the server. ( Alt + R ) | halt }
  if ($sock(mServices) != $null) { ms.echo orange Server is already running | return }

  sockopen mServices $mServices.config(hostname) $mServices.config(port)
  ms.echo green Server is now running 
  ms.echo blue Using servername: $mServices.config(serverName) and linking to hostname: $mServices.config(hostname) port: $mServices.config(port)
}
alias mServices.stop {
  if ($sock(mServices) == $null) { ms.echo orange Server is not running | return }

  sockclose $v1
  ms.echo green Stopped server
}
alias ms.echo { 
  var %ms.echo.name <mServices> 
  if ( $1 == red ) { var %echo.color 4 }
  elseif ( $1 == green ) { var %echo.color 3 }
  elseif ( $1 == blue ) { var %echo.color 2 }
  elseif ( $1 == orange ) { var %echo.color 7 }
  elseif ( $1 == yellow ) { var %echo.color 8 }
  else { var %echo.color 14 }

  if ($window($mServices.config(window)) != $null) { echo %echo.color -t $mServices.config(window) %ms.echo.name $2- }
  else { echo %echo.color -at %ms.echo.name $1- }
}
