#pragma semicolon 1

#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <multicolors>

#pragma newdecls required

#define MAX_CLIENTS 129
#define MAX_ID      32
#define MAX_NAME    96
#define MAX_BUFF    512

bool g_bInBuyZoneAll              = false;
bool g_bInBuyZone[MAXPLAYERS + 1] = { false, ... };

bool g_bInfAmmoHooked           = false;
bool g_bInfAmmoAll              = false;
bool g_bInfAmmo[MAXPLAYERS + 1] = { false, ... };

bool g_bLate = false;

ConVar g_CVar_sv_pausable;
ConVar g_CVar_sv_bombanywhere;

float coords[MAX_CLIENTS][3];

static char g_sServerCanExecuteCmds[][] = { "cl_soundscape_flush", "r_screenoverlay", "playgamesound",
	                                        "slot0", "slot1", "slot2", "slot3", "slot4", "slot5", "slot6",
	                                        "slot7", "slot8", "slot9", "slot10", "cl_spec_mode", "cancelselect",
	                                        "invnext", "play", "invprev", "sndplaydelay", "lastinv", "dsp_player",
	                                        "name", "redirect", "retry", "r_cleardecals", "echo", "soundfade" };

public Plugin myinfo =
{
	name        = "Advanced Commands",
	author      = "BotoX + Obus + maxime1907, .Rushaway",
	description = "Adds extra commands for admins.",
	version     = "2.7.4",
	url         = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	g_bLate = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_hp", Command_Health, ADMFLAG_GENERIC, "sm_hp <#userid|name> <value>");
	RegAdminCmd("sm_health", Command_Health, ADMFLAG_GENERIC, "sm_health <#userid|name> <value>");
	RegAdminCmd("sm_armor", Command_Armor, ADMFLAG_GENERIC, "sm_armor <#userid|name> <value>");
	RegAdminCmd("sm_weapon", Command_Weapon, ADMFLAG_GENERIC, "sm_weapon <#userid|name> <name> [clip] [ammo]");
	RegAdminCmd("sm_give", Command_Weapon, ADMFLAG_GENERIC, "sm_give <#userid|name> <name> [clip] [ammo]");
	RegAdminCmd("sm_strip", Command_Strip, ADMFLAG_GENERIC, "sm_strip <#userid|name>");
	RegAdminCmd("sm_buyzone", Command_BuyZone, ADMFLAG_GENERIC, "sm_buyzone <#userid|name> <0|1>");
	RegAdminCmd("sm_iammo", Command_InfAmmo, ADMFLAG_GENERIC, "sm_iammo <#userid|name> <0|1>");
	RegAdminCmd("sm_speed", Command_Speed, ADMFLAG_GENERIC, "sm_speed <#userid|name> <value>");
	RegAdminCmd("sm_respawn", Command_Respawn, ADMFLAG_GENERIC, "sm_respawn <#userid|name>");
	RegAdminCmd("sm_team", Command_Team, ADMFLAG_GENERIC, "sm_team <#userid|name> <team> [alive]");
	RegAdminCmd("sm_cash", Command_Cash, ADMFLAG_GENERIC, "sm_cash <#userid|name> <value>");
	RegAdminCmd("sm_modelscale", Command_ModelScale, ADMFLAG_GENERIC, "sm_modelscale <#userid|name> <scale>");
	RegAdminCmd("sm_resize", Command_ModelScale, ADMFLAG_GENERIC, "sm_resize <#userid|name> <scale>");
	RegAdminCmd("sm_setmodel", Command_SetModel, ADMFLAG_GENERIC, "sm_setmodel <#userid|name> <modelpath>");
	RegAdminCmd("sm_setscore", Command_SetScore, ADMFLAG_GENERIC, "sm_setscore <#userid|name> <value>");
	RegAdminCmd("sm_setdeaths", Command_SetDeaths, ADMFLAG_GENERIC, "sm_setdeaths <#userid|name> <value>");
	RegAdminCmd("sm_setmvp", Command_SetMvp, ADMFLAG_GENERIC, "sm_setmvp <#userid|name> <value>");
	RegAdminCmd("sm_setteamscore", Command_SetTeamScore, ADMFLAG_GENERIC, "sm_setteamscore <team> <value>");
	RegAdminCmd("sm_teamscore", Command_SetTeamScore, ADMFLAG_GENERIC, "sm_teamscore <team> <value>");
	RegAdminCmd("sm_restartround", Command_RestartRound, ADMFLAG_GENERIC, "sm_restartround <delay>");
	RegAdminCmd("sm_rr", Command_RestartRound, ADMFLAG_GENERIC, "sm_rr <delay>");
	RegAdminCmd("sm_nv", Command_NV, ADMFLAG_GENERIC, "sm_nv <#userid|name>");
	RegAdminCmd("sm_defuser", Command_Defuser, ADMFLAG_GENERIC, "sm_defuser <#userid|name>");
	RegAdminCmd("sm_querycvar", Command_QueryCVar, ADMFLAG_GENERIC, "sm_querycvar <#userid|name> [cvar]");
	RegAdminCmd("sm_waila", Command_WAILA, ADMFLAG_GENERIC, "sm_waila");
	RegAdminCmd("sm_info", Command_WAILA, ADMFLAG_GENERIC, "sm_info");
	RegAdminCmd("sm_balance", Command_Balance, ADMFLAG_GENERIC, "sm_balance");
	RegAdminCmd("sm_forcespec", Command_ForceSpec, ADMFLAG_KICK, "sm_forcespec <#userid|name>");
	RegAdminCmd("sm_shuffle", Command_Shuffle, ADMFLAG_KICK, "sm_shuffle");
	RegAdminCmd("sm_teamswap", Command_TeamSwap, ADMFLAG_KICK, "sm_teamswap");
	RegAdminCmd("sm_getloc", Command_Location, ADMFLAG_BAN, "sm_getloc <#userid|name>");
	RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_BAN, "sm_teleport <#userid|name> <#userid|name>");
	RegAdminCmd("sm_getmodel", Command_GetModel, ADMFLAG_BAN, "sm_getmodel <#userid|name>");
	RegAdminCmd("sm_god", Command_God, ADMFLAG_BAN, "sm_god <#userid|name> <0|1>");
	RegAdminCmd("sm_saveloc", Command_SaveLoc, ADMFLAG_BAN, "sm_saveloc");
	RegAdminCmd("sm_uptime", Command_Uptime, ADMFLAG_CHEATS, "sm_uptime");
	RegAdminCmd("sm_fcvar", Command_ForceCVar, ADMFLAG_CHEATS, "sm_fcvar <#userid|name> <cvar> <value>");
	RegAdminCmd("sm_setclantag", Command_SetClanTag, ADMFLAG_CHEATS, "sm_setclantag <#userid|name> [text]");
	RegAdminCmd("sm_fakecommand", Command_FakeCommand, ADMFLAG_CHEATS, "sm_fakecommand <#userid|name> [command] [args]");

	HookEvent("bomb_planted", Event_BombPlanted, EventHookMode_Pre);
	HookEvent("bomb_defused", Event_BombDefused, EventHookMode_Pre);

	g_CVar_sv_pausable     = FindConVar("sv_pausable");
	g_CVar_sv_bombanywhere = CreateConVar("sv_bombanywhere", "0", "Allows the bomb to be planted anywhere", FCVAR_NOTIFY);

	AutoExecConfig(true);

	if (g_CVar_sv_pausable)
	{
		AddCommandListener(Listener_Pause, "pause");
		AddCommandListener(Listener_Pause, "setpause");    // doesn't work on win32 srcds?
		AddCommandListener(Listener_Pause, "unpause");     // doesn't work on win32 srcds?
	}

	/* Handle late load */
	if (g_bLate)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i))
			{
				OnClientPutInServer(i);
			}
		}
	}
}

public void OnPluginEnd()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		SDKUnhook(i, SDKHook_PreThink, OnPreThink);
		SDKUnhook(i, SDKHook_PostThinkPost, OnPostThinkPost);
	}
}

public void OnMapStart()
{
	g_bInBuyZoneAll = false;
	g_bInfAmmoAll   = false;

	if (g_bInfAmmoHooked)
	{
		UnhookEvent("weapon_fire", Event_WeaponFire);
		g_bInfAmmoHooked = false;
	}
}

public Action Listener_Pause(int client, const char[] command, int argc)
{
	static bool bPaused;

	if (!g_CVar_sv_pausable.BoolValue)
	{
		CReplyToCommand(client, "{green}[SM]{default} \"sv_pausable\" is set to 0!");
		return Plugin_Handled;
	}

	if (!IsClientAuthorized(client) || !GetAdminFlag(GetUserAdmin(client), Admin_Root))
	{
		CReplyToCommand(client, "{green}[SM]{default} You do not have permission to pause/unpause the game.");
		return Plugin_Handled;
	}

	if (strcmp(command, "setpause") == 0)
		bPaused = true;
	else if (strcmp(command, "unpause") == 0)
		bPaused = false;
	else
		bPaused = !bPaused;

	CShowActivity2(client, "{green}[SM] {olive}", "{red}%s the game.", bPaused ? "Paused" : "Unpaused");
	LogAction(client, -1, "\"%L\" %s the game.", client, bPaused ? "Paused" : "Unpaused");

	return Plugin_Continue;
}

public Action Event_BombPlanted(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			ClientCommand(i, "playgamesound \"radio/bombpl.wav\"");
	}
	return Plugin_Handled;
}

public Action Event_BombDefused(Handle event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			ClientCommand(i, "playgamesound \"radio/bombdef.wav\"");
	}
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	g_bInBuyZone[client] = false;
	g_bInfAmmo[client]   = false;

	SDKHook(client, SDKHook_PreThink, OnPreThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnClientDisconnect(int client)
{
	g_bInBuyZone[client] = false;
	g_bInfAmmo[client]   = false;

	SDKUnhook(client, SDKHook_PreThink, OnPreThink);
	SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);
}

public void OnPreThink(int client)
{
	if (g_CVar_sv_bombanywhere.IntValue >= 1)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			SetEntProp(client, Prop_Send, "m_bInBombZone", 1);
		}
	}
}

public void OnPostThinkPost(int client)
{
	if (g_bInBuyZoneAll || g_bInBuyZone[client])
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			SetEntProp(client, Prop_Send, "m_bInBuyZone", 1);
		}
	}
}

public void Event_WeaponFire(Handle hEvent, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!g_bInfAmmoAll && !g_bInfAmmo[client])
		return;

	int weapon = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon", 0);
	if (IsValidEntity(weapon))
	{
		if (weapon == GetPlayerWeaponSlot(client, 0) || weapon == GetPlayerWeaponSlot(client, 1))
		{
			if (GetEntProp(weapon, Prop_Send, "m_iState", 4, 0) == 2 && GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0))
			{
				int  toAdd = 1;
				char weaponClassname[128];
				GetEntityClassname(weapon, weaponClassname, sizeof(weaponClassname));

				if (StrEqual(weaponClassname, "weapon_glock", true) || StrEqual(weaponClassname, "weapon_famas", true))
				{
					if (GetEntProp(weapon, Prop_Send, "m_bBurstMode"))
					{
						switch (GetEntProp(weapon, Prop_Send, "m_iClip1"))
						{
							case 1:
							{
								toAdd = 1;
							}
							case 2:
							{
								toAdd = 2;
							}
							default:
							{
								toAdd = 3;
							}
						}
					}
				}

				SetEntProp(weapon, Prop_Send, "m_iClip1", GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0) + toAdd, 4, 0);
			}
		}
	}

	return;
}

public Action Command_Health(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_hp <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[65];
	char sArgs2[20];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int amount = clamp(StringToInt(sArgs2), 1, 0x7FFFFFFF);

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Send, "m_iHealth", amount, 1);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set health to {green}%d{default} on {olive}%s{default}.", amount, sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set health to \"%d\" on \"%s\"", client, amount, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set health to \"%d\" on \"%L\"", client, amount, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_Armor(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_armor <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[65];
	char sArgs2[20];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int amount = clamp(StringToInt(sArgs2), 0, 0xFF);

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Send, "m_ArmorValue", amount, 1);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set kevlar to {green}%d{default} on {olive}%s{default}.", amount, sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set kevlar to \"%d\" on \"%s\"", client, amount, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set kevlar to \"%d\" on \"%L\"", client, amount, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_Weapon(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_weapon <#userid|name> <weapon> [clip] [ammo]");
		return Plugin_Handled;
	}

	int ammo = 2500;
	int clip = -1;

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	char sArgs2[65];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	char sWeapon[65];

	if (strncmp(sArgs2, "weapon_", 7) != 0 && strncmp(sArgs2, "item_", 5) != 0 && !StrEqual(sArgs2, "nvg", false))
		Format(sWeapon, sizeof(sWeapon), "weapon_%s", sArgs2);
	else
		strcopy(sWeapon, sizeof(sWeapon), sArgs2);

	if (StrContains(sWeapon, "grenade", false) != -1 || StrContains(sWeapon, "flashbang", false) != -1 || strncmp(sArgs2, "item_", 5) == 0)
		ammo = -1;

	if (client >= 1)
	{
		AdminId id         = GetUserAdmin(client);
		int     superadmin = GetAdminFlag(id, Admin_Cheats);

		if (!superadmin)
		{
			if (StrEqual(sWeapon, "weapon_c4", false) || StrEqual(sWeapon, "weapon_smokegrenade", false) || StrEqual(sWeapon, "item_defuser", false))
			{
				CReplyToCommand(client, "{green}[SM]{default} This weapon is restricted!");
				return Plugin_Handled;
			}
		}
	}

	if (argc >= 3)
	{
		char sArgs3[20];
		GetCmdArg(3, sArgs3, sizeof(sArgs3));

		if (StringToIntEx(sArgs3, clip) == 0)
		{
			CReplyToCommand(client, "{green}[SM]{default} Invalid Clip Value.");
			return Plugin_Handled;
		}
	}

	if (argc >= 4)
	{
		char sArgs4[20];
		GetCmdArg(4, sArgs4, sizeof(sArgs4));

		if (StringToIntEx(sArgs4, ammo) == 0)
		{
			CReplyToCommand(client, "{green}[SM]{default} Invalid Ammo Value.");
			return Plugin_Handled;
		}
	}

	if (StrContains(sWeapon, "grenade", false) != -1 || StrContains(sWeapon, "flashbang", false) != -1)
	{
		int tmp = ammo;
		ammo    = clip;
		clip    = tmp;
	}

	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	if (StrEqual(sWeapon, "nvg", false))
	{
		for (int i = 0; i < iTargetCount; i++)
			SetEntProp(iTargets[i], Prop_Send, "m_bHasNightVision", 1, 1);
	}
	else if (StrEqual(sWeapon, "item_defuser", false))
	{
		for (int i = 0; i < iTargetCount; i++)
			SetEntProp(iTargets[i], Prop_Send, "m_bHasDefuser", 1);
	}
	else
	{
		for (int i = 0; i < iTargetCount; i++)
		{
			int ent = GivePlayerItemFixed(iTargets[i], sWeapon);

			if (ent == -1)
			{
				CReplyToCommand(client, "{green}[SM]{default} Invalid Weapon.");
				return Plugin_Handled;
			}

			if (clip != -1)
				SetEntProp(ent, Prop_Send, "m_iClip1", clip);

			if (ammo != -1)
			{
				int PrimaryAmmoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");

				if (PrimaryAmmoType != -1)
					SetEntProp(iTargets[i], Prop_Send, "m_iAmmo", ammo, _, PrimaryAmmoType);
			}

			if (strncmp(sArgs2, "item_", 5) != 0 && !StrEqual(sWeapon, "weapon_hegrenade", false))
				EquipPlayerWeapon(iTargets[i], ent);

			if (ammo != -1)
			{
				int PrimaryAmmoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");

				if (PrimaryAmmoType != -1)
					SetEntProp(iTargets[i], Prop_Send, "m_iAmmo", ammo, _, PrimaryAmmoType);
			}
		}
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Gave {green}%s{default} to {olive}%s{default}.", sWeapon, sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" gave \"%s\" to \"%s\"", client, sWeapon, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" gave \"%s\" to \"%L\"", client, sWeapon, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_Strip(int client, int argc)
{
	if (argc < 1)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_strip <#userid|name>");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		for (int j = 0; j < 5; j++)
		{
			int w = -1;

			while ((w = GetPlayerWeaponSlot(iTargets[i], j)) != -1)
			{
				if (IsValidEntity(w) && IsValidEdict(w))
				{
					RemovePlayerItem(iTargets[i], w);
					AcceptEntityInput(w, "Kill");
				}
			}
		}
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Stripped all weapons from {olive}%s{default}.", sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" stripped all weapons from \"%s\"", client, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" stripped all weapons from \"%L\"", client, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_BuyZone(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_buyzone <#userid|name> <0|1>");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	int  value = -1;
	char sArgs2[20];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	if (StringToIntEx(sArgs2, value) == 0)
	{
		CReplyToCommand(client, "{green}[SM]{default} Invalid Value.");
		return Plugin_Handled;
	}

	char sTargetName[MAX_TARGET_LENGTH];

	if (StrEqual(sArgs, "@all", false))
	{
		sTargetName     = "all players";
		g_bInBuyZoneAll = value ? true : false;
	}
	else
	{
		int  iTargets[MAXPLAYERS];
		int  iTargetCount;
		bool bIsML;

		if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
		{
			ReplyToTargetError(client, iTargetCount);
			return Plugin_Handled;
		}

		for (int i = 0; i < iTargetCount; i++)
		{
			g_bInBuyZone[iTargets[i]] = value ? true : false;
		}
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{green}%s{default} permanent buyzone on {olive}%s{default}.", (value ? "Enabled" : "Disabled"), sTargetName);
	LogAction(client, -1, "\"%L\" %s permanent buyzone on \"%s\"", client, (value ? "enabled" : "disabled"), sTargetName);

	return Plugin_Handled;
}

public Action Command_InfAmmo(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_iammo <#userid|name> <0|1>");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	int  value = -1;
	char sArgs2[20];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	if (StringToIntEx(sArgs2, value) == 0)
	{
		CReplyToCommand(client, "{green}[SM]{default} Invalid Value.");
		return Plugin_Handled;
	}

	char sTargetName[MAX_TARGET_LENGTH];

	if (StrEqual(sArgs, "@all", false))
	{
		sTargetName   = "all players";
		g_bInfAmmoAll = value ? true : false;

		if (!g_bInfAmmoAll)
		{
			for (int i = 0; i < MAXPLAYERS; i++)
				g_bInfAmmo[i] = false;
		}
	}
	else
	{
		int  iTargets[MAXPLAYERS];
		int  iTargetCount;
		bool bIsML;

		if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
		{
			ReplyToTargetError(client, iTargetCount);
			return Plugin_Handled;
		}

		for (int i = 0; i < iTargetCount; i++)
		{
			g_bInfAmmo[iTargets[i]] = value ? true : false;
		}
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{green}%s{default} infinite ammo on {olive}%s{default}.", (value ? "Enabled" : "Disabled"), sTargetName);
	LogAction(client, -1, "\"%L\" %s infinite ammo on \"%s\"", client, (value ? "enabled" : "disabled"), sTargetName);

	if (g_bInfAmmoAll)
	{
		if (!g_bInfAmmoHooked)
		{
			HookEvent("weapon_fire", Event_WeaponFire);
			g_bInfAmmoHooked = true;
		}

		return Plugin_Handled;
	}

	for (int i = 0; i < MAXPLAYERS; i++)
	{
		if (g_bInfAmmo[i])
		{
			if (!g_bInfAmmoHooked)
			{
				HookEvent("weapon_fire", Event_WeaponFire);
				g_bInfAmmoHooked = true;
			}

			return Plugin_Handled;
		}
	}

	if (g_bInfAmmoHooked)
	{
		UnhookEvent("weapon_fire", Event_WeaponFire);
		g_bInfAmmoHooked = false;
	}

	return Plugin_Handled;
}

public Action Command_Speed(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_speed <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[65];
	char sArgs2[20];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	float speed = clamp(StringToFloat(sArgs2), 0.0, 100.0);

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntPropFloat(iTargets[i], Prop_Data, "m_flLaggedMovementValue", speed);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set speed to {green}%.2f{default} on {olive}%s{default}.", speed, sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set speed to \"%.2f\" on \"%s\"", client, speed, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set speed to \"%.2f\" on \"%L\"", client, speed, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_Respawn(int client, int argc)
{
	if (argc < 1)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_respawn <#userid|name>");
		return Plugin_Handled;
	}

	char pattern[MAX_NAME], buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	int  targets[MAX_CLIENTS];
	bool ml = false;
	int  count;

	if ((count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_CONNECTED | COMMAND_FILTER_DEAD | COMMAND_FILTER_NO_IMMUNITY, buffer, sizeof(buffer), ml)) <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	for (int i = 0; i < count; i++)
	{
		int t = targets[i];
		if (IsClientInGame(t) && GetClientTeam(t) > 1)
		{
			CS_RespawnPlayer(t);
		}
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Respawned {olive}%s", buffer);

	if (count > 1)
		LogAction(client, -1, "\"%L\" respawned \"%s\"", client, buffer);
	else
		LogAction(client, targets[0], "\"%L\" respawned \"%L\"", client, targets[0]);

	return Plugin_Handled;
}

public Action Command_Team(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_team <#userid|name> <team>");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	int  iTeam = CS_TEAM_NONE;
	char sArgs2[8];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	bool bAlive = false;
	if (argc >= 3)
	{
		char sArgs3[8];
		GetCmdArg(3, sArgs3, sizeof(sArgs3));
		if (StringToInt(sArgs3))
			bAlive = true;
	}

	if (StringToIntEx(sArgs2, iTeam) == 0 || iTeam < CS_TEAM_NONE || iTeam > CS_TEAM_CT)
	{
		CReplyToCommand(client, "{green}[SM]{default} Invalid Value.");
		return Plugin_Handled;
	}

	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		if (bAlive)
			CS_SwitchTeam(iTargets[i], iTeam);
		else
			ChangeClientTeam(iTargets[i], iTeam);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Changed {olive}%s{default} to team {green}%d{default}.", sTargetName, iTeam);
	LogAction(client, -1, "\"%L\" changed team%s to %d on \"%s\"", client, bAlive ? " ALIVE" : "", iTeam, sTargetName);

	return Plugin_Handled;
}

public Action Command_Cash(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_cash <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[64];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iCash = clamp(StringToInt(sArgs2), 0, 0xFFFF);

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Send, "m_iAccount", iCash);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set cash to {green}%d{default} on {olive}%s{default}.", iCash, sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set cash to \"%d\" on \"%s\"", client, iCash, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set cash to \"%d\" on \"%L\"", client, iCash, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_ModelScale(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_resize/sm_modelscale <#userid|name> <scale>");
		return Plugin_Handled;
	}

	char sArgs[64];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	float fScale = clamp(StringToFloat(sArgs2), 0.0, 100.0);

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntPropFloat(iTargets[i], Prop_Send, "m_flModelScale", fScale);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set model scale to {green}%.2f{default} on {olive}%s{default}.", fScale, sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set model scale to \"%.2f\" on \"%s\"", client, fScale, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set model scale to \"%.2f\" on \"%L\"", client, fScale, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_SetModel(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_setmodel <#userid|name> <modelpath>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[PLATFORM_MAX_PATH];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	if (!FileExists(sArgs2, true))
	{
		CReplyToCommand(client, "{green}[SM]{default} File {green}%s {default}does not exist.", sArgs2);
		return Plugin_Handled;
	}

	if (!IsModelPrecached(sArgs2))
	{
		CReplyToCommand(client, "{green}[SM]{default} File {green}%s {default}is not precached, attempting to precache now.", sArgs2);

		PrecacheModel(sArgs2);
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntityModel(iTargets[i], sArgs2);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set model to {green}%s{default} on {olive}%s{default}.", sArgs2, sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set model to \"%s\" on \"%s\"", client, sArgs2, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set model to \"%s\" on \"%L\"", client, sArgs2, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_SetScore(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_setscore <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iVal = StringToInt(sArgs2);

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Data, "m_iFrags", iVal);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set score to {green}%d{default} on {olive}%s{default}.", iVal, sTargetName);

	if (iTargetCount > 1)
		LogAction(client, -1, "\"%L\" set score to \"%d\" on \"%s\"", client, iVal, sTargetName);
	else
		LogAction(client, iTargets[0], "\"%L\" set score to \"%d\" on \"%L\"", client, iVal, iTargets[0]);

	return Plugin_Handled;
}

public Action Command_SetDeaths(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_setdeaths <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iVal = StringToInt(sArgs2);

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Data, "m_iDeaths", iVal);
	}

	if (iTargetCount > 1)
	{
		CShowActivity2(client, "{green}[SM] {olive}", "{default}Set deaths to {green}%d{default} on {olive}%s{default}.", iVal, sTargetName);
		LogAction(client, -1, "\"%L\" set deaths to \"%d\" on \"%s\"", client, iVal, sTargetName);
	}
	else
	{
		CShowActivity2(client, "{green}[SM] {olive}", "{default}Set deaths to {green}%d{default} on {olive}%s{default}.", iVal, sTargetName);
		LogAction(client, iTargets[0], "\"%L\" set deaths to \"%d\" on \"%L\"", client, iVal, iTargets[0]);
	}

	return Plugin_Handled;
}

public Action Command_SetMvp(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_setmvp <#userid|name> <value>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[32];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iVal = StringToInt(sArgs2);

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		CS_SetMVPCount(iTargets[i], iVal);
	}

	if (iTargetCount > 1)
	{
		CShowActivity2(client, "{green}[SM] {olive}", "{default}Set MVP to {green}%d{default} on {olive}%s{default}.", iVal, sTargetName);
		LogAction(client, -1, "\"%L\" set MVP to \"%d\" on \"%s\"", client, iVal, sTargetName);
	}
	else
	{
		CShowActivity2(client, "{green}[SM] {olive}", "{default}Set MVP to {green}%d{default} on {olive}%s{default}.", iVal, sTargetName);
		LogAction(client, iTargets[0], "\"%L\" set MVP to \"%d\" on \"%L\"", client, iVal, iTargets[0]);
	}

	return Plugin_Handled;
}

public Action Command_SetTeamScore(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_setteamscore <team> <value>");
		return Plugin_Handled;
	}

	char sArgs[32];
	char sArgs2[32];

	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int iVal = StringToInt(sArgs2);

	if (strcmp(sArgs, "@ct", false) == 0 || strcmp(sArgs, "@cts", false) == 0)
	{
		SetTeamScore(CS_TEAM_CT, iVal);
		CS_SetTeamScore(CS_TEAM_CT, iVal);

		CShowActivity2(client, "{green}[SM] {olive}", "{default}Set team-score to {green}%d{default} for {blue}Humans{default}.", iVal);
		LogAction(client, -1, "\"%L\" set team-score to \"%d\" for \"Humans\"", client, iVal);
	}
	else if (strcmp(sArgs, "@t", false) == 0 || strcmp(sArgs, "@ts", false) == 0)
	{
		SetTeamScore(CS_TEAM_T, iVal);
		CS_SetTeamScore(CS_TEAM_T, iVal);

		CShowActivity2(client, "{green}[SM] {olive}", "{default}Set team-score to {green}%d{default} for {red}Zombies{default}.", iVal);
		LogAction(client, -1, "\"%L\" set team-score to \"%d\" for \"Zombies\"", client, iVal);
	}
	else
	{
		CReplyToCommand(client, "{green}[SM]{default} Invalid team.");
	}

	return Plugin_Handled;
}

public Action Command_RestartRound(int client, int argc)
{
	float fDelay = 2.0;

	if (argc)
	{
		char sArgs[32];
		GetCmdArg(1, sArgs, sizeof(sArgs));
		fDelay = StringToFloat(sArgs);
	}

	CS_TerminateRound(fDelay, CSRoundEnd_Draw, true);

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Restarted the round. ({olive}%f seconds{default})", fDelay);
	LogAction(client, -1, "\"%L\" restarted the round (%f seconds)", client, fDelay);

	return Plugin_Handled;
}

public Action Command_WAILA(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] Cannot use this command from server console.");
		return Plugin_Handled;
	}

	float vecEyeAngles[3];
	float vecEyeOrigin[3];

	GetClientEyeAngles(client, vecEyeAngles);
	GetClientEyePosition(client, vecEyeOrigin);

	Handle hTraceRay = TR_TraceRayFilterEx(vecEyeOrigin, vecEyeAngles, MASK_ALL, RayType_Infinite, TraceEntityFilter_FilterCaller, client);

	if (TR_DidHit(hTraceRay))
	{
		float vecEndPos[3];
		char  sModelPath[PLATFORM_MAX_PATH];
		char  sClsName[64];
		char  sNetClsName[64];
		char  sTargetname[64];
		int   iEntity;
		int   iEntityModelIdx;
		int   iHammerID;

		TR_GetEndPosition(vecEndPos, hTraceRay);

		if ((iEntity = TR_GetEntityIndex(hTraceRay)) <= 0)
		{
			CPrintToChat(client, "{green}[SM]{default} Trace hit the world.");

			delete hTraceRay;

			return Plugin_Handled;
		}

		GetEntPropString(iEntity, Prop_Data, "m_ModelName", sModelPath, sizeof(sModelPath));
		GetEntityClassname(iEntity, sClsName, sizeof(sClsName));
		GetEntityNetClass(iEntity, sNetClsName, sizeof(sNetClsName));
		GetEntPropString(iEntity, Prop_Data, "m_iName", sTargetname, sizeof(sTargetname));
		iEntityModelIdx = GetEntProp(iEntity, Prop_Send, "m_nModelIndex");
		iHammerID       = GetEntProp(iEntity, Prop_Data, "m_iHammerID");

		PrintToConsole(client, "Entity Index: %i\nHammer ID: %d\nTarget name: %s\nModel Path: %s\nModel Index: %i\nClass Name: %s\nNet Class Name: %s", iEntity, iHammerID, sTargetname, sModelPath, iEntityModelIdx, sClsName, sNetClsName);

		CPrintToChat(client, "{green}[SM]{default} Trace hit something, check your console for more information.");

		LogAction(client, -1, "\"%L\" used Waila. Trace hit something. \nEntity Index: %i\nHammer ID: %d\nTarget name: %s\nModel Path: %s\nModel Index: %i\nClass Name: %s\nNet Class Name: %s", client, iEntity, iHammerID, sTargetname, sModelPath, iEntityModelIdx, sClsName, sNetClsName);

		delete hTraceRay;

		return Plugin_Handled;
	}

	delete hTraceRay;

	CPrintToChat(client, "{green}[SM]{default} Couldn't find anything under your crosshair.");

	return Plugin_Handled;
}

stock bool TraceEntityFilter_FilterCaller(int entity, int contentsMask, int client)
{
	return entity != client;
}

public Action Command_ForceCVar(int client, int argc)
{
	if (argc < 3)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_fcvar <#userid|name> <cvar> <value>");
		return Plugin_Handled;
	}

	char sArg[65];
	char sArg2[65];
	char sArg3[65];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));

	ConVar cvar = FindConVar(sArg2);

	if (cvar == null)
	{
		CReplyToCommand(client, "{green}[SM]{default} No such cvar.");
		return Plugin_Handled;
	}

	if ((iTargetCount = ProcessTargetString(sArg, client, iTargets, MAXPLAYERS, COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		cvar.ReplicateToClient(iTargets[i], sArg3);
	}

	CReplyToCommand(client, "{green}[SM]{default} Force Cvar has been perfomed on {olive}%s {default}({green}%s %s{default}).", sTargetName, sArg2, sArg3);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" forced a cvar on \"%s\". (\"%s\" \"%s\")", client, sTargetName, sArg2, sArg3);
	else
		LogAction(client, iTargets[0], "\"%L\" forced a cvar on \"%L\". (\"%s\" \"%s\")", client, iTargets[0], sArg2, sArg3);

	return Plugin_Handled;
}

public Action Command_SetClanTag(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_setclantag <#userid|name> [text]");
		return Plugin_Handled;
	}

	char sArg[64];
	char sArg2[64];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	if ((iTargetCount = ProcessTargetString(sArg, client, iTargets, MAXPLAYERS, 0, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		CS_SetClientClanTag(iTargets[i], sArg2);
	}

	CReplyToCommand(client, "{green}[SM]{default} Successfully changed clantag of {olive}%s {default}to {green}%s{default}.", sTargetName, sArg2);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" changed clantag of \"%s\". (\"%s\")", client, sTargetName, sArg2);
	else
		LogAction(client, iTargets[0], "\"%L\" changed clantag of \"%L\". (\"%s\")", client, iTargets[0], sArg2);

	return Plugin_Handled;
}

public Action Command_FakeCommand(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_fakecommand <#userid|name> [command] [args]");
		return Plugin_Handled;
	}

	char sArg[64];
	char sArg2[64];
	char sArg3[64];
	char sTargetName[MAX_TARGET_LENGTH];
	int  iTargets[MAXPLAYERS];
	int  iTargetCount;
	bool bIsML;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));
	GetCmdArg(3, sArg3, sizeof(sArg3));

	if ((iTargetCount = ProcessTargetString(sArg, client, iTargets, MAXPLAYERS, COMMAND_FILTER_CONNECTED | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
	{
		ReplyToTargetError(client, iTargetCount);
		return Plugin_Handled;
	}

	bool bCanServerExecute = false;

	for (int i = 0; i < sizeof(g_sServerCanExecuteCmds); i++)
	{
		if (strcmp(g_sServerCanExecuteCmds[i], sArg2) == 0)
		{
			bCanServerExecute = true;
			break;
		}
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		if (bCanServerExecute)
			ClientCommand(iTargets[i], "%s %s", sArg2, sArg3);
		else
			FakeClientCommand(iTargets[i], "%s %s", sArg2, sArg3);
	}

	CReplyToCommand(client, "{green}[SM]{default} Successfully faked command of {olive}%s {default}with {green}%s %s{default}.", sTargetName, sArg2, sArg3);

	if(iTargetCount > 1)
		LogAction(client, -1, "\"%L\" executed a fakecommand on \"%s\". (\"%s\" \"%s\")", client, sTargetName, sArg2, sArg3);
	else
		LogAction(client, iTargets[0], "\"%L\" executed a fakecommand on \"%L\". (\"%s\" \"%s\")", client, iTargets[0], sArg2, sArg3);

	return Plugin_Handled;
}

public Action Command_QueryCVar(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_querycvar <#userid|name> [cvar]");
		return Plugin_Handled;
	}

	char sArg[64];
	char sArg2[64];
	int  iTarget;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	if ((iTarget = FindTarget(client, sArg, true)) <= 0)
		return Plugin_Handled;

	if (QueryClientConVar(iTarget, sArg2, ConVarQueryFinished_QueryCVar, client) == QUERYCOOKIE_FAILED)
		CReplyToCommand(client, "{green}[SM]{default} Failed to query cvar {green}%s{default}.", sArg2);

	LogAction(client, -1, "\"%L\" query the cvar of \"%L\". (\"%s\")", client, iTarget, sArg2);

	return Plugin_Handled;
}

public Action Command_Balance(int client, int args)
{
	Balance(false);
	LogAction(client, -1, "\"%L\" balanced teams", client);
	CShowActivity2(client, "{green}[SM] {olive}", "{default}has balanced the team.");
	return Plugin_Handled;
}

public Action Command_Shuffle(int client, int args)
{
	Balance(false);
	int m = 0, c1 = 0, c2 = 0;
	int pl1[MAX_CLIENTS], pl2[MAX_CLIENTS];
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			switch (GetClientTeam(i))
			{
				case CS_TEAM_T: pl1[c1++] = i;
				case CS_TEAM_CT: pl2[c2++] = i;
			}
	m = c1-- + c2--;
	if (m < 2) return Plugin_Handled;

	if (m % 4) m += 3;
	m /= 4;

	while (m)
	{
		int mi1 = GetRandomInt(0, c1);
		int mi2 = GetRandomInt(0, c2);

		if ((pl1[mi1] != -1) && (pl2[mi2] != -1))
		{
			ChangeClientTeam(pl1[mi1], CS_TEAM_CT);
			ChangeClientTeam(pl2[mi2], CS_TEAM_T);

			pl1[mi1] = pl2[mi2] = -1;
			m--;
		}
	}
	LogAction(client, -1, "\"%L\" shuffled teams", client);
	CShowActivity2(client, "{green}[SM] {olive}", "{default}Shuffled teams.");
	return Plugin_Handled;
}

public Action Command_Location(int client, int args)
{
	float origin[3];
	if (args)
	{
		char pattern[MAX_NAME], buffer[MAX_NAME];
		GetCmdArg(1, pattern, sizeof(pattern));
		int  targets[MAX_CLIENTS];
		bool ml;

		int count;

		if ((count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, buffer, sizeof(buffer), ml)) <= 0)
		{
			ReplyToTargetError(client, count);
			return Plugin_Handled;
		}

		for (int i = 0; i < count; i++)
		{
			int t = targets[i];
			GetEntPropVector(t, Prop_Send, "m_vecOrigin", origin);
			CShowActivity2(client, "{green}[SM] {olive}", "{default}Location of player {olive}%L {default}is {green}%f %f %f", t, origin[0], origin[1], origin[2]);
		}

		LogAction(client, -1, "\"%L\" checked the location of player \"%s\".", client, buffer);
	}
	else if (client)
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		CShowActivity2(client, "{green}[SM] {olive}", "{default}Location of player {olive}%L {default}is {green}%f %f %f", client, origin[0], origin[1], origin[2]);
		LogAction(client, -1, "\"%L\" checked the location of himself. (%f %f %f)", client, origin[0], origin[1], origin[2]);
	}
	else
	{
		ReplyToCommand(client, "[SM] Cannot use this command from server console.");
		return Plugin_Handled;
	}
	return Plugin_Handled;
}

public Action Command_SaveLoc(int client, int args)
{
	if (args > 2)
	{
		char ax[16];
		GetCmdArg(1, ax, sizeof(ax));
		coords[client][0] = StringToFloat(ax);
		GetCmdArg(2, ax, sizeof(ax));
		coords[client][1] = StringToFloat(ax);
		GetCmdArg(3, ax, sizeof(ax));
		coords[client][2] = StringToFloat(ax);
	}
	else if (client)
	{
		float origin[3];
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		coords[client][0] = origin[0];
		coords[client][1] = origin[1];
		coords[client][2] = origin[2];
	}
	else
	{
		ReplyToCommand(client, "[SM] Cannot use this command from server console.");
		return Plugin_Handled;
	}

	CPrintToChat(client, "{green}[SM]{default} Location %f %f %f saved", coords[client][0], coords[client][1], coords[client][2]);

	return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_teleport <target> [x|client] [y] [z]");
		return Plugin_Handled;
	}

	float origin[3];
	if (args > 3)
	{
		char ax[MAX_ID];
		GetCmdArg(2, ax, sizeof(ax));
		origin[0] = StringToFloat(ax);
		GetCmdArg(3, ax, sizeof(ax));
		origin[1] = StringToFloat(ax);
		GetCmdArg(4, ax, sizeof(ax));
		origin[2] = StringToFloat(ax);
	}
	else if (args > 1)
	{
		char cl[MAX_NAME];
		GetCmdArg(2, cl, sizeof(cl));
		int tgt = FindTarget(client, cl);
		if ((tgt != -1) && IsValidEntity(tgt)) GetEntPropVector(tgt, Prop_Send, "m_vecOrigin", origin);
		else
		{
			CReplyToCommand(client, "{green}[SM]{default} Invalid target.");
			return Plugin_Handled;
		}
	}
	else
	{
		origin[0] = coords[client][0];
		origin[1] = coords[client][1];
		origin[2] = coords[client][2];
	}
	char pattern[MAX_NAME], buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	int  targets[MAX_CLIENTS];
	bool ml = false;
	int  count;

	if ((count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, buffer, sizeof(buffer), ml)) <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	for (int i = 0; i < count; i++)
	{
		int t = targets[i];
		TeleportEntity(t, origin, NULL_VECTOR, NULL_VECTOR);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Teleported player {olive}%s {default}to {green}%.1f %.1f %.1f", buffer, origin[0], origin[1], origin[2]);

	if (count > 1)
		LogAction(client, -1, "\"%L\" teleported player \"%s\" to %.1f %.1f %.1f", client, buffer, origin[0], origin[1], origin[2]);
	else
		LogAction(client, targets[0], "\"%L\" teleported player \"%L\" to %.1f %.1f %.1f", client, targets[0], origin[0], origin[1], origin[2]);

	return Plugin_Handled;
}

public Action Command_GetModel(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_getmodel <target>");
		return Plugin_Handled;
	}
	char pattern[MAX_NAME], buffer[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));
	int  targets[MAX_CLIENTS];
	bool ml = false;
	int  count;

	if ((count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, buffer, sizeof(buffer), ml)) <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	for (int i = 0; i < count; i++)
	{
		int t = targets[i];
		GetClientModel(t, buffer, sizeof(buffer));
		CShowActivity2(client, "{green}[SM] {olive}", "{default}Model of player {olive}%L {default}is {green}%s{default}.", t, buffer);
	}

	if(count > 1)
		LogAction(client, -1, "\"%L\" checked the model of \"%s\"", client, pattern);
	else
		LogAction(client, targets[0], "\"%L\" checked the model of \"%L\" (\"%s\")", client, targets[0], buffer);

	return Plugin_Handled;
}

public Action Command_ForceSpec(int client, int args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "{green}[SM]{default} Moves target to spectator mode\nUsage: sm_forcespec <target>");
		return Plugin_Handled;
	}
	char pattern[MAX_NAME], buffer[MAX_NAME];
	GetCmdArg(1, pattern, sizeof(pattern));
	int  targets[MAX_CLIENTS];
	bool ml;
	int  count;

	if ((count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, buffer, sizeof(buffer), ml)) <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	for (int i = 0; i < count; i++)
	{
		int t = targets[i];
		if (IsPlayerAlive(t))
			ForcePlayerSuicide(t);

		ChangeClientTeam(t, CS_TEAM_SPECTATOR);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Moved {olive}%s {default}to Spectators.", buffer);

	if (count > 1)
		LogAction(client, -1, "\"%L\" moved \"%s\" to spectators", client, buffer);
	else
		LogAction(client, targets[0], "\"%L\" moved \"%L\" to spectators", client, targets[0]);

	return Plugin_Handled;
}

public Action Command_TeamSwap(int client, int args)
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			switch (GetClientTeam(i))
			{
				case CS_TEAM_T: ChangeClientTeam(i, CS_TEAM_CT);
				case CS_TEAM_CT: ChangeClientTeam(i, CS_TEAM_T);
			}
	int ts = GetTeamScore(CS_TEAM_T);
	SetTeamScore(CS_TEAM_T, GetTeamScore(CS_TEAM_CT));
	SetTeamScore(CS_TEAM_CT, ts);

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Swapped teams.");
	LogAction(client, -1, "\"%L\" swapped teams", client);
	return Plugin_Handled;
}

public Action Command_NV(int client, int args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_nv <target> <0|1>");
		return Plugin_Handled;
	}
	char pattern[MAX_NAME], buffer[MAX_NAME], nvs[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, nvs, sizeof(nvs));
	int  nv = StringToInt(nvs);
	int  targets[MAX_CLIENTS];
	bool ml = false;
	int  count;

	if ((count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, buffer, sizeof(buffer), ml)) <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	for (int i = 0; i < count; i++)
	{
		int t = targets[i];
		SetEntProp(t, Prop_Send, "m_bHasNightVision", nv ? 1 : 0, 1);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set nightvision of {olive}%s {default}to {green}%d{default}.", buffer, nv);

	if (count > 1)
		LogAction(client, -1, "\"%L\" set nightvision of \"%s\" to %d", client, buffer, nv);
	else
		LogAction(client, targets[0], "\"%L\" set nightvision of \"%L\" to %d", client, targets[0], nv);

	return Plugin_Handled;
}

public Action Command_Defuser(int client, int args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_defuser <target> <0|1>");
		return Plugin_Handled;
	}
	char pattern[MAX_NAME], buffer[MAX_NAME], def[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, def, sizeof(def));
	int  df = StringToInt(def);
	int  targets[MAX_CLIENTS];
	bool ml = false;
	int  count;

	if ((count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, buffer, sizeof(buffer), ml)) <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	for (int i = 0; i < count; i++)
	{
		int t = targets[i];
		if (GetClientTeam(t) == CS_TEAM_CT)
			SetEntProp(t, Prop_Send, "m_bHasDefuser", df ? 1 : 0, 1);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set defuser of {olive}%s {default}to {green}%d{default}.", buffer, df);

	if (count > 1)
		LogAction(client, -1, "\"%L\" set defuser of \"%s\" to %d", client, buffer, df);
	else
		LogAction(client, targets[0], "\"%L\" set defuser of \"%L\" to %d", client, targets[0], df);

	return Plugin_Handled;
}

public Action Command_God(int client, int args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} Usage: sm_god <target> <0|1>");
		return Plugin_Handled;
	}

	char pattern[MAX_NAME], buffer[MAX_NAME], god[MAX_ID];
	GetCmdArg(1, pattern, sizeof(pattern));
	GetCmdArg(2, god, sizeof(god));

	int  gd = StringToInt(god);
	int  targets[MAX_CLIENTS];
	bool ml = false;
	int  count;

	if ((count = ProcessTargetString(pattern, client, targets, sizeof(targets), COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, buffer, sizeof(buffer), ml)) <= 0)
	{
		ReplyToTargetError(client, count);
		return Plugin_Handled;
	}

	for (int i = 0; i < count; i++)
	{
		SetEntProp(targets[i], Prop_Data, "m_takedamage", gd ? 0 : 2, 1);
	}

	CShowActivity2(client, "{green}[SM] {olive}", "{default}Set godmode on {olive}%s {default}to {green}%d{default}.", buffer, gd);

	if (count > 1)
		LogAction(client, -1, "\"%L\" set godmode on \"%s\" to %d", client, buffer, gd);
	else
		LogAction(client, targets[0], "\"%L\" set godmode on \"%L\" to %d", client, targets[0], gd);

	return Plugin_Handled;
}

public Action Command_Uptime(int client, int args)
{
	char UpTime[128];
	int ServerUpTime = RoundToFloor(GetEngineTime());
	
	int Days = ServerUpTime / 60 / 60 / 24;
	int Hours = (ServerUpTime / 60 / 60) % 24;
	int Mins = (ServerUpTime / 60) % 60;
	int Secs = (ServerUpTime) % 60;

	if (!client)
	{
		FormatEx(UpTime, sizeof(UpTime), "%d Days %02d Hours %02d Minutes %02d Seconds", Days, Hours, Mins, Secs);
		ReplyToCommand(client, "[SM] Server uptime: %s", UpTime);
	}
	else
	{
		FormatEx(UpTime, sizeof(UpTime), "{green}%d {default}Days {green}%02d {default}Hours {green}%02d {default}Minutes {green}%02d {default}Seconds.", Days, Hours, Mins, Secs);
		CReplyToCommand(client, "{green}[SM] {default}Server uptime: %s", UpTime);
	}

	return Plugin_Handled;
}

//--------------------------------------
// Functions
//--------------------------------------

int abs(int val)
{
	return (val < 0) ? -val : val;
}

void Balance(bool dead)
{
	int n1 = 0, n2 = 0, nf1 = 0, nf2 = 0, nd1 = 0, nd2 = 0;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			switch (GetClientTeam(i))
			{
				case CS_TEAM_T:
				{
					n1++;
					nf1 += GetClientFrags(i);
					nd1 += GetClientDeaths(i);
				}
				case CS_TEAM_CT:
				{
					n2++;
					nf2 += GetClientFrags(i);
					nd2 += GetClientDeaths(i);
				}
			}
	int st = CS_TEAM_CT, mt = CS_TEAM_T, dn = abs(n1 - n2), df = 0, dd = 0;
	if (n1 > n2)
	{
		st = CS_TEAM_T;
		mt = CS_TEAM_CT;
	}
	while (dn-- > 0)
	{
		df     = abs(nf1 - nf2) / 2;
		dd     = abs(nd1 - nd2) / 2;
		int mi = 0, mf = 2047, md = 2047;
		for (int i = 1; i <= MaxClients; i++)
			if (IsClientInGame(i) && (GetClientTeam(i) == st) && (!dead || (dead && !IsPlayerAlive(i))))
			{
				AdminId admid = GetUserAdmin(i);
				if (admid != INVALID_ADMIN_ID) continue;
				int cdf = abs(GetClientFrags(i) - df);
				int cdd = abs(GetClientDeaths(i) - dd);
				if ((cdf < mf) || ((cdf == mf) && (cdd < md)))
				{
					mi = i;
					mf = cdf;
					md = cdd;
				}
			}
		if (mi && IsClientInGame(mi))
		{
			ChangeClientTeam(mi, mt);
			CPrintToChat(mi, "{green}[SM]{default} You have been moved to balance teams");
		}
	}
}

public void ConVarQueryFinished_QueryCVar(QueryCookie hCookie, int client, ConVarQueryResult res, const char[] sCVarName, const char[] sCVarValue, int admin)
{
	switch (res)
	{
		case ConVarQuery_NotFound:
		{
			CReplyToCommand(admin, "{green}[SM]{default} No such cvar.");
			return;
		}
		case ConVarQuery_NotValid:
		{
			CReplyToCommand(admin, "{green}[SM]{default} Commands can not be queried.");
			return;
		}
		case ConVarQuery_Protected:
		{
			CReplyToCommand(admin, "{green}[SM]{default} That cvar is protected and can not be queried.");
			return;
		}
	}

	CReplyToCommand(admin, "{green}[SM]{default} Value for cvar \"%s\" on client \"%N\" is \"%s\".", sCVarName, client, sCVarValue);
}

stock any clamp(any input, any min, any max)
{
	any retval = input < min ? min : input;

	return retval > max ? max : retval;
}

stock int GivePlayerItemFixed(int client, const char[] item)
{
	static bool bEngineVersionIsCSGO;

	// These weapons 'exist' on csgo, but attempting to give them causes a crash.
	if (bEngineVersionIsCSGO || GetEngineVersion() == Engine_CSGO)
	{
		bEngineVersionIsCSGO = true;

		if (StrEqual(item, "weapon_galil", false) || StrEqual(item, "weapon_m3", false) || StrEqual(item, "weapon_mp5navy", false) || StrEqual(item, "weapon_p228", false) || StrEqual(item, "weapon_scout", false) || StrEqual(item, "weapon_sg550", false) || StrEqual(item, "weapon_sg552", false) || StrEqual(item, "weapon_tmp", false) || StrEqual(item, "weapon_usp", false))
		{
			LogError("Prevented giving ent: %s", item);
			return -1;
		}
	}

	return GivePlayerItem(client, item);
}
