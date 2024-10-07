; /mServices.raw <args>
alias mServices.raw {
  if ($window($mServices.window) != $null) { ms.echo orange "Raw client" $v1 [W]: $1- }
  if ($sock(mServices) != $null) { sockwrite -nt mServices $1- }
}
; /mServices.sraw <args>
alias mServices.sraw {
  if ($window($mServices.window) != $null) { ms.echo orange "Raw server" $v1 [W]: $inttobase64($mServices.config(numeric),2) $1- }
  if ($sock(mServices) != $null) { sockwrite -nt mServices $inttobase64($mServices.config(numeric),2) $1- }
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
  ; TODO, check if $mServices.config(window) exists (is active) and echo to that window
  if ( $1 == red ) { echo 4 -at <-mIRC Services-> $2- }
  elseif ( $1 == green ) { echo 3 -at <-mIRC Services-> $2- }
  elseif ( $1 == blue ) { echo 2 -at <-mIRC Services-> $2- }
  elseif ( $1 == orange ) { echo 7 -at <-mIRC Services-> $2- }
  elseif ( $1 == yellow ) { echo 8 -at <-mIRC Services-> $2- }
  else { echo -at <-mIRC Services-> $1- }
}
