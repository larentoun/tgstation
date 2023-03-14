#define ANALYZER_MODE_SURROUNDINGS 0
#define ANALYZER_MODE_TARGET 1
#define ANALYZER_HISTORY_SIZE 30

/obj/item/analyzer
	desc = "A hand-held environmental scanner which reports current gas levels."
	name = "gas analyzer"
	custom_price = PAYCHECK_LOWER * 0.9
	icon = 'icons/obj/device.dmi'
	icon_state = "analyzer"
	inhand_icon_state = "analyzer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	w_class = WEIGHT_CLASS_SMALL
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	slot_flags = ITEM_SLOT_BELT
	throwforce = 0
	throw_speed = 3
	throw_range = 7
	tool_behaviour = TOOL_ANALYZER
	custom_materials = list(/datum/material/iron=30, /datum/material/glass=20)
	grind_results = list(/datum/reagent/mercury = 5, /datum/reagent/iron = 5, /datum/reagent/silicon = 5)
	var/cooldown = FALSE
	var/cooldown_time = 250
	var/barometer_accuracy // 0 is the best accuracy.
	var/list/last_gasmix_data
	var/list/history_gasmix_data
	var/history_gasmix_index = 1
	var/scan_range = 1
	var/auto_updating = TRUE
	var/target_mode = ANALYZER_MODE_SURROUNDINGS
	var/atom/scan_target

/obj/item/analyzer/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_TOOL_ATOM_ACTED_PRIMARY(tool_behaviour), PROC_REF(on_analyze))

/obj/item/analyzer/equipped(mob/user, slot, initial)
	. = ..()
	ADD_TRAIT(user, TRAIT_DETECT_STORM, CLOTHING_TRAIT)

/obj/item/analyzer/dropped(mob/user, silent)
	. = ..()
	REMOVE_TRAIT(user, TRAIT_DETECT_STORM, CLOTHING_TRAIT)

/obj/item/analyzer/examine(mob/user)
	. = ..()
	. += span_notice("Right-click [src] to start scanning environment with TGUI. Right-click a target to start scanning it.")
	. += span_notice("Alt-click [src] to activate the barometer function.")

/obj/item/analyzer/suicide_act(mob/living/carbon/user)
	user.visible_message(span_suicide("[user] begins to analyze [user.p_them()]self with [src]! The display shows that [user.p_theyre()] dead!"))
	return BRUTELOSS

/obj/item/analyzer/AltClick(mob/user) //Barometer output for measuring when the next storm happens
	..()

	if(!user.can_perform_action(src, NEED_LITERACY|NEED_LIGHT))
		return

	if(cooldown)
		to_chat(user, span_warning("[src]'s barometer function is preparing itself."))
		return

	var/turf/T = get_turf(user)
	if(!T)
		return

	playsound(src, 'sound/effects/pop.ogg', 100)
	var/area/user_area = T.loc
	var/datum/weather/ongoing_weather = null

	if(!user_area.outdoors)
		to_chat(user, span_warning("[src]'s barometer function won't work indoors!"))
		return

	for(var/V in SSweather.processing)
		var/datum/weather/W = V
		if(W.barometer_predictable && (T.z in W.impacted_z_levels) && W.area_type == user_area.type && !(W.stage == END_STAGE))
			ongoing_weather = W
			break

	if(ongoing_weather)
		if((ongoing_weather.stage == MAIN_STAGE) || (ongoing_weather.stage == WIND_DOWN_STAGE))
			to_chat(user, span_warning("[src]'s barometer function can't trace anything while the storm is [ongoing_weather.stage == MAIN_STAGE ? "already here!" : "winding down."]"))
			return

		to_chat(user, span_notice("The next [ongoing_weather] will hit in [butchertime(ongoing_weather.next_hit_time - world.time)]."))
		if(ongoing_weather.aesthetic)
			to_chat(user, span_warning("[src]'s barometer function says that the next storm will breeze on by."))
	else
		var/next_hit = SSweather.next_hit_by_zlevel["[T.z]"]
		var/fixed = next_hit ? timeleft(next_hit) : -1
		if(fixed < 0)
			to_chat(user, span_warning("[src]'s barometer function was unable to trace any weather patterns."))
		else
			to_chat(user, span_warning("[src]'s barometer function says a storm will land in approximately [butchertime(fixed)]."))
	cooldown = TRUE
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/item/analyzer, ping)), cooldown_time)

/obj/item/analyzer/proc/ping()
	if(isliving(loc))
		var/mob/living/L = loc
		to_chat(L, span_notice("[src]'s barometer function is ready!"))
	playsound(src, 'sound/machines/click.ogg', 100)
	cooldown = FALSE

/// Applies the barometer inaccuracy to the gas reading.
/obj/item/analyzer/proc/butchertime(amount)
	if(!amount)
		return
	if(barometer_accuracy)
		var/inaccurate = round(barometer_accuracy*(1/3))
		if(prob(50))
			amount -= inaccurate
		if(prob(50))
			amount += inaccurate
	return DisplayTimeText(max(1,amount))

/obj/item/analyzer/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "GasAnalyzer", "Gas Analyzer")
		ui.open()

/obj/item/analyzer/ui_static_data(mob/user)
	return return_atmos_handbooks()

/obj/item/analyzer/ui_data(mob/user)
	var/list/data = list()
	if(auto_updating)
		on_analyze(source=src, target=scan_target)
	LAZYINITLIST(last_gasmix_data)
	LAZYINITLIST(history_gasmix_data)
	data["gasmixes"] = last_gasmix_data
	data["autoUpdating"] = auto_updating
	data["historyLength"] = length(history_gasmix_data)
	data["historyIndex"] = history_gasmix_index
	return data

/obj/item/analyzer/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	switch(action)
		if("autoscantoggle")
			auto_updating = !auto_updating
			return TRUE
		if("historybackwards")
			auto_updating = FALSE
			if(history_gasmix_index < length(history_gasmix_data))
				history_gasmix_index++
				last_gasmix_data = history_gasmix_data[history_gasmix_index]
			return TRUE
		if("historyforward")
			auto_updating = FALSE
			if(history_gasmix_index - 1 > 0)
				history_gasmix_index--
				if(history_gasmix_index <= length(history_gasmix_data))
					last_gasmix_data = history_gasmix_data[history_gasmix_index]
			return TRUE
		if("input")
			if(!length(history_gasmix_data))
				return TRUE
			var/target = params["target"]
			auto_updating = FALSE
			history_gasmix_index = target
			last_gasmix_data = history_gasmix_data[history_gasmix_index]
			return TRUE
		if("clearhistory")
			history_gasmix_index = 1
			history_gasmix_data = list()
			return TRUE


/obj/item/analyzer/attack_self(mob/user, modifiers)
	if(user.stat != CONSCIOUS || !user.can_read(src) || user.is_blind())
		return
	atmos_scan(user=user, target=get_turf(src), silent=FALSE)
	on_analyze(source=src, target=get_turf(src))

/obj/item/analyzer/attack_self_secondary(mob/user, modifiers)
	if(user.stat != CONSCIOUS || !user.can_read(src) || user.is_blind())
		return
	target_mode = ANALYZER_MODE_SURROUNDINGS
	atmos_scan(user=user, target=get_turf(src), silent=FALSE, print=FALSE)
	on_analyze(source=src, target=get_turf(src))
	ui_interact(user)

/obj/item/analyzer/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!can_see(user, target, scan_range))
		return
	. |= AFTERATTACK_PROCESSED_ITEM
	atmos_scan(user, target=(target.return_analyzable_air() ? target : get_turf(target)))
	on_analyze(source=src, target=(target.return_analyzable_air() ? target : get_turf(target)))

/obj/item/analyzer/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!can_see(user, target, scan_range))
		on_analyze(source=src, target=get_turf(src))
		ui_interact(user)
		return
	. |= AFTERATTACK_PROCESSED_ITEM
	target_mode = ANALYZER_MODE_TARGET
	atmos_scan(user, target=(target.return_analyzable_air() ? target : get_turf(target)), print=FALSE)
	on_analyze(source=src, target=(target.return_analyzable_air() ? target : get_turf(target)))
	ui_interact(user)

/// Called when our analyzer is used on something
/obj/item/analyzer/proc/on_analyze(datum/source, atom/target)
	SIGNAL_HANDLER
	LAZYINITLIST(history_gasmix_data)
	switch(target_mode)
		if(ANALYZER_MODE_SURROUNDINGS)
			scan_target = get_turf(src)
		if(ANALYZER_MODE_TARGET)
			scan_target = target
			if(!can_see(src, target, scan_range))
				target_mode = ANALYZER_MODE_SURROUNDINGS
				scan_target = get_turf(src)
			if(!scan_target)
				target_mode = ANALYZER_MODE_SURROUNDINGS
				scan_target = get_turf(src)

	var/mixture = scan_target.return_analyzable_air()
	if(!mixture)
		return FALSE
	var/list/airs = islist(mixture) ? mixture : list(mixture)
	var/list/new_gasmix_data = list()
	for(var/datum/gas_mixture/air as anything in airs)
		var/mix_name = capitalize(lowertext(scan_target.name))
		if(scan_target == get_turf(src))
			mix_name = "Location Reading"
		if(airs.len != 1) //not a unary gas mixture
			mix_name += " - Node [airs.Find(air)]"
		new_gasmix_data += list(gas_mixture_parser(air, mix_name))
	last_gasmix_data = new_gasmix_data
	if(length(history_gasmix_data) >= ANALYZER_HISTORY_SIZE)
		history_gasmix_data.Cut(ANALYZER_HISTORY_SIZE, length(history_gasmix_data) + 1)
	history_gasmix_data.Insert(1, list(new_gasmix_data))
	history_gasmix_index = 1


/**
 * Outputs a message to the user describing the target's gasmixes.
 *
 * Gets called by analyzer_act, which in turn is called by tool_act.
 * Also used in other chat-based gas scans.
 */
/proc/atmos_scan(mob/user, atom/target, silent=FALSE, print=TRUE)
	var/mixture = target.return_analyzable_air()
	if(!mixture)
		return FALSE

	var/icon = target
	var/message = list()
	if(!silent && isliving(user))
		user.visible_message(span_notice("[user] uses the analyzer on [icon2html(icon, viewers(user))] [target]."), span_notice("You use the analyzer on [icon2html(icon, user)] [target]."))
	message += span_boldnotice("Results of analysis of [icon2html(icon, user)] [target].")

	if(!print)
		return TRUE

	var/list/airs = islist(mixture) ? mixture : list(mixture)
	for(var/datum/gas_mixture/air as anything in airs)
		var/mix_name = capitalize(lowertext(target.name))
		if(airs.len > 1) //not a unary gas mixture
			var/mix_number = airs.Find(air)
			message += span_boldnotice("Node [mix_number]")
			mix_name += " - Node [mix_number]"

		var/total_moles = air.total_moles()
		var/pressure = air.return_pressure()
		var/volume = air.return_volume() //could just do mixture.volume... but safety, I guess?
		var/temperature = air.return_temperature()
		var/heat_capacity = air.heat_capacity()
		var/thermal_energy = air.thermal_energy()

		if(total_moles > 0)
			message += span_notice("Moles: [round(total_moles, 0.01)] mol")

			var/list/cached_gases = air.gases
			for(var/id in cached_gases)
				var/gas_concentration = cached_gases[id][MOLES]/total_moles
				message += span_notice("[cached_gases[id][GAS_META][META_GAS_NAME]]: [round(cached_gases[id][MOLES], 0.01)] mol ([round(gas_concentration*100, 0.01)] %)")
			message += span_notice("Temperature: [round(temperature - T0C,0.01)] &deg;C ([round(temperature, 0.01)] K)")
			message += span_notice("Volume: [volume] L")
			message += span_notice("Pressure: [round(pressure, 0.01)] kPa")
			message += span_notice("Heat Capacity: [display_joules(heat_capacity)] / K")
			message += span_notice("Thermal Energy: [display_joules(thermal_energy)]")
		else
			message += airs.len > 1 ? span_notice("This node is empty!") : span_notice("[target] is empty!")
			message += span_notice("Volume: [volume] L") // don't want to change the order volume appears in, suck it

	// we let the join apply newlines so we do need handholding
	to_chat(user, examine_block(jointext(message, "\n")), type = MESSAGE_TYPE_INFO)
	return TRUE

/obj/item/analyzer/ranged
	desc = "A hand-held long-range environmental scanner which reports current gas levels."
	name = "long-range gas analyzer"
	icon_state = "analyzerranged"
	worn_icon_state = "analyzer"
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/iron = 100, /datum/material/glass = 20, /datum/material/gold = 300, /datum/material/bluespace=200)
	grind_results = list(/datum/reagent/mercury = 5, /datum/reagent/iron = 5, /datum/reagent/silicon = 5)
	scan_range = 15;

#undef ANALYZER_MODE_SURROUNDINGS
#undef ANALYZER_MODE_TARGET
#undef ANALYZER_HISTORY_SIZE
