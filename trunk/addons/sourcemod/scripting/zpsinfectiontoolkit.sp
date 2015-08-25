/***********************************************
** Zombie Panic:Source Infection Tool Kit
** 	by DR RAMBONE MURDOCH PHD
**
**  Visit the West Coast Zombie Hideout
*

Adds the following natives for use in your plugins:
	Float:ZIT_InfectPlayerInXSeconds(player, Float:seconds)
	ZIT_DisinfectPlayer(player)
	bool:ZIT_PlayerIsInfected(player)
	Float:ZIT_GetPlayerTurnTime(player)

Provides the following console commands:
	zit_infectplayer <playerid> <time to infection in seconds>
	zit_disinfectplayer <playerid>
	zit_checkup <playerid>
*
***
************
************************************************/

#include <helpers>
#include <zpsinfectiontoolkit>

new g_InfectionTimeOffset = 0;

#define PLUGIN_VERSION "2.0.0"

public Plugin:myinfo = {
	name = "Zombie Panic:Source Infection Toolkit",
	author = "DR RAMBONE MURDOCH PHD",
	description = "Basic infection controls",
	version = PLUGIN_VERSION,
	url = "http://rambonemurdoch.blogspot.com/"
}	

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max) {
	CreateNative("ZIT_InfectPlayerInXSeconds", Native_InfectPlayerInXSeconds);
	CreateNative("ZIT_DisinfectPlayer", Native_DisinfectPlayer);
	CreateNative("ZIT_PlayerIsInfected", Native_PlayerIsInfected);
	CreateNative("ZIT_GetPlayerTurnTime", Native_GetPlayerTurnTime);
	return true;
}

public OnPluginStart() {
	LoadTranslations("common.phrases")
	if(!LoadConfig())
		SetFailState("Couldn't load ZIT config!");
	// zie_infectplayer <playerid> <time to infection in seconds>
	RegAdminCmd(
		"zit_infectplayer", onCmdInfectPlayer, ADMFLAG_SLAY,
		"Infect a player in x seconds"
	);
	// zie_disinfectplayer <playerid>
	RegAdminCmd(
		"zit_disinfectplayer", onCmdDisinfectPlayer, ADMFLAG_SLAY,
		"Disinfect a player"
	);
	RegAdminCmd(
		"zit_checkup", onCmdCheckup, ADMFLAG_SLAY,
		"See if a player is infected, and how long until they turn. Output is to your chat."
	);
	CreateConVar(
		"zit_version", PLUGIN_VERSION,
		"ZP:S Infection Toolkit",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY
	);
}

bool:LoadConfig() {
	// This lets sourcemod distinguish between linux and windows for us
	new Handle:conf;
	conf = LoadGameConfigFile("zpsinfectiontoolkit");
	g_InfectionTimeOffset = GameConfGetOffset(conf, "ZombieTurnTime");
	CloseHandle(conf);
	return -1 != g_InfectionTimeOffset;	
}

/** Console Commands **********************************************/

public Action:onCmdCheckup(client, args) {
	new String:buf[3];
	new ent;
	GetCmdArg(1, buf, sizeof(buf));
	ent = FindTarget(client, buf);
	if(ent == -1)
		return Plugin_Handled;
	if(!(IsClientInGame(ent) && IsPlayerAlive(ent)))
		return Plugin_Handled;
	if(ZIT_PlayerIsInfected(ent)) {
		new Float:countdown = ZIT_GetPlayerTurnTime(ent) - GetGameTime();
		PrintToConsole(client, "Player is infected, turning in %f seconds", countdown);
	} else {
		PrintToConsole(client, "Player is not infected");
	}
	return Plugin_Handled;
}

public Action:onCmdDisinfectPlayer(client, args) {
	new String:buf[3];
	new ent;
	GetCmdArg(1, buf, sizeof(buf));
	ent = FindTarget(client, buf);
	if(ent == -1)
		return Plugin_Handled;
	ZIT_DisinfectPlayer(ent);
	return Plugin_Handled;
}

public Action:onCmdInfectPlayer(client, args) {
	new String:buf[10];
	new ent;
	new Float:seconds;
	GetCmdArg(1, buf, sizeof(buf));
	ent = FindTarget(client, buf);
	if(ent == -1) 
		return Plugin_Handled;
	if(client != 0)
		PrintToChat(client, "Infecting %s", buf);
	if(args == 2) {
		GetCmdArg(2, buf, sizeof(buf));
		seconds = StringToFloat(buf);
	} else {
		if(client != 0)
			PrintToChat(client, "No time set, infection takes hold immediately", buf);
		seconds = 0.0;
	}
	ZIT_InfectPlayerInXSeconds(ent, seconds);
	return Plugin_Handled;
}

/** Natives ********************************************************/

// Player will immediately become infected, turning into a zombie after <seconds> time
public Native_InfectPlayerInXSeconds(Handle:plugin, numParams) {
	new playerEnt = GetNativeCell(1);
	new Float:seconds = Float:GetNativeCell(2)
	if(!(IsClientInGame(playerEnt) && IsPlayerAlive(playerEnt)))
		return _:0.0;

	new Float:turnTime = GetGameTime() + seconds; // time of zombification
	SetEntData(playerEnt, g_InfectionTimeOffset, turnTime)
	SetEntData(
		playerEnt, 
		FindSendPropInfo("CHL2MP_Player","m_IsInfected"), 
		1
	); 
	return _:turnTime;
}

public Native_DisinfectPlayer(Handle:plugin, numParams) {
	new playerEnt = GetNativeCell(1);
	if(!(IsClientInGame(playerEnt) && IsPlayerAlive(playerEnt)))
		return;
	SetEntData(
		playerEnt, 
		FindSendPropInfo("CHL2MP_Player","m_IsInfected"),
		0
	);
}

public Native_PlayerIsInfected(Handle:plugin, numParams) {
	new playerEnt = GetNativeCell(1);
	return _:(
		0 < GetEntData(
			playerEnt, 
			FindSendPropInfo("CHL2MP_Player","m_IsInfected")
		)
	);
}

public Native_GetPlayerTurnTime(Handle:plugin, numParams) { 
	new playerEnt = GetNativeCell(1);
	return _:GetEntDataFloat(playerEnt, g_InfectionTimeOffset);
}

