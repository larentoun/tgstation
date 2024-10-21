SUBSYSTEM_DEF(battlepass)
	name = "Battlepass"
	flags = SS_NO_FIRE
	init_order = -200
	var/battlepass_enabled = FALSE
	var/list/modify_list = list()
	var/list/top_list = list()

/datum/controller/subsystem/battlepass/Initialize()
	if(!SSdbcore.Connect())
		return SS_INIT_NO_NEED
	battlepass_enabled = TRUE
	var/datum/db_query/query = SSdbcore.NewQuery({"
		SELECT TOP 10 ckey, score FROM battlepass
		ORDER BY score ASC
	"})
	if(query.Execute(async = TRUE))
		while(query.NextRow())
			top_list["[query.item[1]]"] = query.item[2]
	qdel(query)

/datum/controller/subsystem/battlepass/Shutdown()
	save_scores()

/datum/controller/subsystem/battlepass/proc/save_scores()
	var/list/scores_to_modify = list()
	for(var/ckey in modify_list)
		if(!ckey || !modify_list[ckey])
			continue
		var/list/score_by_ckey = list("[ckey]" = max(modify_list[ckey], 0))
		var/datum/db_query/query = SSdbcore.NewQuery({"
			SELECT ckey, score FROM battlepass
			WHERE ckey=:ckey
		"}, list("ckey" = ckey))
		// Player is not in the DB
		if(!query)
			scores_to_modify[++scores_to_modify.len] += score_by_ckey
			continue
		if(!query.warn_execute())
			qdel(query)
			continue
		query.NextRow()
		score_by_ckey += list("[ckey]" = query.item[2])
		qdel(query)

		scores_to_modify[++scores_to_modify.len] += score_by_ckey
	if(!length(scores_to_modify))
		return
	SSdbcore.MassInsert(format_table_name("battlepass"), scores_to_modify)

/datum/controller/subsystem/battlepass/proc/update_score(player_ckey, value)
	if(!value || !player_ckey)
		return
	modify_list["[player_ckey]"] += value

/datum/controller/subsystem/battlepass
