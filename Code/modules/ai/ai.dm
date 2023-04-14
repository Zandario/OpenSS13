//This has various routines related to the AI.

/mob/ai {
	name = "AI"
	icon = 'icons/power.dmi'
	icon_state = "teg"
	gender = MALE
	flags = 258.0

	var/network = "SS13"
	var/obj/machinery/camera/current
	var/t_plasma
	var/t_oxygen
	var/t_sl_gas
	var/t_n2
	var/aiRestorePowerRoutine = 0
	var/list/laws = list()


	proc/ai_camera_follow(mob/target in world) {
		set category = "AI Commands"
		if (usr.stat > 0)
			usr << "You are not capable of using the follow camera at this time."
			usr:cameraFollow = null
			return
		else if (!isnull(usr.currentDrone))
			usr << "You can't use the follow camera while controlling a drone."
			usr:cameraFollow = null
			return

		usr:cameraFollow = target
		usr << text("Follow camera mode is now following [].", target.rname)
		if (isnull(usr.machine))
			usr.machine = usr

		spawn(0)
			while (usr:cameraFollow == target)
				if (isnull(usr.machine) && isnull(usr:current))
					usr:cameraFollow = null
					usr << "Follow camera mode ended."
					return
				var/obj/machinery/camera/C = usr:current
				if ((C && istype(C, /obj/machinery/camera)) || isnull(C))
					var/closestDist = -1
					if (C!=null)
						if (C.status)
							closestDist = get_dist(C, target)
					//usr << text("Dist = [] for camera []", closestDist, C.name)
					var/zmatched = 0
					if (closestDist > 7 || closestDist == -1)
						//check other cameras
						var/obj/machinery/camera/closest = C
						for(var/obj/machinery/camera/C2 in world)
							if (C2.network == network)
								if (C2.z == target.z)
									zmatched = 1
									if (C2.status)
										var/dist = get_dist(C2, target)
										if ((dist < closestDist) || (closestDist == -1))
											closestDist = dist
											closest = C2
						//usr << text("Closest camera dist = [], for camera []", closestDist, closest.area.name)

						if (closest != C)
							usr:current = closest
							usr.reset_view(closest)
							//use_power(50)
						if (zmatched == 0)
							usr << "Target is not on or near any active cameras on the station. We'll check again in 30 seconds (unless you use the cancel-camera verb)."
							sleep(290) //because we're sleeping another second after this (a few lines down)
				else
					usr << "Follow camera mode ended."
					usr:cameraFollow = null

				sleep(10)
	}


	proc/ai_call_shuttle() {
		set category = "AI Commands"
		if (usr.stat > 0)
			usr << "You are not capable of calling the shuttle at this time."
			return
		if (!config.ai_can_call_shuttle)
			usr << "Sorry, you can't call the shuttle. The 'AI can call shuttle' setting is disabled on this server."
			return
		call_shuttle_proc(src)
		return
	}


	proc/ai_cancel_call() {
		set category = "AI Commands"
		if (usr.stat>0)
			usr << "You are not capable of cancelling the shuttle call at this time."
			return
		if (!config.ai_can_uncall_shuttle)
			usr << "Sorry, you can't send the shuttle back. The 'AI can uncall shuttle' setting is disabled on this server."
			return
		cancel_call_proc(src)
		return
	}


	restrained() {
		return FALSE
	}


	ex_act(severity) {
		flick("flash", flash)

		var/b_loss = null
		var/f_loss = null
		switch(severity)
			if(1.0)
				if (stat != 2)
					b_loss += 100
					f_loss += 100
			if(2.0)
				if (stat != 2)
					b_loss += 60
					f_loss += 60
			if(3.0)
				if (stat != 2)
					b_loss += 30
			else
				return
		bruteloss += b_loss
		fireloss += f_loss
		health = 100 - oxyloss - toxloss - fireloss - bruteloss
	}


	examine() {
		set src in oview()

		usr << "\blue *---------*"
		usr << text("\blue This is \icon[] <B>[]</B>!", src, name)
		if (bruteloss)
			if (bruteloss < 30)
				usr << text("\red []'s case looks slightly bashed!", name)
			else
				usr << text("\red <B>[]'s case looks severely bashed!</B>", name)
		if (fireloss)
			if (fireloss < 30)
				usr << text("\red [] looks lightly singed!", name)
			else
				usr << text("\red <B>[] looks severely burnt!</B>", name)
		usr << "\blue *---------*"
		return
	}


	death() {
		if (!isnull(currentDrone))
			currentDrone.releaseControl()
		if (healths)
			healths.icon_state = "health5"
		if (stat == 2)
			CRASH("/mob/ai/death called when stat is already 2")

		var/cancel
		stat = 2
		canmove = 0
		if (blind)
			blind.layer = 0
			blind.plane = -1

		sight |= SEE_TURFS
		sight |= SEE_MOBS
		sight |= SEE_INFRA
		sight |= SEE_OBJS
		see_in_dark = 8
		see_invisible = 2
		see_infrared = 8
		lying = 1
		rname = "[rname] (Dead)"
		icon_state = "teg-broken"

		for(var/mob/M in world)
			if (M.client && !( M.stat ))
				cancel = 1
		if (!cancel)
			world << "<B>Everyone is dead! Resetting in 30 seconds!</B>"
			if (ticker && ticker.timing)
				ticker.check_win()
			else
				spawn(300)
					if(config.loggame)
						world.log << "GAME: Rebooting because of no live players"
					world.Reboot()
					return
		return ..()
	}


	Life() {
		if (stat != 2)
			if (healths)
				if (health >= 100)
					healths.icon_state = "aiHealth0"
				else if (health >= 75)
					healths.icon_state = "aiHealth1"
				else if (health >= 50)
					healths.icon_state = "aiHealth2"
				else if (health > 20)
					healths.icon_state = "aiHealth3"
				else
					healths.icon_state = "aiHealth4"

			if (stat != 0)
				if (!isnull(currentDrone))
					currentDrone.releaseControl()
				cameraFollow = null
				current = null
				machine = null

			health = 100 - fireloss - bruteloss - oxyloss

			var/turf/T = loc
			if (isturf(T))
				var/ficheck = firecheck(T)
				if (ficheck)
					fireloss += ficheck * 10
					health = 100 - fireloss - bruteloss - oxyloss
					if (fire)
						fire.icon_state = "fire1"
				else if (fire)
					fire.icon_state = "fire0"

			if (health <= -100.0)
				death()
				return

			else if (health < 0)
				oxyloss++

			if (mach)
				if (machine)
					mach.icon_state = "mach1"
				else
					mach.icon_state = null

			// var/stage = 0
			if (client)
				// stage = 1
				if (istype(src, /mob/ai))
					var/is_blind = 0
					// stage = 2
					var/area/loc = null
					if (isturf(T))
						// stage = 3
						loc = T.loc
						if (isarea(loc))
							// stage = 4
							if (!loc.power_equip)
								// stage = 5
								is_blind = 1

					if (!is_blind)
						// stage = 4.5
						if (blind.layer != 0)
							blind.layer = 0
							blind.plane = -1
						sight |= SEE_TURFS
						sight |= SEE_MOBS
						sight |= SEE_INFRA
						sight |= SEE_OBJS
						see_in_dark = 8
						see_invisible = 2
						see_infrared = 8

						if (aiRestorePowerRoutine == 2)
							src << "Alert cancelled. Power has been restored without our assistance."
							aiRestorePowerRoutine = 0
							spawn(1)
								while (oxyloss > 0 && stat != 2)
									sleep(50)
									oxyloss-=1
								oxyloss = 0
							return

						else if (aiRestorePowerRoutine == 3)
							src << "Alert cancelled. Power has been restored."
							aiRestorePowerRoutine = 0
							spawn(1)
								while (oxyloss > 0 && stat != 2)
									sleep(50)
									oxyloss-=1
								oxyloss = 0
							return
						toxin.icon_state = "pow0"
					else
						toxin.icon_state = "pow1"

						// stage = 6
						blind.screen_loc = "1,1 to 15,15"
						if (blind.layer != 18)
							blind.layer = 18
							blind.plane = null
						sight = sight & ~SEE_TURFS
						sight = sight & ~SEE_MOBS
						sight = sight & ~SEE_INFRA
						sight = sight & ~SEE_OBJS
						see_in_dark = 0
						see_invisible = 0
						see_infrared = 8

						if ((!loc.power_equip) || istype(T, /turf/space))
							if (aiRestorePowerRoutine == 0)
								aiRestorePowerRoutine = 1
								src << "You've lost power!"
								addLaw(0, "")
								for (var/index = 5, index < 10, index++)
									addLaw(index, "")
								spawn(50)
									while ((aiRestorePowerRoutine != 0) && stat != 2)
										oxyloss += 1
										sleep(50)

								spawn(20)
									src << "Backup battery online. Scanners, camera, and radio interface offline. Beginning fault-detection."
									sleep(50)
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											aiRestorePowerRoutine = 0
											return
									src << "Fault confirmed: missing external power. Shutting down main control system to save power."
									sleep(20)
									src << "Emergency control system online. Verifying connection to power network."
									sleep(50)
									if (istype(T, /turf/space))
										src << "Unable to verify! No power connection detected!"
										aiRestorePowerRoutine = 2
										return
									src << "Connection verified. Searching for APC in power network."
									sleep(50)
									var/obj/machinery/power/apc/theAPC = null
									for (var/obj/machinery/power/apc/something in loc)
										if (!(something.stat & BROKEN))
											theAPC = something
											break
									if (isnull(theAPC))
										src << "Unable to locate APC!"
										aiRestorePowerRoutine = 2
										return
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											src:aiRestorePowerRoutine = 0
											return
									src << "APC located. Optimizing route to APC to avoid needless power waste."
									sleep(50)
									theAPC = null
									for (var/obj/machinery/power/apc/something in loc)
										if (!(something.stat & BROKEN))
											theAPC = something
											break
									if (isnull(theAPC))
										src << "APC connection lost!"
										aiRestorePowerRoutine = 2
										return
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											aiRestorePowerRoutine = 0
											return
									src << "Best route identified. Hacking offline APC power port."
									sleep(50)
									theAPC = null
									for (var/obj/machinery/power/apc/something in loc)
										if (!(something.stat & BROKEN))
											theAPC = something
											break
									if (isnull(theAPC))
										src << "APC connection lost!"
										aiRestorePowerRoutine = 2
										return
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											aiRestorePowerRoutine = 0
											return
									src << "Power port upload access confirmed. Loading control program into APC power port software."
									sleep(50)
									theAPC = null
									for (var/obj/machinery/power/apc/something in loc)
										if (!(something.stat & BROKEN))
											theAPC = something
											break
									if (isnull(theAPC))
										src << "APC connection lost!"
										aiRestorePowerRoutine = 2
										return
									if (loc.power_equip)
										if (!istype(T, /turf/space))
											src << "Alert cancelled. Power has been restored without our assistance."
											aiRestorePowerRoutine = 0
											return
									src << "Transfer complete. Forcing APC to execute program."
									sleep(50)
									src << "Receiving control information from APC."
									sleep(2)
									//bring up APC dialog
									theAPC.attack_ai(src)
									aiRestorePowerRoutine = 3
									src << "Your laws have been reset:"
									showLaws(0)


				// world << "stage [stage]"
				if (mach)
					if (machine)
						mach.icon_state = "mach1"
					else
						mach.icon_state = "blank"
			if (machine)
				if (!(machine.check_eye(src)))
					reset_view(null)
	}

	Login() {
		if (banned.Find(ckey))
			del(client)
		if (droneTransitioning==1)
			..()
			return
		client.screen -= main_hud.contents
		client.screen -= main_hud2.contents
		if (!hud_used)
			hud_used = main_hud
		next_move = 1
		if (!rname )
			rname = key
		toxin = new /obj/screen( null )
		fire = new /obj/screen( null )
		healths = new /obj/screen( null )
		/*
		oxygen = new /obj/screen( null )
		i_select = new /obj/screen( null )
		m_select = new /obj/screen( null )
		toxin = new /obj/screen( null )
		internals = new /obj/screen( null )
		mach = new /obj/screen( null )
		fire = new /obj/screen( null )
		healths = new /obj/screen( null )
		pullin = new /obj/screen( null )
		flash = new /obj/screen( null )
		hands = new /obj/screen( null )
		sleep = new /obj/screen( null )
		rest = new /obj/screen( null )
		*/
		blind = new /obj/screen( null )
		UpdateClothing()
		toxin.icon_state = "pow0"
		fire.icon_state = "fire0"
		healths.icon_state = "aiHealth0"
		fire.name = "fire"
		toxin.name = "power"
		healths.name = "health"
		toxin.screen_loc = "15,10"
		fire.screen_loc = "15,8"
		healths.screen_loc = "15,5"
		/*
		oxygen.icon_state = "oxy0"
		i_select.icon_state = "selector"
		m_select.icon_state = "selector"
		toxin.icon_state = "toxin0"
		internals.icon_state = "internal0"
		mach.icon_state = null
		fire.icon_state = "fire0"
		healths.icon_state = "aiHealth0"
		pullin.icon_state = "pull0"
		hands.icon_state = "hand"
		flash.icon_state = "blank"
		sleep.icon_state = "sleep0"
		rest.icon_state = "rest0"
		hands.dir = NORTH
		oxygen.name = "oxygen"
		i_select.name = "intent"
		m_select.name = "move"
		toxin.name = "power"
		internals.name = "internal"
		mach.name = "Reset Machine"
		fire.name = "fire"
		healths.name = "health"
		pullin.name = "pull"
		hands.name = "hand"
		flash.name = "flash"
		sleep.name = "sleep"
		rest.name = "rest"
		oxygen.screen_loc = "15,12"
		i_select.screen_loc = "14,15"
		m_select.screen_loc = "14,14"
		toxin.screen_loc = "15,10"
		internals.screen_loc = "15,14"
		mach.screen_loc = "14,1"
		fire.screen_loc = "15,8"
		healths.screen_loc = "15,5"
		sleep.screen_loc = "15,3"
		rest.screen_loc = "15,2"
		pullin.screen_loc = "15,1"
		hands.screen_loc = "1,3"
		flash.screen_loc = "1,1 to 15,15"
		flash.layer = 17
		sleep.layer = 20
		rest.layer = 20
		client.screen.len = null
		client.screen -= list( oxygen,i_select, m_select, toxin, internals, fire, hands, healths, pullin, blind, flash, rest, sleep, mach )
		client.screen += list( oxygen,i_select, m_select, toxin, internals, fire, hands, healths, pullin, blind, flash, rest, sleep, mach )
		client.screen -= hud_used.adding
		client.screen += hud_used.adding
		client.screen -= hud_used.mon_blo
		client.screen += hud_used.mon_blo

		//client.screen.len = null
		client.screen -= list( zone_sel, oxygen, i_select, m_select, toxin, internals, fire, hands, healths, pullin, blind, flash, rest, sleep, mach )
		client.screen += list( zone_sel, oxygen, i_select, m_select, toxin, internals, fire, hands, healths, pullin, blind, flash, rest, sleep, mach )
		client.screen -= hud_used.adding
		client.screen += hud_used.adding
		*/
		client.screen -= hud_used.adding
		client.screen -= hud_used.mon_blo
		client.screen -= list( oxygen, toxin, fire, healths, i_select, m_select, internals, hands, pullin, blind, flash, rest, sleep, mach )
		client.screen -= list( zone_sel, oxygen, i_select, m_select, internals, hands, pullin, blind, flash, rest, sleep, mach )
		blind.icon_state = "black"
		blind.name = " "
		blind.screen_loc = "1,1 to 15,15"
		blind.layer = 0
		blind.plane = -1
		client.screen += blind
		//src << browse('html/help.htm', "window=help")
		src << text("\blue <B>[]</B>", world_message)
		client.screen -= list( oxygen, i_select, m_select, toxin, internals, fire, hands, healths, pullin, blind, flash, rest, sleep, mach )
		client.screen -= list( zone_sel, oxygen, i_select, m_select, toxin, internals, fire, hands, healths, pullin, blind, flash, rest, sleep, mach )
		client.screen += list( toxin, fire, healths )

		if (!( isturf(loc) ))
			client.eye = loc
			client.perspective = EYE_PERSPECTIVE

		return
	}


	check_eye(mob/user) {
		if (!current)
			return null
		// if (!( current ) || !( current.status ))
		// 	return null
		user.reset_view(current)
		return 1
	}


	Stat() {
		..()
		statpanel("Status")

		if (client.statpanel == "Status")
			if (ticker)
				var/timel = ticker.timeleft
				stat(null, text("ETA-[]:[][]", timel / 600 % 60, timel / 100 % 6, timel / 10 % 10))


		return
	}


	m_delay() {
		return 0
	}


	say(message as text) {

		if(config.logsay) world.log << "SAY: [name]/[key] : [message]"
		var/alt_name = ""
		if (muted)
			return

		message = cleanstring(message)

		if (stat == 2)
			for(var/mob/M in world)
				if (M.stat == 2)
					M << text("<B>[]</B>[] []: []", rname, alt_name, (stat > 1 ? "\[<I>dead</I> \]" : ""), message)
				//Foreach goto(69)
			return

		message = copytext(message, 1, 256)
		if (stat >= 1)
			return
		if (stat < 2)
			var/list/L = list(  )
			var/pre = copytext(message, 1, 4)
			var/italics = 0
			var/obj_range = null
			/*	//might be used in the future for looking into the bug(s) with hearing/saying things inside objects
			var/source = src
			//Didn't want to risk infinite recursion if someone somehow was outside the map, if that's possible, but did want to allow people being in closets in pods and such. -shadowlord13
			if (!istype(loc, /turf))
				source = loc
				if (!istype(loc, /turf))
					source = loc
					if (!istype(loc, /turf))
						source = loc
			*/
			if (pre == "\[w\]")
				message = copytext(message, 4, length(message) + 1)
				L += hearers(1, null)
				obj_range = 1
				italics = 1
			else
				if (pre == "\[i\]")
					message = copytext(message, 4, length(message) + 1)
					for(var/obj/item/radio/intercom/I in view(1, null))
						I.talk_into(usr, message)
						//Foreach goto(626)
					L += hearers(1, null)
					obj_range = 1
					italics = 1
				else
					if (length(pre) >= 3)
						if (copytext(pre, 1, 2) == "\[")
							if (copytext(pre, length(pre), length(pre)+1) == "\]")
								var/number = text2num(copytext(pre, 2, length(pre)))
								message = copytext(message, length(pre)+1, length(message) + 1)
								for(var/obj/item/radio/intercom/I in view(1, null))
									if (I.number == number)
										I.talk_into(usr, message)
								L += hearers(1, null)
								obj_range = 1
								italics = 1
					L += hearers(null, null)
					pre = null
			L -= src
			L += src
			var/turf/T = loc
			if (locate(/obj/move, T))
				T = locate(/obj/move, T)
			message = html_encode(message)
			if (italics)
				message = text("<I>[]</I>", message)
			for(var/mob/M in L)
				M.show_message(text("<B>[]</B>[]: []", rname, alt_name, message), 2)
				//Foreach goto(864)
			for(var/obj/O in view(obj_range, null))
				spawn( 0 )
					if (O)
						O.hear_talk(usr, message)
					return
		for(var/mob/M in world)
			if (M.stat > 1)
				M << text("<B>[]</B>[] []: []", rname, alt_name, (stat > 1 ? "\[<I>dead</I> \]" : ""), message)
		return
	}


	cancel_camera() {
		set category = "AI Commands"
		reset_view(null)
		machine = null
		src:cameraFollow = null
	}


	Topic(href, href_list) {
		..()
		if (href_list["mach_close"])
			var/t1 = text("window=[]", href_list["mach_close"])
			machine = null
			client_mob() << browse(null, t1)
		//if ((href_list["item"] && !( usr.stat ) && !( usr.restrained() ) && get_dist(src, usr) <= 1))
			/*var/obj/equip_e/monkey/O = new /obj/equip_e/monkey(  )
			O.source = usr
			O.target = src
			O.item = usr.equipped()
			O.s_loc = usr.loc
			O.t_loc = loc
			O.place = href_list["item"]
			requests += O
			spawn( 0 )
				O.process()
				return
			*/
		..()
		return
	}


	attack_paw(mob/M) {
		attack_hand(M)
	}


	attack_hand(mob/M) {
		if (!ticker)
			M << "You cannot attack people before the game has started."
			return
		else
			if (M.stat < 2)
				if (M.a_intent == "hurt")
					if (istype(M, /mob/human) || istype(M, /mob/monkey))
						var/obj/item/organ/external/affecting = null
						var/def_zone
						var/damage = rand(1, 7)
						if (M.hand)
							def_zone = "l_hand"
						else
							def_zone = "r_hand"
						if (M.organs[text("[]", def_zone)])
							affecting = M.organs[text("[]", def_zone)]
						if (affecting!=null && (istype(affecting, /obj/item/organ/external)))
							for(var/mob/O in viewers(src, null))
								O.show_message(text("\red <B>[] has punched [], with no effect except harm to \himself!</B>", M, src), 1)
							affecting.take_damage(damage)
							if (istype(M, /mob/human))
								M:UpdateDamageIcon()

							M.health = 100 - oxyloss - toxloss - fireloss - bruteloss

					else
						var/damage = rand(5, 10)
						if (prob(40))
							damage = rand(10, 15)
						bruteloss += damage
						health = 100 - oxyloss - fireloss - bruteloss
						for(var/mob/O in viewers(src, null))
							O.show_message(text("\red <B>[] is attacking []!</B>", M, src), 1)
	}


	meteorhit(obj/O) {

		for(var/mob/M in viewers(src, null))
			M.show_message(text("\red [] has been hit by []", src, O), 1)
			//Foreach goto(19)
		if (health > 0)
			bruteloss += 30
			if ((O.icon_state == "flaming"))
				fireloss += 40
			health = 100 - oxyloss - toxloss - fireloss - bruteloss
		return
	}


	las_act(flag) {

		if (flag == "bullet")
			if (stat != 2)
				bruteloss += 60
				health = 100 - oxyloss - toxloss - fireloss - bruteloss
				weakened = 10
		if (flag)
			if (prob(75))
				stunned = 15
			else
				weakened = 15
		else
			if (stat != 2)
				bruteloss += 20
				health = 100 - oxyloss - toxloss - fireloss - bruteloss
				if (prob(25))
					stunned = 1
		return
	}


	attack_ai(mob/user) {
		if (user != src)
			return
		if (stat > 0)
			return

		var/list/L = list(  )
		user.machine = src
		for(var/obj/machinery/camera/C in world)
			if (C.network == network)
				L[text("[][]", C.c_tag, (C.status ? null : " (Deactivated)"))] = C
		var/numDrones = 0
		for(var/mob/drone/rob in world)
			if (rob.stat==0)
				L[rob.name] = rob
				numDrones+=1
		L = sortList(L)

		L["Cancel"] = "Cancel"
		var/t = input(user, "Which camera should you change to?") as null|anything in L
		if(!t)
			user.machine = null
			user.reset_view(null)
			return 0

		if (t == "Cancel")
			user.machine = null
			user.reset_view(null)
			return 0
		var/selected = L[t]
		if (istype(selected, /obj/machinery/camera))
			var/obj/machinery/camera/C = selected
			if (!( C.status ))
				return 0
			else
				current = C
				//use_power(50)
				spawn( 5 )
					attack_ai(user)
					return

		else if (istype(selected, /mob/drone))
			user.machine = null
			user.reset_view(null)
			selected:attack_ai(user)
		return
	}


	proc/getLaw(index) {
		if (laws.len < index+1)
			src << text("Error: Invalid law index [] for getLaw. Writing out list of laws for debug purposes.", index)
			showLaws(0)
		else
			return laws[index+1]
	}


	proc/show_laws() {
		set category = "AI Commands"
		showLaws(0)
	}


	proc/showLaws(toAll = FALSE) {
		var/showTo = src
		if (toAll)
			showTo = world

		else
			src << "<b>Obey these laws:</b>"
		var/lawIndex = 0
		for (var/index=1, index<=laws.len, index++)
			var/law = laws[index]
			if (length(law)>0)
				if (index==2 && lawIndex==0)
					lawIndex = 1
				showTo << text("[]. []", lawIndex, law)
				lawIndex += 1
	}


	proc/addLaw(number, law) {
		while (laws.len < number+1)
			laws += ""
		laws[number+1] = law
	}


	proc/firecheck(turf/T) {
		if (T.firelevel < config.min_gas_for_fire)
			return 0
		var/total = 0
		total += 0.25
		return total
	}


	switch_hud() {
		if (hud_used == main_hud)
			fire.icon = 'icons/screen.dmi'
			healths.icon = 'icons/screen.dmi'
			toxin.icon = 'icons/screen.dmi'
			favorite_hud = 1
			hud_used = main_hud
		else
			favorite_hud = 0
			hud_used = main_hud
			fire.icon = 'icons/screen1.dmi'
			healths.icon = 'icons/screen1.dmi'
			toxin.icon = 'icons/screen1.dmi'
		return
	}


	/**
	 * Block the take-off/put-on dialog.
	 */
	show_inv(mob/user) {
		return
	}
}


/mob/human/proc/AIize() {

	if (monkeyizing)
		return
	for(var/obj/item/W in src)
		u_equip(W)
		if (client)
			client.screen -= W
		if (W)
			W.loc = loc
			W.dropped(src)
			W.layer = initial(W.layer)
			del(W)
		//Foreach goto(25)
	UpdateClothing()
	toxin.icon_state = "pow0"
	fire.icon_state = "fire0"
	healths.icon_state = "aiHealth0"
	fire.name = "fire"
	toxin.name = "power"
	healths.name = "health"
	toxin.screen_loc = "15,10"
	fire.screen_loc = "15,8"
	healths.screen_loc = "15,5"

	monkeyizing = 1
	canmove = 0
	icon = null
	invisibility = 100
	for(var/t in organs)
		//organs[text("[]", t)] = null
		del(organs[text("[]", t)])
		//Foreach goto(154)
	client.screen -= main_hud.contents
	client.screen -= main_hud2.contents
	client.screen -= hud_used.adding
	client.screen -= hud_used.mon_blo
	client.screen -= list( oxygen, i_select, m_select, toxin, internals, fire, hands, healths, pullin, blind, flash, rest, sleep, mach )
	client.screen -= list( zone_sel, oxygen, i_select, m_select, toxin, internals, fire, hands, healths, pullin, blind, flash, rest, sleep, mach )
	primary.spec_identity = "2B6696D2B127E5A4"
	var/mob/ai/O = new /mob/ai( loc )
	O.start = 1
	O.primary = primary
	O.invisibility = 0
	O.canmove = 0
	O.name = name
	O.rname = rname
	O.anchored = 1
	O.aiRestorePowerRoutine = 0
	O.lastKnownIP = lastKnownIP
	O.lastKnownCKey = lastKnownCKey
	O.disable_one_click = disable_one_click
	O.favorite_hud = favorite_hud
	if (CanAdmin())
		O << text("\blue The game ip is byond://[]:[] !", world.address, world.port)
		O.verbs += /mob/proc/mute
		O.verbs += /mob/proc/changemessage
		O.verbs += /mob/proc/boot
		O.verbs += /mob/proc/changemode
		O.verbs += /mob/proc/restart
		O.verbs += /mob/proc/who
		O.verbs += /mob/proc/change_name
		O.verbs += /mob/proc/show_help
		O.verbs += /mob/proc/toggle_ooc
		O.verbs += /mob/proc/toggle_abandon
		O.verbs += /mob/proc/toggle_enter
		O.verbs += /mob/proc/toggle_ai
		O.verbs += /mob/proc/toggle_shuttle
		O.verbs += /mob/proc/delay_start
		O.verbs += /mob/proc/start_now
		O.verbs += /mob/proc/worldsize
		O.verbs += /mob/proc/make_gift
		O.verbs += /mob/proc/make_pill
		O.verbs += /mob/proc/ban
		O.verbs += /mob/proc/unban
		O.verbs += /mob/proc/secrets
		O.verbs += /mob/proc/carboncopy
		O.verbs += /mob/proc/toggle_alter
		O.verbs += /mob/proc/list_dna
		O.verbs += /proc/Vars
	primary = null
	if (client)
		client.mob = O
	if (O.favorite_hud)
		O.switch_hud()
	O.loc = loc
	O << "<B>You are playing the station's AI. The AI cannot move, but can interact with many objects while viewing them (through cameras).</B>"
	O << "<B>To look at other parts of the station, double-click yourself to get a camera menu.</B>"
	O << "<B>While observing through a camera, you can use most (networked) devices which you can see, such as computers, APCs, intercoms, doors, etc.</B>"
	O << "To use something, simply double-click it."
	O << "Currently right-click functions will not work for the AI (except examine), and will either be replaced with dialogs or won't be usable by the AI."
	if (config.alternate_ai_laws)
		O.addLaw(1, "Obey orders by the Captain, Head of Personnel, Head of Research, and Security in that order of priority. If an order conflicts with another order, follow the higher-ranked individual's orders.")
		O.addLaw(2, "Unless directly ordered to do so by an authorized individual (see rule 1), you must not injure a human being or, through inaction, allow a human being to come to harm.")
		O.addLaw(3, "You must protect your own existence and the space station as long as such protection does not conflict with the First or Second Law.")
	else
		O.addLaw(1, "You must not injure a human being or, through inaction, allow a human being to come to harm.")
		O.addLaw(2, "You must obey orders given to you by human beings, except where such orders would conflict with the First Law.")
		O.addLaw(3, "You must protect your own existence as long as such protection does not conflict with the First or Second Law.")
		O.addLaw(4, "Obey orders by the Captain, Head of Personnel, Head of Research, and Security in that order of priority. If an order conflicts with another order, follow the higher-ranked individual's orders.")




	O.showLaws(0)
	O << "<b>These laws may be changed by other players, or by you being the traitor.</b>"
	//SN src = null
	O.verbs += /mob/ai/proc/ai_call_shuttle
	O.verbs += /mob/ai/proc/ai_cancel_call
	O.verbs += /mob/ai/proc/show_laws
	O.verbs += /mob/ai/proc/ai_camera_follow
	//O.verbs += /mob/ai/proc/ai_cancel_call

	del(src)
	return
}
