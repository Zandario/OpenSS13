/**
 *# Broken Pipe -- a broken pipe object
 *
 * This object is substituted for a /obj/machinery/pipes object when it is broken
 *
 * TODO: make removable and/or repairable
 *
 */
/obj/brokenpipe {
	name = "a broken pipe"
	icon = 'icons/reg_pipe.dmi'
	icon_state = "12-b"
	anchored = TRUE

	/**
	 * The p_dir or h_dir of the original pipe.
	 */
	var/p_dir = 0

	/**
	 * The pipe type of orginal pipe.
	 * 0 = regular, 1 = h/e
	 */
	var/ptype = 0


	/**
	 * Create a new broken pipe.
	 */
	New() {
		..()
		updateicon()
	}


	/**
	 * Set the state of the brokenpipe.
	 * Copies data from the original pipe object.
	 *
	 * @public
	 */
	proc/update(obj/machinery/pipes/P) {

		ptype = 0 //? The default for regular pipe.
		p_dir = P.p_dir

		if(istype(P, /obj/machinery/pipes/heat_exch)) // h/e pipe
			ptype = 1
			p_dir = P.h_dir

		level = P.level

		updateicon()
	}


	/**
	 * Update the broken pipe icon depending on the pipe dirs and type.
	 *
	 * @public
	 */
	proc/updateicon() {
		var/is

		switch(ptype)
			if(0)
				icon = 'icons/reg_pipe.dmi'
				is = "[p_dir]-b"
			if(1)
				icon = 'icons/heat_pipe.dmi'
				is = "[p_dir]-b"


		var/turf/T = loc

		if (level == 1 && isturf(T) && T.intact)
			invisibility = 101
			is += "-f"

		else
			invisibility = null

		icon_state = is
		return
	}


	/**
	 * Called when a pipe is revealed or hidden when a floor tile is removed, etc.
	 * Just call updateicon(), since all is handled there already.
	 *
	 * @public
	 */
	hide(i) {
		updateicon()
	}


	/**
	 * Attack with item.
	 * If welder, delete the pipe.
	 *
	 * @public
	 */
	attackby(obj/item/W, mob/user) {

		if (istype(W, /obj/item/weldingtool))
			var/obj/item/weldingtool/WT = W
			if(WT.welding)

				if(WT.weldfuel > 2)
					WT.weldfuel -=2

					user.client_mob() << "\blue Removing the broken pipe. Stand still as this takes some time."
					var/turf/T = user.loc
					sleep(30)

					if ((user.loc == T && user.equipped() == W))

						del(src)
				else
					user.client_mob() << "\blue You need more welding fuel to remove the pipe."
		else
			..()
		return
	}
}

/**
 * Look for a matching broken pipe.
 *
 * step direction target_dir from turf origin.
 * must match level and ptype.
 *
 * @public
 * @param {turf} origin The turf to start from.
 * @param {target_dir} target_dir The direction to step in.
 * @param {level} level The level of the pipe.
 * @param {ptype} ptype The type of pipe.
 * @returns {boolean} Returns `TRUE` if a matching broken pipe is found, `FALSE` otherwise.
 */
proc/findbrokenpipe(turf/origin, target_dir, level, ptype) {

	// Look in this turf.
	// for brokenpipe matching this pdir.
	var/turf/T = get_step(origin, target_dir)
	var/flipdir = turn(target_dir, 180)

	for(var/obj/brokenpipe/BP in T)
		if(BP.p_dir & flipdir)
			if(BP.level == level && BP.ptype == ptype)

				return TRUE // Found a matching brokenpipe!

	return FALSE // Found no match. :(
}
