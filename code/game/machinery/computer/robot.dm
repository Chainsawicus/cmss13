//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31


/obj/structure/machinery/computer/robotics
	name = "Robotics Control"
	desc = "Used to remotely lockdown or detonate linked Cyborgs."
	icon = 'icons/obj/structures/machinery/computer.dmi'
	icon_state = "robot"
	req_access = list(ACCESS_MARINE_RESEARCH)
	circuit = /obj/item/circuitboard/computer/robotics

	var/id = 0.0
	var/temp = null
	var/status = 0
	var/timeleft = 60
	var/stop = 0.0
	var/screen = 0 // 0 - Main Menu, 1 - Cyborg Status, 2 - Kill 'em All! -- In text


/obj/structure/machinery/computer/robotics/attack_remote(var/mob/user as mob)
	return src.attack_hand(user)

/obj/structure/machinery/computer/robotics/attack_hand(var/mob/user as mob)
	if(..())
		return
	if (src.z > 6)
		to_chat(user, SPAN_DANGER("<b>Unable to establish a connection</b>: \black You're too far away from the station!"))
		return
	user.set_interaction(src)
	var/dat
	if (src.temp)
		dat = "<TT>[src.temp]</TT><BR><BR><A href='?src=\ref[src];temp=1'>Clear Screen</A>"
	else
		if(screen == 0)
			dat += "<h3>Cyborg Control Console</h3><BR>"
			dat += "<A href='?src=\ref[src];screen=1'>1. Cyborg Status</A><BR>"
			dat += "<A href='?src=\ref[src];screen=2'>2. Emergency Full Destruct</A><BR>"
		if(screen == 1)
			for(var/mob/living/silicon/robot/R in GLOB.mob_list)
				if(istype(R, /mob/living/silicon/robot/drone))
					continue //There's a specific console for drones.
				if(isRemoteControlling(user))
					if (R.connected_ai != user)
						continue
				if(isrobot(user))
					if (R != user)
						continue
				if(R.scrambledcodes)
					continue

				dat += "[R.name] |"
				if(R.stat)
					dat += " Not Responding |"
				else if (!R.canmove)
					dat += " Locked Down |"
				else
					dat += " Operating Normally |"
				if (!R.canmove)
				else if(R.cell)
					dat += " Battery Installed ([R.cell.charge]/[R.cell.maxcharge]) |"
				else
					dat += " No Cell Installed |"
				if(R.module)
					dat += " Module Installed ([R.module.name]) |"
				else
					dat += " No Module Installed |"
				if(R.connected_ai)
					dat += " Slaved to [R.connected_ai.name] |"
				else
					dat += " Independent from AI |"
				if (isRemoteControlling(user))
					if((user.mind.original == user))
						dat += "<A href='?src=\ref[src];magbot=\ref[R]'>(<font color=blue><i>Hack</i></font>)</A> "
				dat += "<A href='?src=\ref[src];stopbot=\ref[R]'>(<font color=green><i>[R.canmove ? "Lockdown" : "Release"]</i></font>)</A> "
				dat += "<A href='?src=\ref[src];killbot=\ref[R]'>(<font color=red><i>Destroy</i></font>)</A>"
				dat += "<BR>"
			dat += "<A href='?src=\ref[src];screen=0'>(Return to Main Menu)</A><BR>"
		if(screen == 2)
			if(!src.status)
				dat += {"<BR><B>Emergency Robot Self-Destruct</B><HR>\nStatus: Off<BR>
				\n<BR>
				\nCountdown: [src.timeleft]/60 <A href='?src=\ref[src];reset=1'>\[Reset\]</A><BR>
				\n<BR>
				\n<A href='?src=\ref[src];eject=1'>Start Sequence</A><BR>
				\n<BR>
				\n<A href='?src=\ref[user];mach_close=computer'>Close</A>"}
			else
				dat = {"<B>Emergency Robot Self-Destruct</B><HR>\nStatus: Activated<BR>
				\n<BR>
				\nCountdown: [src.timeleft]/60 \[Reset\]<BR>
				\n<BR>\n<A href='?src=\ref[src];stop=1'>Stop Sequence</A><BR>
				\n<BR>
				\n<A href='?src=\ref[user];mach_close=computer'>Close</A>"}
			dat += "<A href='?src=\ref[src];screen=0'>(Return to Main Menu)</A><BR>"

	user << browse(dat, "window=computer;size=400x500")
	onclose(user, "computer")
	return

/obj/structure/machinery/computer/robotics/Topic(href, href_list)
	if(..())
		return
	if ((usr.contents.Find(src) || (in_range(src, usr) && istype(src.loc, /turf))) || (isRemoteControlling(usr)))
		usr.set_interaction(src)

		if (href_list["eject"])
			src.temp = {"Destroy Robots?<BR>
			<BR><B><A href='?src=\ref[src];eject2=1'>\[Swipe ID to initiate destruction sequence\]</A></B><BR>
			<A href='?src=\ref[src];temp=1'>Cancel</A>"}

		else if (href_list["eject2"])
			var/obj/item/card/id/I = usr.get_active_hand()
			if (istype(I))
				if(src.check_access(I))
					if (!status)
						message_staff("[key_name_admin(usr)] has initiated the global cyborg killswitch!")
						log_game(SPAN_NOTICE("[key_name(usr)] has initiated the global cyborg killswitch!"))
						src.status = 1
						src.start_sequence()
						src.temp = null

				else
					to_chat(usr, SPAN_DANGER("Access Denied."))

		else if (href_list["stop"])
			src.temp = {"
			Stop Robot Destruction Sequence?<BR>
			<BR><A href='?src=\ref[src];stop2=1'>Yes</A><BR>
			<A href='?src=\ref[src];temp=1'>No</A>"}

		else if (href_list["stop2"])
			src.stop = 1
			src.temp = null
			src.status = 0

		else if (href_list["reset"])
			src.timeleft = 60

		else if (href_list["temp"])
			src.temp = null
		else if (href_list["screen"])
			switch(href_list["screen"])
				if("0")
					screen = 0
				if("1")
					screen = 1
				if("2")
					screen = 2
		else if (href_list["killbot"])
			if(src.allowed(usr))
				var/mob/living/silicon/robot/R = locate(href_list["killbot"])
				if(R)
					var/choice = tgui_input_list(usr, "Are you certain you wish to detonate [R.name]?", "Hack machine", list("Confirm", "Abort"))
					if(choice == "Confirm")
						if(R && istype(R))
							message_staff("[key_name_admin(usr)] detonated [R.name]!")
							log_game(SPAN_NOTICE("[key_name_admin(usr)] detonated [R.name]!"))
							R.self_destruct()
			else
				to_chat(usr, SPAN_DANGER("Access Denied."))

		else if (href_list["stopbot"])
			if(src.allowed(usr))
				var/mob/living/silicon/robot/R = locate(href_list["stopbot"])
				if(R && istype(R)) // Extra sancheck because of input var references
					var/choice = tgui_input_list(usr, "Are you certain you wish to [R.canmove ? "lock down" : "release"] [R.name]?", "Hack machine", list("Confirm", "Abort"))
					if(choice == "Confirm")
						if(R && istype(R))
							message_staff("[key_name_admin(usr)] [R.canmove ? "locked down" : "released"] [R.name]!")
							log_game("[key_name(usr)] [R.canmove ? "locked down" : "released"] [R.name]!")
							R.canmove = !R.canmove
							if (R.lockcharge)
							// R.cell.charge = R.lockcharge
								R.lockcharge = !R.lockcharge
								to_chat(R, "Your lockdown has been lifted!")
							else
								R.lockcharge = !R.lockcharge
						// R.cell.charge = 0
								to_chat(R, "You have been locked down!")

			else
				to_chat(usr, SPAN_DANGER("Access Denied."))

		else if (href_list["magbot"])
			if(src.allowed(usr))
				var/mob/living/silicon/robot/R = locate(href_list["magbot"])

				// whatever weirdness this is supposed to be, but that is how the href gets added, so here it is again
				if(istype(R) && isRemoteControlling(usr) && (usr.mind.original == usr))

					var/choice = tgui_input_list(usr, "Are you certain you wish to hack [R.name]?", "Hack machine", list("Confirm", "Abort"))
					if(choice == "Confirm")
						if(R && istype(R))
							log_game("[key_name(usr)] emagged [R.name] using robotic console!")
							add_verb(R, /mob/living/silicon/robot/proc/ResetSecurityCodes)

		src.add_fingerprint(usr)
	src.updateUsrDialog()
	return

/obj/structure/machinery/computer/robotics/proc/start_sequence()
	while(src.timeleft)
		if(src.stop)
			src.stop = 0
			return
		src.timeleft--
	sleep(10)
	for(var/mob/living/silicon/robot/R in GLOB.mob_list)
		if(!R.scrambledcodes && !istype(R, /mob/living/silicon/robot/drone))
			R.self_destruct()

	return
