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

; Dev versions of the above functions for testing ipv4\ipv6 
; $ipv6tobase64(<ipv6>)
alias ipv6tobase64 {
  var %ip = $1
  ; Fjern kolon og sett opp full lengde
  var %expanded = $expandipv6(%ip)
  ; Bygg binær streng
  var %bin
  var %i = 1
  while (%i <= 32) {
    var %hex = $mid(%expanded, %i, 2)
    var %bin = %bin $chr($base(%hex,16,10))
    inc %i 2
  }
  ; Base64URL-encode
  var %b64 = $base64encodebin(%bin)
  ; Bytt +/ til -_ og fjern padding
  var %b64 = $replace(%b64, +, -, /, _, =, )
  return %b64
}

; $expandipv6(<ipv6>) → gir 32 heksadesimaltegn uten :
alias expandipv6 {
  var %parts = $split($1, :)
  var %full = 
  var %skip = $calc(8 - $numtok(%parts, 58) + 1)
  var %i = 1
  while (%i <= $numtok(%parts, 58)) {
    var %block = $gettok(%parts, %i, 58)
    if (%block == $null) {
      var %full = %full $str(0000, %skip)
    }
    else {
      var %full = %full $base(%block, 16, 16, 4)
    }
    inc %i
  }
  return %full
}

; $base64encodebin(<binær streng>)
alias base64encodebin {
  var %table = ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/
  var %out
  var %i = 1
  while (%i <= $len($1)) {
    var %b1 = $asc($mid($1, %i, 1))
    var %b2 = $iif($calc(%i + 1) <= $len($1), $asc($mid($1, %i + 1, 1)), 0)
    var %b3 = $iif($calc(%i + 2) <= $len($1), $asc($mid($1, %i + 2, 1)), 0)

    var %c1 = $calc(%b1 >> 2)
    var %c2 = $calc((%b1 & 3) << 4 | (%b2 >> 4))
    var %c3 = $calc((%b2 & 15) << 2 | (%b3 >> 6))
    var %c4 = $calc(%b3 & 63)

    var %out = %out $mid(%table, %c1 + 1, 1)
    var %out = %out $mid(%table, %c2 + 1, 1)
    var %out = %out $iif($calc(%i + 1) <= $len($1), $mid(%table, %c3 + 1, 1), =)
    var %out = %out $iif($calc(%i + 2) <= $len($1), $mid(%table, %c4 + 1, 1), =)

    inc %i 3
  }
  return %out
}