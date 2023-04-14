/*
 *	Injector -- allows transfer of gas across a wall when attacked by a gas tank
 *
 *
 */

obj/machinery/injector
	name = "injector"
	icon = 'icons/stationobjs.dmi'
	icon_state = "injector"
	density = 1
	anchored = 1
	flags = WINDOW			// Unsure why flagged as a window


	// When attacked by a tank item, transfer the tank's gas contents to the turf behind the injector

	attackby(var/obj/item/W, var/mob/user)

		if(stat & NOPOWER)
			return
		use_power(25)

		var/obj/item/tank/ptank = W
		if (!( istype(ptank, /obj/item/tank) ))
			return

		var/turf/T = get_step(src.loc, get_dir(user, src))
		ptank.gas.turf_add(T, -1.0)
		src.add_fingerprint(user)
		return
