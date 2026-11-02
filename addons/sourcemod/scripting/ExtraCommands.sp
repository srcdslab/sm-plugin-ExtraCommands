#pragma semicolon 1

#include <cstrike>
#include <sdkhooks>
#include <sdktools>
#include <sourcemod>
#include <multicolors>

#undef REQUIRE_PLUGIN
#tryinclude <zombiereloaded>
#define REQUIRE_PLUGIN

#pragma newdecls required

#define MAX_CLIENTS 129
#define MAX_ID      32
#define MAX_NAME    96
#define MAX_BUFF    512

bool g_bInBuyZoneAll              = false;
bool g_bInBuyZone[MAXPLAYERS + 1] = { false, ... };

bool g_bPreThinkHooked[MAXPLAYERS + 1]      = { false, ... };
bool g_bPostThinkPostHooked[MAXPLAYERS + 1] = { false, ... };

bool g_bInfAmmoHooked           = false;
bool g_bInfAmmoAll              = false;
bool g_bInfAmmo[MAXPLAYERS + 1] = { false, ... };

bool g_bLate = false;
bool g_bBlockRespawn = false;

ConVar g_CVar_sv_pausable;
ConVar g_CVar_sv_bombanywhere;
ConVar g_CVar_sv_cleanonrr;

float coords[MAX_CLIENTS][3];

StringMap g_hServerCanExecuteCmds;
StringMap g_hEntitiesListToKill;

public Plugin myinfo =
{
	name        = "Advanced Commands",
	author      = "BotoX + Obus + maxime1907, .Rushaway",
	description = "Adds extra commands for admins.",
	version     = "2.7.18",
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
	LoadTranslations("ExtraCommands.phrases");

	InitStringMap();

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
	HookEvent("round_end", Event_OnRoundEnd, EventHookMode_PostNoCopy);

	g_CVar_sv_pausable     = FindConVar("sv_pausable");
	g_CVar_sv_bombanywhere = CreateConVar("sv_bombanywhere", "0", "Allows the bomb to be planted anywhere", FCVAR_NOTIFY);
	g_CVar_sv_cleanonrr     = CreateConVar("sm_extracmds_slay_rr", "0", "Slay players before restarting the round [0 = Disabled | 1 = Enabled | 2 = Enabled + Clean temporary entities]", FCVAR_NOTIFY);

	g_CVar_sv_bombanywhere.AddChangeHook(OnConVarChanged_BombAnywhere);

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

public void OnMapStart()
{
	g_bInBuyZoneAll = false;
	g_bInfAmmoAll   = false;
	g_bBlockRespawn = false;

	if (g_bInfAmmoHooked)
	{
		UnhookEvent("weapon_fire", Event_WeaponFire);
		g_bInfAmmoHooked = false;
	}

	for (int i = 1; i <= MaxClients; i++)
	{
		coords[i][0] = 0.0;
		coords[i][1] = 0.0;
		coords[i][2] = 0.0;
	}
}

public void OnMapEnd()
{
	if (g_hServerCanExecuteCmds != null)
		delete g_hServerCanExecuteCmds;

	g_hServerCanExecuteCmds = new StringMap();

	if (g_hEntitiesListToKill != null)
		delete g_hEntitiesListToKill;

	g_hEntitiesListToKill = new StringMap();
}

public Action Listener_Pause(int client, const char[] command, int argc)
{
	static bool bPaused;

	if (!g_CVar_sv_pausable.BoolValue)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Pausable Disabled");
		return Plugin_Handled;
	}

	if (!IsClientAuthorized(client) || !GetAdminFlag(GetUserAdmin(client), Admin_Root))
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Pause No Permission");
		return Plugin_Handled;
	}

	if (strcmp(command, "setpause") == 0)
		bPaused = true;
	else if (strcmp(command, "unpause") == 0)
		bPaused = false;
	else
		bPaused = !bPaused;

	CShowActivity2(client, "{green}[SM] {olive}", "%t", bPaused ? "Game Paused" : "Game Unpaused");
	LogAction(client, -1, "\"%L\" %s the game.", client, bPaused ? "Paused" : "Unpaused");

	return Plugin_Continue;
}

public Action Event_BombPlanted(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			ClientCommand(i, "playgamesound \"radio/bombpl.wav\"");
	}
	return Plugin_Handled;
}

public Action Event_BombDefused(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			ClientCommand(i, "playgamesound \"radio/bombdef.wav\"");
	}
	return Plugin_Handled;
}

public void Event_OnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bBlockRespawn = false;
}

public void OnConVarChanged_BombAnywhere(ConVar convar, const char[] oldValue, const char[] newValue)
{
	UpdateAllThinkHooks();
}

public void OnClientPutInServer(int client)
{
	g_bInBuyZone[client] = false;
	g_bInfAmmo[client]   = false;

	// Fresh player entity, nothing is hooked on it yet
	g_bPreThinkHooked[client]      = false;
	g_bPostThinkPostHooked[client] = false;
	UpdateThinkHooks(client);
}

public void OnClientDisconnect(int client)
{
	g_bInBuyZone[client] = false;
	g_bInfAmmo[client]   = false;

	UpdateThinkHooks(client, true);
}

// The think hooks run every tick for every player, so only keep them
// on the clients for which they actually have something to do.
void UpdateThinkHooks(int client, bool bDisconnecting = false)
{
	bool bPreThink = !bDisconnecting && g_CVar_sv_bombanywhere.IntValue >= 1;
	if (bPreThink != g_bPreThinkHooked[client])
	{
		if (bPreThink)
			SDKHook(client, SDKHook_PreThink, OnPreThink);
		else
			SDKUnhook(client, SDKHook_PreThink, OnPreThink);

		g_bPreThinkHooked[client] = bPreThink;
	}

	bool bPostThinkPost = !bDisconnecting && (g_bInBuyZoneAll || g_bInBuyZone[client]);
	if (bPostThinkPost != g_bPostThinkPostHooked[client])
	{
		if (bPostThinkPost)
			SDKHook(client, SDKHook_PostThinkPost, OnPostThinkPost);
		else
			SDKUnhook(client, SDKHook_PostThinkPost, OnPostThinkPost);

		g_bPostThinkPostHooked[client] = bPostThinkPost;
	}
}

void UpdateAllThinkHooks()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			UpdateThinkHooks(i);
	}
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

public void Event_WeaponFire(Event hEvent, char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
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

				if (strcmp(weaponClassname, "weapon_glock", true) == 0 || strcmp(weaponClassname, "weapon_famas", true) == 0)
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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage HP");
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Health", amount, sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Health", amount, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Armor");
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Armor", amount, sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Armor", amount, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Weapon");
		return Plugin_Handled;
	}

	int ammo = 2500;
	int clip = -1;

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	char sArgs2[65];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	char sWeapon[65];

	if (strncmp(sArgs2, "weapon_", 7) != 0 && strncmp(sArgs2, "item_", 5) != 0 && strcmp(sArgs2, "nvg", false) != 0)
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
			if (strcmp(sWeapon, "weapon_c4", false) == 0 || strcmp(sWeapon, "weapon_smokegrenade", false) == 0 || strcmp(sWeapon, "item_defuser", false) == 0)
			{
				CReplyToCommand(client, "{green}[SM]{default} %t", "Weapon Restricted");
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
			CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Clip");
			return Plugin_Handled;
		}
	}

	if (argc >= 4)
	{
		char sArgs4[20];
		GetCmdArg(4, sArgs4, sizeof(sArgs4));

		if (StringToIntEx(sArgs4, ammo) == 0)
		{
			CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Ammo");
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

	if (strcmp(sWeapon, "nvg", false) == 0)
	{
		for (int i = 0; i < iTargetCount; i++)
			SetEntProp(iTargets[i], Prop_Send, "m_bHasNightVision", 1, 1);
	}
	else if (strcmp(sWeapon, "item_defuser", false) == 0)
	{
		for (int i = 0; i < iTargetCount; i++)
			SetEntProp(iTargets[i], Prop_Send, "m_bHasDefuser", 1);
	}
	else
	{
		for (int i = 0; i < iTargetCount; i++)
		{
			int ent = GivePlayerItem(iTargets[i], sWeapon);

			if (ent == -1)
			{
				CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Weapon");
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

			if (strncmp(sArgs2, "item_", 5) != 0 && strcmp(sWeapon, "weapon_hegrenade", false) != 0)
				EquipPlayerWeapon(iTargets[i], ent);

			if (ammo != -1)
			{
				int PrimaryAmmoType = GetEntProp(ent, Prop_Data, "m_iPrimaryAmmoType");

				if (PrimaryAmmoType != -1)
					SetEntProp(iTargets[i], Prop_Send, "m_iAmmo", ammo, _, PrimaryAmmoType);
			}
		}
	}

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Gave Weapon", sWeapon, sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Gave Weapon", sWeapon, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Strip");
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Stripped Weapons", sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Stripped Weapons", "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage BuyZone");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	int  value = -1;
	char sArgs2[20];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	if (StringToIntEx(sArgs2, value) == 0)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Value");
		return Plugin_Handled;
	}

	char sTargetName[MAX_TARGET_LENGTH];
	bool bIsML;

	if (strcmp(sArgs, "@all", false) == 0)
	{
		sTargetName     = "all players";
		bIsML           = true;
		g_bInBuyZoneAll = value ? true : false;
	}
	else
	{
		int  iTargets[MAXPLAYERS];
		int  iTargetCount;

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

	UpdateAllThinkHooks();

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", (value ? "BuyZone Enabled" : "BuyZone Disabled"), sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", (value ? "BuyZone Enabled" : "BuyZone Disabled"), "_s", sTargetName);
	LogAction(client, -1, "\"%L\" %s permanent buyzone on \"%s\"", client, (value ? "enabled" : "disabled"), sTargetName);

	return Plugin_Handled;
}

public Action Command_InfAmmo(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage InfAmmo");
		return Plugin_Handled;
	}

	char sArgs[65];
	GetCmdArg(1, sArgs, sizeof(sArgs));

	int  value = -1;
	char sArgs2[20];
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	if (StringToIntEx(sArgs2, value) == 0)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Value");
		return Plugin_Handled;
	}

	char sTargetName[MAX_TARGET_LENGTH];
	bool bIsML;

	if (strcmp(sArgs, "@all", false) == 0)
	{
		sTargetName   = "all players";
		bIsML         = true;
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", (value ? "InfAmmo Enabled" : "InfAmmo Disabled"), sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", (value ? "InfAmmo Enabled" : "InfAmmo Disabled"), "_s", sTargetName);
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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Speed");
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Speed", speed, sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Speed", speed, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Respawn");
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

	if (ml)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Respawned", buffer);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Respawned", "_s", buffer);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Team");
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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Value");
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Changed Team", sTargetName, iTeam);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Changed Team", "_s", sTargetName, iTeam);
	LogAction(client, -1, "\"%L\" changed team%s to %d on \"%s\"", client, bAlive ? " ALIVE" : "", iTeam, sTargetName);

	return Plugin_Handled;
}

public Action Command_Cash(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Cash");
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Cash", iCash, sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Cash", iCash, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage ModelScale");
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Model Scale", fScale, sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Model Scale", fScale, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage SetModel");
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
		CReplyToCommand(client, "{green}[SM]{default} %t", "File Not Found", sArgs2);
		return Plugin_Handled;
	}

	if (!IsModelPrecached(sArgs2))
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "File Not Precached", sArgs2);

		PrecacheModel(sArgs2);
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntityModel(iTargets[i], sArgs2);
	}

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Model", sArgs2, sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Model", sArgs2, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage SetScore");
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

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Score", iVal, sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Score", iVal, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage SetDeaths");
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
		if (bIsML)
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Deaths", iVal, sTargetName);
		else
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Deaths", iVal, "_s", sTargetName);
		LogAction(client, -1, "\"%L\" set deaths to \"%d\" on \"%s\"", client, iVal, sTargetName);
	}
	else
	{
		if (bIsML)
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Deaths", iVal, sTargetName);
		else
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Deaths", iVal, "_s", sTargetName);
		LogAction(client, iTargets[0], "\"%L\" set deaths to \"%d\" on \"%L\"", client, iVal, iTargets[0]);
	}

	return Plugin_Handled;
}

public Action Command_SetMvp(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage SetMvp");
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
		if (bIsML)
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set MVP", iVal, sTargetName);
		else
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set MVP", iVal, "_s", sTargetName);
		LogAction(client, -1, "\"%L\" set MVP to \"%d\" on \"%s\"", client, iVal, sTargetName);
	}
	else
	{
		if (bIsML)
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set MVP", iVal, sTargetName);
		else
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set MVP", iVal, "_s", sTargetName);
		LogAction(client, iTargets[0], "\"%L\" set MVP to \"%d\" on \"%L\"", client, iVal, iTargets[0]);
	}

	return Plugin_Handled;
}

public Action Command_SetTeamScore(int client, int argc)
{
	if (argc < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage SetTeamScore");
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

		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Team Score Humans", iVal);
		LogAction(client, -1, "\"%L\" set team-score to \"%d\" for \"Humans\"", client, iVal);
	}
	else if (strcmp(sArgs, "@t", false) == 0 || strcmp(sArgs, "@ts", false) == 0)
	{
		SetTeamScore(CS_TEAM_T, iVal);
		CS_SetTeamScore(CS_TEAM_T, iVal);

		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Team Score Zombies", iVal);
		LogAction(client, -1, "\"%L\" set team-score to \"%d\" for \"Zombies\"", client, iVal);
	}
	else
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Team");
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
		
		// Players are killed with 0.3 delay, so we need to wait at least 0.4 seconds
		if (fDelay < 0.4)
			fDelay = 0.4;
	}

	if (g_CVar_sv_cleanonrr.IntValue > 0)
	{
		if (g_CVar_sv_cleanonrr.IntValue == 2)
		{
			bool dummy;
			char sClassname[64];
			int iMaxEntities = GetMaxEntities();
			for (int entites = 0; entites <= iMaxEntities; entites++)
			{
				if (!IsValidEntity(entites))
					continue;

				GetEntityClassname(entites, sClassname, sizeof(sClassname));

				if (g_hEntitiesListToKill.GetValue(sClassname, dummy))
					AcceptEntityInput(entites, "Kill");
			}
		}

		g_bBlockRespawn = true;
		CreateTimer(0.3, Timer_ForceSuicide, _, TIMER_FLAG_NO_MAPCHANGE);
	}

	CS_TerminateRound(fDelay, CSRoundEnd_Draw, true);

	CShowActivity2(client, "{green}[SM] {olive}", "%t", "Round Restarted", fDelay);
	LogAction(client, -1, "\"%L\" restarted the round (in %0.1f seconds)", client, fDelay);

	return Plugin_Handled;
}

public Action Timer_ForceSuicide(Handle timer)
{
	g_bBlockRespawn = true;
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i))
			ForcePlayerSuicide(i);

	return Plugin_Continue;
}

public Action Command_WAILA(int client, int argc)
{
	if (!client)
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
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
			CPrintToChat(client, "{green}[SM]{default} %t", "Trace Hit World");

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

		CPrintToChat(client, "{green}[SM]{default} %t", "Trace Hit Entity");

		LogAction(client, -1, "\"%L\" used Waila. Trace hit something. \nEntity Index: %i\nHammer ID: %d\nTarget name: %s\nModel Path: %s\nModel Index: %i\nClass Name: %s\nNet Class Name: %s", client, iEntity, iHammerID, sTargetname, sModelPath, iEntityModelIdx, sClsName, sNetClsName);

		delete hTraceRay;

		return Plugin_Handled;
	}

	delete hTraceRay;

	CPrintToChat(client, "{green}[SM]{default} %t", "Trace Hit Nothing");

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage ForceCVar");
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
		CReplyToCommand(client, "{green}[SM]{default} %t", "No Such Cvar");
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

	if (bIsML)
		CReplyToCommand(client, "{green}[SM]{default} %t", "Forced Cvar", sTargetName, sArg2, sArg3);
	else
		CReplyToCommand(client, "{green}[SM]{default} %t", "Forced Cvar", "_s", sTargetName, sArg2, sArg3);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage SetClanTag");
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

	if (bIsML)
		CReplyToCommand(client, "{green}[SM]{default} %t", "Clantag Changed", sTargetName, sArg2);
	else
		CReplyToCommand(client, "{green}[SM]{default} %t", "Clantag Changed", "_s", sTargetName, sArg2);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage FakeCommand");
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
	bool dummy;
	if (g_hServerCanExecuteCmds.GetValue(sArg2, dummy))
	{
		bCanServerExecute = true;
	}

	for (int i = 0; i < iTargetCount; i++)
	{
		if (bCanServerExecute)
			ClientCommand(iTargets[i], "%s %s", sArg2, sArg3);
		else
			FakeClientCommand(iTargets[i], "%s %s", sArg2, sArg3);
	}

	if (bIsML)
		CReplyToCommand(client, "{green}[SM]{default} %t", "Command Faked", sArg2, sArg3, sTargetName);
	else
		CReplyToCommand(client, "{green}[SM]{default} %t", "Command Faked", sArg2, sArg3, "_s", sTargetName);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage QueryCVar");
		return Plugin_Handled;
	}

	char sArg[64];
	char sArg2[64];
	int  iTarget;

	GetCmdArg(1, sArg, sizeof(sArg));
	GetCmdArg(2, sArg2, sizeof(sArg2));

	if ((iTarget = FindTarget(client, sArg, true)) <= 0)
		return Plugin_Handled;

	if (QueryClientConVar(iTarget, sArg2, ConVarQueryFinished_QueryCVar, client ? GetClientUserId(client) : 0) == QUERYCOOKIE_FAILED)
		CReplyToCommand(client, "{green}[SM]{default} %t", "Query Failed", sArg2);

	LogAction(client, -1, "\"%L\" query the cvar of \"%L\". (\"%s\")", client, iTarget, sArg2);

	return Plugin_Handled;
}

public Action Command_Balance(int client, int args)
{
	Balance(false);
	LogAction(client, -1, "\"%L\" balanced teams", client);
	CShowActivity2(client, "{green}[SM] {olive}", "%t", "Teams Balanced");
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
	CShowActivity2(client, "{green}[SM] {olive}", "%t", "Teams Shuffled");
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
			CShowActivity2(client, "{green}[SM] {olive}", "%t", "Player Location", t, origin[0], origin[1], origin[2]);
		}

		LogAction(client, -1, "\"%L\" checked the location of player \"%s\".", client, buffer);
	}
	else if (client)
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", origin);
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Player Location", client, origin[0], origin[1], origin[2]);
		LogAction(client, -1, "\"%L\" checked the location of himself. (%f %f %f)", client, origin[0], origin[1], origin[2]);
	}
	else
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
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
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}

	CReplyToCommand(client, "{green}[SM]{default} %t", "Location Saved", coords[client][0], coords[client][1], coords[client][2]);

	return Plugin_Handled;
}

public Action Command_Teleport(int client, int args)
{
	if (args < 1)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Teleport");
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
			CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Target");
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

	if (ml)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Teleported Player", buffer, origin[0], origin[1], origin[2]);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Teleported Player", "_s", buffer, origin[0], origin[1], origin[2]);

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
		ReplyToCommand(client, "[SM] %t", "Usage GetModel");
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
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Player Model", t, buffer);
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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage ForceSpec");
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

	if (ml)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Moved To Spectators", buffer);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Moved To Spectators", "_s", buffer);

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

	CShowActivity2(client, "{green}[SM] {olive}", "%t", "Teams Swapped");
	LogAction(client, -1, "\"%L\" swapped teams", client);
	return Plugin_Handled;
}

public Action Command_NV(int client, int args)
{
	if (args < 2)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage NV");
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

	if (ml)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Nightvision", buffer, nv);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Nightvision", "_s", buffer, nv);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage Defuser");
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

	if (ml)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Defuser", buffer, df);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", "Set Defuser", "_s", buffer, df);

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
		CReplyToCommand(client, "{green}[SM]{default} %t", "Usage God");
		return Plugin_Handled;
	}

	char sArgs[MAX_NAME], sTargetName[MAX_NAME], sArgs2[MAX_ID];
	GetCmdArg(1, sArgs, sizeof(sArgs));
	GetCmdArg(2, sArgs2, sizeof(sArgs2));

	int  value = -1;
	if (StringToIntEx(sArgs2, value) == 0)
	{
		CReplyToCommand(client, "{green}[SM]{default} %t", "Invalid Value");
		return Plugin_Handled;
	}

	int  gd = StringToInt(sArgs2);
	int  iTargets[MAX_CLIENTS];
	bool bIsML = false;
	int  iTargetCount;

	if ((iTargetCount = ProcessTargetString(sArgs, client, iTargets, MAXPLAYERS, COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_IMMUNITY, sTargetName, sizeof(sTargetName), bIsML)) <= 0)
		{
			ReplyToTargetError(client, iTargetCount);
			return Plugin_Handled;
		}

	for (int i = 0; i < iTargetCount; i++)
	{
		SetEntProp(iTargets[i], Prop_Data, "m_takedamage", gd ? 0 : 2, 1);
	}

	if (bIsML)
		CShowActivity2(client, "{green}[SM] {olive}", "%t", (value ? "God Enabled" : "God Disabled"), sTargetName);
	else
		CShowActivity2(client, "{green}[SM] {olive}", "%t", (value ? "God Enabled" : "God Disabled"), "_s", sTargetName);
	LogAction(client, -1, "\"%L\" %s godmode on \"%s\"", client, (value ? "enabled" : "disabled"), sTargetName);

	return Plugin_Handled;
}

public Action Command_Uptime(int client, int args)
{
	char UpTime[256];
	int ServerUpTime = RoundToFloor(GetEngineTime());
	
	int Days = ServerUpTime / 60 / 60 / 24;
	int Hours = (ServerUpTime / 60 / 60) % 24;
	int Mins = (ServerUpTime / 60) % 60;
	int Secs = (ServerUpTime) % 60;

	if (!client)
	{
		FormatEx(UpTime, sizeof(UpTime), "%T", "Uptime Value Plain", LANG_SERVER, Days, Hours, Mins, Secs);
		ReplyToCommand(client, "[SM] %t", "Server Uptime", UpTime);
	}
	else
	{
		FormatEx(UpTime, sizeof(UpTime), "%T", "Uptime Value", client, Days, Hours, Mins, Secs);
		CReplyToCommand(client, "{green}[SM] {default}%t", "Server Uptime", UpTime);
	}

	return Plugin_Handled;
}

//--------------------------------------
// Functions
//--------------------------------------

stock void InitStringMap()
{
	char sServerCanExecuteCmds[][] = { "cl_soundscape_flush", "r_screenoverlay", "playgamesound",
											"slot0", "slot1", "slot2", "slot3", "slot4", "slot5", "slot6",
											"slot7", "slot8", "slot9", "slot10", "cl_spec_mode", "cancelselect",
											"invnext", "play", "invprev", "sndplaydelay", "lastinv", "dsp_player",
											"name", "redirect", "retry", "r_cleardecals", "echo", "soundfade" };

	if (g_hServerCanExecuteCmds == null)
		g_hServerCanExecuteCmds = new StringMap();

	for (int i = 0; i < sizeof(sServerCanExecuteCmds); i++)
	{
		g_hServerCanExecuteCmds.SetValue(sServerCanExecuteCmds[i], true);
	}

	char sSafeEntitiesToKill[][] = {
		"env_beam", "env_entity_maker", "env_explosion", "env_fade", "env_shake", "env_spark", "env_sprite",
		"func_breakable", "func_button", "func_door", "func_door_rotating", "func_movelinear", "func_physbox", "func_physbox_multiplayer", "func_reflective_glass", "func_rotating",
		"game_text",
		"info_particle_system", "info_teleport_destination",
		"phys_keepupright", "phys_thruster",
		"point_hurt", "point_spotlight", "point_teleport",
		"prop_dynamic", "prop_dynamic_override", "prop_physics", "prop_physics_multiplayer", "prop_physics_override",
		"trigger_hurt", "trigger_multiple", "trigger_once", "trigger_push", "trigger_teleport",
		"weapon_glock", "weapon_usp", "weapon_deagle", "weapon_elite", "weapon_p228", "weapon_fiveseven",
		"weapon_m3", "weapon_xm1014",
		"weapon_mac10", "weapon_tmp", "weapon_mp5navy", "weapon_ump45", "weapon_p90",
		"weapon_galil", "weapon_famas", "weapon_ak47", "weapon_m4a1", "weapon_sg552", "weapon_aug",
		"weapon_scout", "weapon_sg550", "weapon_g3sg1", "weapon_awp",
		"weapon_m249", "weapon_knife", "weapon_c4", 
		"weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade", "item_nvgs", "item_kevlar"
	};

	if (g_hEntitiesListToKill == null)
		g_hEntitiesListToKill = new StringMap();

	for (int i = 0; i < sizeof(sSafeEntitiesToKill); i++)
	{
		g_hEntitiesListToKill.SetValue(sSafeEntitiesToKill[i], true);
	}
}

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
			CPrintToChat(mi, "{green}[SM]{default} %t", "Moved To Balance");
		}
	}
}

public void ConVarQueryFinished_QueryCVar(QueryCookie hCookie, int client, ConVarQueryResult res, const char[] sCVarName, const char[] sCVarValue, int userid)
{
	int admin = GetClientOfUserId(userid);
	if (userid && !admin)
		return;

	switch (res)
	{
		case ConVarQuery_NotFound:
		{
			if (admin)
				CPrintToChat(admin, "{green}[SM]{default} %t", "No Such Cvar");
			else
				CPrintToServer("{green}[SM]{default} %t", "No Such Cvar");
			return;
		}
		case ConVarQuery_NotValid:
		{
			if (admin)
				CPrintToChat(admin, "{green}[SM]{default} %t", "Query Not Valid");
			else
				CPrintToServer("{green}[SM]{default} %t", "Query Not Valid");
			return;
		}
		case ConVarQuery_Protected:
		{
			if (admin)
				CPrintToChat(admin, "{green}[SM]{default} %t", "Query Protected");
			else
				CPrintToServer("{green}[SM]{default} %t", "Query Protected");
			return;
		}
	}

	if (admin)
		CPrintToChat(admin, "{green}[SM]{default} %t", "Query Result", sCVarName, client, sCVarValue);
	else
		CPrintToServer("{green}[SM]{default} %t", "Query Result", sCVarName, client, sCVarValue);
}

stock any clamp(any input, any min, any max)
{
	any retval = input < min ? min : input;

	return retval > max ? max : retval;
}

#if defined _zr_included
public Action ZR_OnClientRespawn(int &client, ZR_RespawnCondition& condition)
{
	if(g_bBlockRespawn)
		return Plugin_Handled;

	return Plugin_Continue;
}
#endif
