on *:load: { ms.echo green Loaded mServices_base64.mrc }
on *:unload: { ms.echo red Unloaded mServices_base64.mrc }

alias -l i { return $calc($poscs(ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[],$1)-1) }
alias -l ii { return $mid(ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789[],$calc($int($1) + 1),1) }

; $base64toint(<N>)
alias base64toint {
  var %o = 0, %x = 1
  while ($mid($1,%x,1) != $null) { 
    var %o = $calc(%o * 64)
    var %o = $calc(%o + $i($v1))
    inc %x
  }
  return %o
}

; $inttobase64(<N>,<pad to N chars>)
alias inttobase64 {
  var %c = $2, %o, %v = $1
  while (%c) {
    var %o = $+($ii($and(%v,63)),%o)
    var %v = $calc(%v / 64) 
    dec %c
  }
  return %o
}
alias ms.picknumeric { 
  var %tmpnumeric %ms.client.numeric
  inc %ms.client.numeric
  return $+($inttobase64($mServices.config(numeric),2),$inttobase64(%tmpnumeric,3)) 
}
alias ms.picknumeric2 { 
  var %i $r(1,4096)
  while (%i) { 
    var %ms.new.client.numeric $+($inttobase64($mServices.config(numeric),2),$inttobase64(%i,3)) 
    if ( $istok($ms.read(c,clients,list),%ms.new.client.numeric,32) ) { dec %i }
    else { return %ms.new.client.numeric }
  }
}

alias listnumerics { 
  var %c $ms.db(read,c,clients,list)
  var %n $numtok(%c,32)
  var %x = 1
  while (%x < %n) { 
    var %r $gettok(%c,%x,32)
    echo -a Numeric list - Server numeric: $mid(%r,1,2)  Client numeric: $mid(%r,3,4) Base64 Numeric: $base64toint($mid(%r,3,4))
  inc %x 
  }
}