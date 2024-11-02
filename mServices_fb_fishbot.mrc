on *:load: { set %mServices.loaded.fishbot true | ms.echo green Loaded mServices_fishbot.mrc }
on *:unload: { unset %mServices.loaded.fishbot | ms.echo red Unloaded mServices_fishbot.mrc }