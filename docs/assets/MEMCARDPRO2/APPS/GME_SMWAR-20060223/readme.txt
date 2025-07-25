#--------------------------------------------------------------------
# Super Mario War / PS2 
# Release version: (23 Feb 2006)
#
# Copyright (C)
#  - Florian Hufsky
#  - Michael Schaffer
# http://smw.72dpiarmy.com
#
# Playstation 2 version by 
#
# Olivier "evilo" Biot <evilo13@gmail.com> 
# <http://psxdev.info/evilo/>
# 
# The Froggies 
# <http://psxdev.org>
#-------------------------------------------------------------------- 


History
-------

*  February 23th, 2006 - Super Mario War v1.10r6

    As promised, a little update to add a great feature : Multitap 
    support thanks to the work of Drakonite on the SDL library
    (as well as others little fixes to the driver, but that should 
    be however not visible). Also, I saw a lot of complains about
    the outdated version on which the PS2 port is based, but all I 
    can say is : don't discourage people, and try to enjoy this
    version anyway(that was initially a try for the PS2 SDL library) 
    while waiting for a fresh new port based on the version 1.6 !

* February 15th, 2006 - Super Mario War v1.10b5

    It's still a wip version, and still need some rework, but since 
    it's already playable and fun, I decided to release a first version.
    The PS2 version is a based on an older version of smw (1.10), but 
    should be updated in the future to be inline with the official version.


Compiling:
----------

To get your sources compiled, checkout the latest PS2SDK source tree. 
You will need the last SDL and SDL_mixer version from the repository.
(All of these are available at www.ps2dev.org)
Check also ps2_lib_patch.txt for specific details/issues.

just type "make all" and you are done !


Credits:
--------
Florian Hufsky and Michael Schaffer for their great game !
Gawd for the SDL library port on the ps2.
Drakonite for adding mtap support in the SDL driver.
To all the froggies, and even Shazz :)

-- evilo 20060223