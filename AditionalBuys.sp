#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <sdktools>
#include <multicolors>

#define PREFIX "\x04[\x06Armas-Tactico\x04] \x09%t" //Prefix for Messages

#define SHIELD "escudo" //tactical shield
#define HEALTH "inyeccion" //healthshot
#define TAGRENADE "tagrenade" //tactical grenade

public Plugin myinfo =
{
	name = "BuyAditionalThings", //Original name = "BuyShield"
	author = "backwards & Edited by MrCazuela",
	description = "Allows players to buy diferent things drom danger zone, etc.",
	version = "1.4",
	url = "https://forums.alliedmods.net/showthread.php?p=2650816"
}

int i_BuyAmountShield[MAXPLAYERS+1];
int i_BuyAmountHealth[MAXPLAYERS+1];
int i_BuyAmountTagrenade[MAXPLAYERS+1];

ConVar g_ShieldAllowed;
ConVar g_HealthAllowed;
ConVar g_TagrenadeAllowed;

ConVar g_ShieldPrice;
ConVar g_HealthPrice;
ConVar g_TagrenadePrice;

ConVar g_BuyAmountShield;
ConVar g_BuyAmountHealth;
ConVar g_BuyAmountTagrenade;

ConVar g_AllowBuyWarmup;
ConVar g_NeedBuyZone;

Handle BuyStartRoundTimer;

char Colors[][] = 
{
	"{default}", "{darkred}", "{purple}", "{green}", "{lightgreen}", "{lime}", "{red}", "{grey}", "{yellow}", "{gold}", "{blue}", "{orchid}", "{darkblue}", "{lightred}", "{grey2}"
};

char ColorEquivalents[][] =
{
	"\x01", "\x02", "\x03", "\x04", "\x05", "\x06", "\x07", "\x08", "\x09", "\x10", "\x0B", "\x0E", "\x0C", "\x0F", "\x0A"
};

public void OnPluginStart()
{
	LoadTranslations("adbuys_csgo.phrases");

	RegConsoleCmd("sm_shield", CMD_BuyShield);
	RegConsoleCmd("sm_tacticalshield", CMD_BuyShield);

	RegConsoleCmd("sm_healthshot", CMD_BuyHealth);
	RegConsoleCmd("sm_hs", CMD_BuyHealth);

	RegAdminCmd("sm_tagrenade", CMD_BuyTagrenade, ADMFLAG_CUSTOM2);
	RegAdminCmd("sm_tg", CMD_BuyTagrenade, ADMFLAG_CUSTOM2);

    HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_prestart", Event_RoundPreStart);

	g_ShieldAllowed = CreateConVar("at_shield_allowed", "1", "Sets if the tactical shield will be allowed in game", 0, true, 0.0, true, 1.0);
	g_HealthAllowed = CreateConVar("at_health_allowed", "1", "Sets if the health injection will be allowed in game", 0, true, 0.0, true, 1.0);
	g_TagrenadeAllowed = CreateConVar("at_tagrenade_allowed", "1", "Sets if the tactical grenade will be allowed in game", 0, true, 0.0, true, 1.0); 
	g_ShieldPrice = CreateConVar("at_shield_cost", "1000", "Sets the price of tactical shield", 0, true, 1.0, true, 64000.0);
	g_HealthPrice = CreateConVar("at_health_cost", "1500", "Sets the price of health injection", 0, true, 1.0, true, 64000.0);
	g_TagrenadePrice = CreateConVar("at_tagrenade_cost", "2000", "Sets the price of tactical grenade", 0, true, 1.0, true, 64000.0);
	g_BuyAmountShield = CreateConVar("at_amount_shield", "1", "Sets how many times a player can buy a shield", 0, true, 1.0, true, 6.0);
	g_BuyAmountHealth = CreateConVar("at_amount_health", "1", "Sets how many times a player can buy a healthshot", 0, true, 1.0, true, 6.0);
	g_BuyAmountTagrenade = CreateConVar("at_amount_tagrenade", "1", "Sets how many times a player can buy a tagrenade", 0, true, 1.0, true, 6.0);
	g_AllowBuyWarmup = CreateConVar("at_warmup_buy", "0", "Sets if you want to the players can buy in warmup", 0, true, 0.0, true, 1.0);
	g_NeedBuyZone = CreateConVar("at_need_buyzone", "1", "Sets if needed buyzone to buy", 0, true, 0.0, true, 1.0);

	AutoExecConfig(true, "adbuys.csgo");
}

// ----- BUY SHIELD ----- //
public Action CMD_BuyShield(int client, int args)
{
	if(g_ShieldAllowed.IntValue <= 0)
	{
		TPrintToChat(client, PREFIX, "not_allowed");
        return Plugin_Stop;
	}

	int ShieldPrice = g_ShieldPrice.IntValue;

    if(g_AllowBuyWarmup.IntValue <= 0)
    {
	    if(GameRules_GetProp("m_bWarmupPeriod") == 1)
        {
            TPrintToChat(client, PREFIX, "cannot_use_warmup", SHIELD);
			return Plugin_Handled;
        }
	}

    if(GameRules_GetProp("m_bWarmupPeriod") == 0)
    {
	    if(g_NeedBuyZone.IntValue >= 1)
	    {
		    bool InBuyZone = view_as<bool>(GetEntProp(client, Prop_Send, "m_bInBuyZone"));
		    if(!InBuyZone)
		    {
			    TPrintToChat(client, PREFIX, "not_buyzone");
			    return Plugin_Handled;
		    }
		    if (BuyStartRoundTimer == null)
		    {
			    TPrintToChat(client, PREFIX, "not_buytime");
			    return Plugin_Handled;
		    }
		}
	}
	
	int account = GetEntProp(client, Prop_Send, "m_iAccount");
	if(account < ShieldPrice)
	{
		TPrintToChat(client, PREFIX, "not_money", SHIELD, ShieldPrice);
		return Plugin_Handled;
	}

	if(i_BuyAmountShield[client] >= g_BuyAmountShield.IntValue)
	{
        TPrintToChat(client, PREFIX, "amount_reached", SHIELD);
		return Plugin_Handled;
	}
	
	SetEntProp(client, Prop_Send, "m_iAccount", account - g_ShieldPrice.IntValue);
	GivePlayerItem(client, "weapon_shield");
	i_BuyAmountShield[client] += 1;
	TPrintToChat(client, PREFIX, "object_bought", SHIELD, ShieldPrice);
	
	return Plugin_Handled;
}

// ----- BUY HEALTHSHOT ----- //
public Action CMD_BuyHealth(int client, int args) 
{	
    if(g_HealthAllowed.IntValue <= 0)
	{
		TPrintToChat(client, PREFIX, "not_allowed");
        return Plugin_Stop;
	}

	int HealthPrice = g_HealthPrice.IntValue;

	if(g_AllowBuyWarmup.IntValue <= 0)
    {
	    if(GameRules_GetProp("m_bWarmupPeriod") == 1)
        {
            TPrintToChat(client, PREFIX, "cannot_use_warmup", HEALTH);
			return Plugin_Handled;
        }
	}
	
	if(GameRules_GetProp("m_bWarmupPeriod") == 0)
    {
	    if(g_NeedBuyZone.IntValue >= 1)
	    {
		    bool InBuyZone = view_as<bool>(GetEntProp(client, Prop_Send, "m_bInBuyZone"));
		    if(!InBuyZone)
		    {
			    TPrintToChat(client, PREFIX, "not_buyzone");
			    return Plugin_Handled;
		    }
		    if (BuyStartRoundTimer == null)
		    {
			    TPrintToChat(client, PREFIX, "not_buytime");
			    return Plugin_Handled;
		    }
		}
	}

	int account = GetEntProp(client, Prop_Send, "m_iAccount");
	if(account < HealthPrice)
	{
		TPrintToChat(client, PREFIX, "not_money", HEALTH, HealthPrice);
		return Plugin_Handled;
	}
	
	if(i_BuyAmountHealth[client] >= g_BuyAmountHealth.IntValue)
	{
        TPrintToChat(client, PREFIX, "amount_reached", HEALTH);
		return Plugin_Handled;
	}
	
	SetEntProp(client, Prop_Send, "m_iAccount", account - HealthPrice);
	GivePlayerItem(client, "weapon_healthshot");
	i_BuyAmountHealth[client] += 1;
	TPrintToChat(client, PREFIX, "object_bought", HEALTH, HealthPrice);
	
	return Plugin_Handled;
}

// ----- BUY TAGRENADE ----- //
public Action CMD_BuyTagrenade(int client, int args) 
{
    if(g_TagrenadeAllowed.IntValue <= 0)
	{
		TPrintToChat(client, PREFIX, "not_allowed");
        return Plugin_Stop;
	}

	int TagrenadePrice = g_TagrenadePrice.IntValue;

    if(g_AllowBuyWarmup.IntValue <= 0)
    {
	    if(GameRules_GetProp("m_bWarmupPeriod") == 1)
        {
            TPrintToChat(client, PREFIX, "cannot_use_warmup", TAGRENADE);
			return Plugin_Handled;
        }
	}

    if(GameRules_GetProp("m_bWarmupPeriod") == 0)
    {
	    if(g_NeedBuyZone.IntValue >= 1)
	    {
		    bool InBuyZone = view_as<bool>(GetEntProp(client, Prop_Send, "m_bInBuyZone"));
		    if(!InBuyZone)
		    {
			    TPrintToChat(client, PREFIX, "not_buyzone");
			    return Plugin_Handled;
		    }
		    if (BuyStartRoundTimer == null)
		    {
			    TPrintToChat(client, PREFIX, "not_buytime");
			    return Plugin_Handled;
		    }
		}
	}
	
	int account = GetEntProp(client, Prop_Send, "m_iAccount");
	if(account < TagrenadePrice)
	{
		TPrintToChat(client, PREFIX, "not_money", TAGRENADE, TagrenadePrice);
		return Plugin_Handled;
	}
	
	if(i_BuyAmountTagrenade[client] >= g_BuyAmountTagrenade.IntValue)
	{
        TPrintToChat(client, PREFIX, "amount_reached", TAGRENADE);
		return Plugin_Handled;
	}
	
	SetEntProp(client, Prop_Send, "m_iAccount", account - TagrenadePrice);
	GivePlayerItem(client, "weapon_tagrenade");
	i_BuyAmountTagrenade[client] += 1;
	TPrintToChat(client, PREFIX, "object_bought", TAGRENADE, TagrenadePrice);
	
	return Plugin_Handled;
}

// ----- OTHER ----- //
public Action Event_PlayerSpawn(Handle event, char [] name, bool Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

    i_BuyAmountShield[client] = 0;
    i_BuyAmountHealth[client] = 0;
    i_BuyAmountTagrenade[client] = 0;
}

public void Event_RoundPreStart(Handle event, char [] name, bool dontBroadcast)
{
	float BuyTime = 45.0;
	ConVar cvarBuyTime = FindConVar("mp_buytime");
	
	if(cvarBuyTime != null)
		BuyTime = float(cvarBuyTime.IntValue);
		
	if (BuyStartRoundTimer != null)
	{
		KillTimer(BuyStartRoundTimer);
		BuyStartRoundTimer = null;
	}
	
	BuyStartRoundTimer = CreateTimer(BuyTime, StopBuying);
}

public Action StopBuying(Handle timer, any client)
{
	BuyStartRoundTimer = null;
	
	return Plugin_Stop;
}

stock void TPrintToChat(int client, const char[] format, any ...)
{
	SetGlobalTransTarget(client);
	
	char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	for(int i=0;i < sizeof(Colors);i++)
	{
		ReplaceString(buffer, sizeof(buffer), Colors[i], ColorEquivalents[i]);
	}
	
	CPrintToChat(client, buffer);
}