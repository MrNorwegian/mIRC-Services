on *:load: { set %mServices.loaded.banana true | ms.echo green Loaded mServices_banana.mrc }
on *:unload: { unset %mServices.loaded.banana | ms.echo red Unloaded mServices_banana.mrc }

alias ms.fb.banana.privmsg { 

  return
}