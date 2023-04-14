/area/vehicles
	requires_power = FALSE

/area/vehicles/New()
	..()
	sleep(1)
	var/obj/shut_controller/S = new /obj/shut_controller()
	shuttles += S
	for(var/obj/move/O in src)
		S.parts += O
		O.master = S
	return

/area/vehicles/shuttle1
/area/vehicles/shuttle2
/area/vehicles/shuttle3
