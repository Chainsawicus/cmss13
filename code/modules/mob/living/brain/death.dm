/mob/living/brain/death(var/cause, var/gibbed)
	if(!gibbed && istype(container, /obj/item/device/mmi)) //If not gibbed but in a container.
		container.icon_state = "mmi_dead"
	return ..(cause, gibbed, "beeps shrilly as the MMI flatlines!")

/mob/living/brain/gib(var/cause = "gibbing")
	if(istype(container, /obj/item/device/mmi))
		qdel(container)//Gets rid of the MMI if there is one
	if(loc)
		if(istype(loc,/obj/item/organ/brain))
			qdel(loc)//Gets rid of the brain item
	..(cause)
