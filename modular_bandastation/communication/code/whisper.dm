/datum/keybinding/client/communication/whisper
	hotkey_keys = list("Y")
	name = WHIS_CHANNEL
	full_name = "IC Whisper"
	keybind_signal = COMSIG_KB_CLIENT_WHISPER_DOWN

/datum/keybinding/client/communication/whisper/down(client/user)
	. = ..()
	if(.)
		return
	winset(user, null, "command=[user.tgui_say_create_open_command(WHIS_CHANNEL)]")
	return TRUE

/datum/tgui_say/alter_entry(payload)
	/// No OOC leaks
	if(payload["channel"] == WHIS_CHANNEL)
		return pick(hurt_phrases)
	. = ..()

/datum/tgui_say/delegate_speech(entry, channel)
	switch(channel)
		if(WHIS_CHANNEL)
			client.mob.whisper_verb(entry)
			return TRUE
	. = ..()

/obj/item/gun/energy/laser/awaymission_aeg
	name = "Exploreverse Mk.I"
	ammo_type = list(/obj/item/ammo_casing/energy/lasergun/awaymission_aeg)

/obj/item/ammo_casing/energy/lasergun/awaymission_aeg
	e_cost = LASER_SHOTS(20, STANDARD_CELL_CHARGE)
