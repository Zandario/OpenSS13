/area
	var/fire = null
	level = null
	name = "area"
	mouse_opacity = 0
	var/lightswitch = 1

	var/eject = null

	var/requires_power = 1
	var/power_equip = 1
	var/power_light = 1
	var/power_environ = 1

	var/used_equip = 0
	var/used_light = 0
	var/used_environ = 0

	var/numturfs = 0
	var/linkarea = null
	var/area/linked = null
	var/no_air = null

/area/New()
	..()
	src.icon = 'icons/alert.dmi'
	src.layer = 10

	if(!requires_power)
		power_light = 1
		power_equip = 1
		power_environ = 1

	spawn(5)
		for(var/turf/T in src)		// count the number of turfs (for lighting calc)
			numturfs++				// spawned with a delay so turfs can finish loading
			if(no_air)
				T.oxygen = 0		// remove air if so specified for this area
				T.n2 = 0
				T.res_vars()

		if(linkarea)
			linked = locate(text2path("/area/[linkarea]"))		// area linked to this for power calcs


	spawn(15)
		src.power_change()		// all machines set to current power level, also updates lighting icon




/area/proc/firealert()
	if (!( src.fire ))
		src.fire = 1
		src.updateicon()
		src.mouse_opacity = 0
		for(var/obj/machinery/door/firedoor/D in src)
			if (!( D.density ))
				spawn( 0 )
					D.closefire()
					return
	return

/area/proc/updateicon()
	if ((fire || eject) && power_environ)
		if(fire && !eject)
			icon_state = "blue"
		else if(!fire && eject)
			icon_state = "red"
		else
			icon_state = "blue-red"
	else
		if(lightswitch && power_light)
			icon_state = null
		else
			icon_state = "dark128"
	if(lightswitch && power_light)
		luminosity = 1;
	else
		luminosity = 0;

/*
#define EQUIP 1
#define LIGHT 2
#define ENVIRON 3
*/

/area/proc/powered(var/chan)		// return true if the area has power to given channel
	if(!requires_power)
		return 1
	switch(chan)
		if(EQUIP)
			return power_equip
		if(LIGHT)
			return power_light
		if(ENVIRON)
			return power_environ

	return 0


// called when power status changes

/area/proc/power_change()

	for(var/obj/machinery/M in src)		// for each machine in the area
		M.power_change()				// reverify power status (to update icons etc.)

	spawn(rand(15,25))
		src.updateicon()


	if(linked)
		linked.power_equip = power_equip
		linked.power_light = power_light
		linked.power_environ = power_environ
		linked.power_change()




/area/proc/usage(var/chan)
	var/used = 0
	switch(chan)
		if(LIGHT)
			used += used_light
		if(EQUIP)
			used += used_equip
		if(ENVIRON)
			used += used_environ
		if(TOTAL)
			used += used_light + used_equip + used_environ

	if(linked)
		return linked.usage(chan) + used
	else
		return used

/area/proc/clear_usage()
	if(linked)
		linked.clear_usage()
	used_equip = 0
	used_light = 0
	used_environ = 0

/area/proc/use_power(var/amount, var/chan)

	switch(chan)
		if(EQUIP)
			used_equip += amount
		if(LIGHT)
			used_light += amount
		if(ENVIRON)
			used_environ += amount

#define LIGHTING_POWER 8		// power (W) per turf used for lighting

/area/proc/calc_lighting()
	if(lightswitch && power_light)
		used_light += numturfs * LIGHTING_POWER
