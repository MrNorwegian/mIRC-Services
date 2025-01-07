on *:load: { set %mServices.loaded.snailbot true | ms.echo green Loaded mServices_snailbot.mrc }
on *:unload: { unset %mServices.loaded.snailbot | ms.echo red Unloaded mServices_snailbot.mrc }

alias ms.fb.snailbot.privmsg { 

  return
}