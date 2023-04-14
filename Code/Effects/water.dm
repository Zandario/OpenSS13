/obj/effects/water
	name = "water"
	icon = 'icons/water.dmi'
	icon_state = "extinguish"
	flags = 2
	mouse_opacity = 0
	weight = 1000

	var/life = 15

/obj/effects/water/New()
	..()
	var/turf/T = src.loc
	if (istype(T, /turf))
		T.firelevel = 0
	spawn(70)
		del(src)

/obj/effects/water/Del()
	var/turf/T = src.loc
	if (istype(T, /turf))
		T.firelevel = 0
	..()

/obj/effects/water/Move(turf/newloc)
	var/turf/T = src.loc
	if (istype(T, /turf))
		T.firelevel = 0
	if (--src.life < 1)
		del(src)
	if(newloc.density)
		return 0
	.=..()
