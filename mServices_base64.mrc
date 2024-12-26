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

alias base64toip {
  var %encoded = $1
  var %num = $base64toint(%encoded)
  var %ip1 = $calc(%num // 16777216)
  var %ip2 = $calc((%num // 65536) % 256)
  var %ip3 = $calc((%num // 256) % 256)
  var %ip4 = $calc(%num % 256)
  return $+(%ip1,.,%ip2,.,%ip3,.,%ip4)
}