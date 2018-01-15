#include <amxmodx>
#include <amxmisc>
#include <cromchat>
#include <hamsandwich>
#include <nvault>

#define PLUGIN_VERSION "2.0"
#define ARG_RANDOM -1
#define RANDOM_COLOR random_num(50, 255) 
#define FLAGS_DELAY 0.1

#if defined client_disconnected
	#define client_disconnect client_disconnected
#endif

enum _:Settings
{
	SAVE_TYPE,
	KILLS_NEEDED,
	VIP_FLAGS_BIT,
	VIP_FLAGS_STR[32],
	VIP_SUCCESS_MESSAGE,
	bool:HUD_MESSAGE_ENABLED,
	HUD_MESSAGE_COLOR[3],
	Float:HUD_MESSAGE_POSITION[2],
	Float:HUD_MESSAGE_DURATION,
	HUD_MESSAGE_EFFECTS,
	Float:HUD_MESSAGE_TIME[3]
}

enum _:PlayerData
{
	Name[32],
	Info[35],
	Kills
}

new g_eSettings[Settings],
	g_ePlayerData[33][PlayerData],
	g_iObject,
	g_iVault

public plugin_init()
{
	register_plugin("BecomeVIP Plus", PLUGIN_VERSION, "OciXCrom")
	register_cvar("CRXBecomeVIP", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY|FCVAR_UNLOGGED)
	register_dictionary("BecomeVIP.txt")
	register_event("DeathMsg", "OnPlayerKilled", "a")
	register_concmd("becomevip_give_kills", "Cmd_GiveKills", ADMIN_BAN, "<nick|#userid> <kills>")
	register_concmd("becomevip_reset_kills", "Cmd_ResetKills", ADMIN_BAN, "<nick|#userid>")
	ReadFile()
}

public plugin_end()
	nvault_close(g_iVault)

ReadFile()
{
	new szConfigsName[256], szFilename[256]
	get_configsdir(szConfigsName, charsmax(szConfigsName))
	formatex(szFilename, charsmax(szFilename), "%s/BecomeVIP.ini", szConfigsName)
	new iFilePointer = fopen(szFilename, "rt")
	
	if(iFilePointer)
	{
		new szData[96], szValue[64], szKey[32], szTemp[4][5], i
		
		while(!feof(iFilePointer))
		{
			fgets(iFilePointer, szData, charsmax(szData))
			trim(szData)
			
			switch(szData[0])
			{
				case EOS, '#', ';': continue
				default:
				{
					strtok(szData, szKey, charsmax(szKey), szValue, charsmax(szValue), '=')
					trim(szKey); trim(szValue)
					
					if(equal(szKey, "PLUGIN_PREFIX"))
						CC_SetPrefix(szValue)
					else if(equal(szKey, "SAVE_TYPE"))
						g_eSettings[SAVE_TYPE] = str_to_num(szValue)
					else if(equal(szKey, "KILLS_NEEDED"))
						g_eSettings[KILLS_NEEDED] = str_to_num(szValue)
					else if(equal(szKey, "VIP_FLAGS"))
					{
						copy(g_eSettings[VIP_FLAGS_STR], charsmax(g_eSettings[VIP_FLAGS_STR]), szValue)
						g_eSettings[VIP_FLAGS_BIT] = read_flags(szValue)
					}
					if(equal(szKey, "CHECK_KILLS_COMMANDS"))
					{
						while(szValue[0] != 0 && strtok(szValue, szKey, charsmax(szKey), szValue, charsmax(szValue), ','))
						{
							trim(szKey); trim(szValue)
							
							if(szKey[0] == '/' || szKey[0] == '!')
							{
								formatex(szData, charsmax(szData), "say %s", szKey)
								register_clcmd(szData, "Cmd_CheckKills")
								formatex(szData, charsmax(szData), "say_team %s", szKey)
								register_clcmd(szData, "Cmd_CheckKills")
							}
							else register_clcmd(szData, "Cmd_CheckKills")
						}
					}
					else if(equal(szKey, "VAULT_FILE"))
						g_iVault = nvault_open(szValue)
					else if(equal(szKey, "VIP_SUCCESS_MESSAGE"))
						g_eSettings[VIP_SUCCESS_MESSAGE] = str_to_num(szValue)
					else if(equal(szKey, "HUD_MESSAGE_ENABLED"))
					{
						g_eSettings[HUD_MESSAGE_ENABLED] = bool:str_to_num(szValue)
						
						if(g_eSettings[HUD_MESSAGE_ENABLED])
						{
							g_iObject = CreateHudSyncObj()
							RegisterHam(Ham_Spawn, "player", "OnPlayerSpawn", 1)
						}
					}
					else if(equal(szKey, "HUD_MESSAGE_COLOR"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]))
						
						for(i = 0; i < 3; i++)
							g_eSettings[HUD_MESSAGE_COLOR][i] = str_to_num(szTemp[i])
					}
					else if(equal(szKey, "HUD_MESSAGE_POSITION"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]))
						
						for(i = 0; i < 2; i++)
							g_eSettings[HUD_MESSAGE_POSITION][i] = _:str_to_float(szTemp[i])
					}
					else if(equal(szKey, "HUD_MESSAGE_DURATION"))
						g_eSettings[HUD_MESSAGE_DURATION] = _:str_to_float(szValue)
					else if(equal(szKey, "HUD_MESSAGE_EFFECTS"))
					{
						parse(szValue, szTemp[0], charsmax(szTemp[]), szTemp[1], charsmax(szTemp[]), szTemp[2], charsmax(szTemp[]), szTemp[3], charsmax(szTemp[]))
						g_eSettings[HUD_MESSAGE_EFFECTS] = str_to_num(szTemp[0])
						
						for(i = 0; i < 3; i++)
							g_eSettings[HUD_MESSAGE_TIME][i] = _:str_to_float(szTemp[i + 1])
					}
				}
			}
		}
		
		fclose(iFilePointer)
	}
}

public client_authorized(id)
{
	switch(g_eSettings[SAVE_TYPE])
	{
		case 0:
		{
			get_user_name(id, g_ePlayerData[id][Info], charsmax(g_ePlayerData[][Info]))
			strtolower(g_ePlayerData[id][Info])
		}
		case 1: get_user_ip(id, g_ePlayerData[id][Info], charsmax(g_ePlayerData[][Info]), 1)
		case 2: get_user_authid(id, g_ePlayerData[id][Info], charsmax(g_ePlayerData[][Info]))
	}
	
	get_user_name(id, g_ePlayerData[id][Name], charsmax(g_ePlayerData[][Name]))
	use_vault(id, false, g_ePlayerData[id][Info])
}

public client_disconnect(id)
	use_vault(id, true, g_ePlayerData[id][Info])
	
public client_infochanged(id)
{		
	static szNewName[32], szOldName[32]
	get_user_info(id, "name", szNewName, charsmax(szNewName))
	get_user_name(id, szOldName, charsmax(szOldName))
	
	if(!equal(szNewName, szOldName))
	{
		if(!g_eSettings[SAVE_TYPE])
		{
			use_vault(id, true, szOldName)
			use_vault(id, false, szNewName)
			copy(g_ePlayerData[id][Info], charsmax(g_ePlayerData[][Info]), szNewName)
			strtolower(g_ePlayerData[id][Info])
		}
		
		set_task(FLAGS_DELAY, "refresh_status", id)
		copy(g_ePlayerData[id][Name], charsmax(g_ePlayerData[][Name]), szNewName)
	}
}

public OnPlayerSpawn(id)
{
	if(!is_user_alive(id) || has_vip_flags(id))
		return
		
	set_hudmessage
	(
		g_eSettings[HUD_MESSAGE_COLOR][0] == ARG_RANDOM ? RANDOM_COLOR : g_eSettings[HUD_MESSAGE_COLOR][0],
		g_eSettings[HUD_MESSAGE_COLOR][1] == ARG_RANDOM ? RANDOM_COLOR : g_eSettings[HUD_MESSAGE_COLOR][1],
		g_eSettings[HUD_MESSAGE_COLOR][2] == ARG_RANDOM ? RANDOM_COLOR : g_eSettings[HUD_MESSAGE_COLOR][2],
		g_eSettings[HUD_MESSAGE_POSITION][0], g_eSettings[HUD_MESSAGE_POSITION][1],	g_eSettings[HUD_MESSAGE_EFFECTS],
		g_eSettings[HUD_MESSAGE_TIME][0], g_eSettings[HUD_MESSAGE_DURATION], g_eSettings[HUD_MESSAGE_TIME][1], g_eSettings[HUD_MESSAGE_TIME][2]
	)
	
	ShowSyncHudMsg(id, g_iObject, "%L", id, "BECOMEVIP_HUD_MSG", g_eSettings[KILLS_NEEDED], g_ePlayerData[id][Kills])
}

public OnPlayerKilled()
{
	new iAttacker = read_data(1), iVictim = read_data(2)
		
	if(is_user_connected(iAttacker) && iAttacker != iVictim)
	{
		g_ePlayerData[iAttacker][Kills]++
		check_status(iAttacker, true)
	}
}

public Cmd_CheckKills(id)
{
	if(has_vip_flags(id))
		CC_SendMessage(id, "%L", id, "BECOMEVIP_INFO_YES", g_eSettings[KILLS_NEEDED], g_eSettings[VIP_FLAGS_STR])
	else
		CC_SendMessage(id, "%L", id, "BECOMEVIP_INFO_NO", g_eSettings[KILLS_NEEDED] - g_ePlayerData[id][Kills], g_ePlayerData[id][Kills], g_eSettings[VIP_FLAGS_STR])
		
	return PLUGIN_HANDLED
}

public Cmd_GiveKills(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 3))
		return PLUGIN_HANDLED
		
	new szPlayer[32]
	read_argv(1, szPlayer, charsmax(szPlayer))
	
	new iPlayer = cmd_target(id, szPlayer, CMDTARGET_ALLOW_SELF)
	
	if(!iPlayer)
		return PLUGIN_HANDLED
		
	new szName[2][32], szAmount[8]
	get_user_name(id, szName[0], charsmax(szName[]))
	get_user_name(iPlayer, szName[1], charsmax(szName[]))
	read_argv(2, szAmount, charsmax(szAmount))
	
	new iAmount = str_to_num(szAmount)
	g_ePlayerData[iPlayer][Kills] += iAmount
	check_status(iPlayer, true)
	
	CC_LogMessage(0, _, "%L", LANG_PLAYER, iAmount >= 0 ? "BECOMEVIP_GIVE_KILLS" : "BECOMEVIP_TAKE_KILLS", szName[0], iAmount, szName[1])
	return PLUGIN_HANDLED
}

public Cmd_ResetKills(id, iLevel, iCid)
{
	if(!cmd_access(id, iLevel, iCid, 2))
		return PLUGIN_HANDLED
		
	new szPlayer[32]
	read_argv(1, szPlayer, charsmax(szPlayer))
	
	new iPlayer = cmd_target(id, szPlayer, CMDTARGET_ALLOW_SELF|CMDTARGET_OBEY_IMMUNITY)
	
	if(!iPlayer)
		return PLUGIN_HANDLED
		
	new szName[2][32]
	get_user_name(id, szName[0], charsmax(szName[]))
	get_user_name(iPlayer, szName[1], charsmax(szName[]))
	g_ePlayerData[iPlayer][Kills] = 0
	CC_LogMessage(0, _, "%L", LANG_PLAYER, "BECOMEVIP_RESET_KILLS", szName[0], szName[1])
	return PLUGIN_HANDLED
}

public refresh_status(id)
	check_status(id, false)

bool:check_status(const id, const bool:bAnnounce)
{
	if(has_vip_flags(id))
		return
		
	if(g_ePlayerData[id][Kills] >= g_eSettings[KILLS_NEEDED])
		set_vip_flags(id, bAnnounce)
}
	
set_vip_flags(const id, const bool:bAnnounce)
{
	set_user_flags(id, g_eSettings[VIP_FLAGS_BIT])
	
	if(bAnnounce)
	{
		switch(g_eSettings[VIP_SUCCESS_MESSAGE])
		{
			case 1: CC_SendMessage(id, "%L", id, "BECOMEVIP_SUCCESS_PLR", g_eSettings[VIP_FLAGS_STR], g_eSettings[KILLS_NEEDED])
			case 2: CC_SendMessage(0, "%L", LANG_PLAYER, "BECOMEVIP_SUCCESS_ALL", g_ePlayerData[id][Name], g_eSettings[VIP_FLAGS_STR], g_eSettings[KILLS_NEEDED])
		}
	}
}
	
bool:has_vip_flags(const id)
	return ((get_user_flags(id) & g_eSettings[VIP_FLAGS_BIT]) == g_eSettings[VIP_FLAGS_BIT])

use_vault(const id, const bool:bSave, const szInfo[])
{
	if(!szInfo[0])
		return
	
	if(bSave)
	{
		static szKills[10]
		num_to_str(g_ePlayerData[id][Kills], szKills, charsmax(szKills))
		nvault_set(g_iVault, szInfo, szKills)
	}
	else
	{
		g_ePlayerData[id][Kills] = nvault_get(g_iVault, szInfo)
		set_task(FLAGS_DELAY, "refresh_status", id)
	}
}

public plugin_natives()
{
	register_library("becomevip")
	register_native("becomevip_get_flags", "_becomevip_get_flags")
	register_native("becomevip_get_kills_needed", "_becomevip_get_kills_needed")
	register_native("becomevip_get_save_type", "_becomevip_get_save_type")
	register_native("becomevip_get_user_kills", "_becomevip_get_user_kills")
	register_native("becomevip_is_hud_enabled", "_becomevip_is_hud_enabled")
	register_native("becomevip_user_has_flags", "_becomevip_user_has_flags")
}

public _becomevip_get_flags(iPlugin, iParams)
	return g_eSettings[VIP_FLAGS_BIT]

public _becomevip_get_kills_needed(iPlugin, iParams)
	return g_eSettings[KILLS_NEEDED]
	
public _becomevip_get_save_type(iPlugin, iParams)
	return g_eSettings[SAVE_TYPE]
	
public _becomevip_get_user_kills(iPlugin, iParams)
	return g_ePlayerData[get_param(1)][Kills]
	
public bool:_becomevip_is_hud_enabled(iPlugin, iParams)
	return g_eSettings[HUD_MESSAGE_ENABLED]

public bool:_becomevip_user_has_flags(iPlugin, iParams)
	return has_vip_flags(get_param(1))