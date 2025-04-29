; alpa.0.0.0
alias ms.version {
  var %version $read(VERSION)
  ; alpha\beta\stable
  var %type $gettok(%version, 2, 46)
  var %major $gettok(%version, 3, 46)
  var %minor $gettok(%version, 4, 46)
  var %patch $gettok(%version, 5, 46)

  if ( $1 == set ) { 
    if ( $2 == type ) {
      if ( $3 == stable ) { write -c VERSION $+($3,.,0,.,0,.,0) | ms.echo green Version set to $+($3,.,0,.,0,.,0) }
      elseif ( $3 == beta ) { write -c VERSION $+($3,.,0,.,0,.,0) | ms.echo green Version set to $+($3,.,0,.,0,.,0) }
      elseif ( $3 == alpha ) { write -c VERSION $+($3,.,0,.,0,.,0) | ms.echo green Version set to $+($3,.,0,.,0,.,0) }
      else { echo -st * /ms.version set type [alpha|beta|stable] }
      else { echo -st * /ms.version set type [alpha|beta|stable] }
    }
  }
  if ( $1 == inc ) {
    if ( $2 == major ) { inc %major }
    if ( $2 == minor ) { inc %minor }
    if ( $2 == patch ) { inc %patch }
    var %new_version $+(%type,.,%major,.,%minor,.,%patch)
    write -c VERSION %new_version
    write CHANGELOG %new_version
    ms.echo green Version set to %new_version
  }
  elseif (!$1) {
    ; Increment the PATCH version
    inc %patch

    ; If PATCH reaches 100, reset it and increment MINOR
    if (%patch >= 100) {
      set %patch 0
      inc %minor
    }

    ; If MINOR reaches 100, reset it and increment MAJOR
    if (%minor >= 100) {
      set %minor 0
      inc %major
    }

    var %new_version $+(%type,.,%major,.,%minor,.,%patch)
    write -c VERSION %new_version
    write CHANGELOG %new_version
  }
}
