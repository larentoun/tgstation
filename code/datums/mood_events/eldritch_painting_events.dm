// These mood events are related to /obj/structure/sign/painting/eldritch
// Names are based on the subtype of painting they belong to

// Mood applied for ripping the painting
/datum/mood_event/eldritch_painting
	description = "ТЫ, МНЕ НЕ СЛЕДОВАЛО ЭТОГО ДЕЛАТЬ!!!"
	mood_change = -6
	timeout = 3 MINUTES

/datum/mood_event/eldritch_painting/weeping
	description = "ОН ЗДЕСЬ, И ОН ПЛАЧЕТ!"
	mood_change = -3
	timeout = 11 SECONDS

/datum/mood_event/eldritch_painting/weeping_heretic
	description = "О, какое искусство! Они прямо воодушевляют меня!"
	mood_change = 5
	timeout = 3 MINUTES

/datum/mood_event/eldritch_painting/weeping_withdrawal
	description = "Мой разум очистился от Его влияния."
	mood_change = 1
	timeout = 3 MINUTES

/datum/mood_event/eldritch_painting/desire_heretic
	description = "Орган получен, Мансус даёт и забирает. Что же оно забрало из меня?"
	mood_change = -2
	timeout = 3 MINUTES

/datum/mood_event/eldritch_painting/desire_examine
	description = "Сдерживаемый голод..."
	mood_change = 3
	timeout = 3 MINUTES

/datum/mood_event/eldritch_painting/heretic_vines
	description = "О, какой прекрасный цветок!"
	mood_change = 3
	timeout = 3 MINUTES

/datum/mood_event/eldritch_painting/rust_examine
	description = "Ржавый подъем может обождать..."
	mood_change = -2
	timeout = 3 MINUTES

/datum/mood_event/eldritch_painting/rust_heretic_examine
	description = "Мне нужно спешить на этот ржавый подъем!"
	mood_change = 6
	timeout = 3 MINUTES
