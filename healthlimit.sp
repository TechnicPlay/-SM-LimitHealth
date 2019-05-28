#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new int:actualHealth[MAXPLAYERS + 1];
new int:healthLimit[MAXPLAYERS + 1];

// Functions
public Plugin:myinfo =
{
	name = "HealthLimit",
	author = "TechnicPlay",
	description = "Limits a players health to the specified amount.",
	version = PLUGIN_VERSION,
};

// OnFunctions
public OnPluginStart()
{
	CreateConVar("sm_limithealth_version", PLUGIN_VERSION, "Limit Health Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegAdminCmd("sm_limithealth", Command_LimitHealth, ADMFLAG_SLAY, "sm_limithealth <userid> <amount>");
    
    HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Post)
    HookEvent("player_death", Event_PlayerDied, EventHookMode_Post)
    
    InitHealthLimit();
}

public OnGameFrame()
{
    for(new i = 0; i < MAXPLAYERS + 1; i++)
    {
        if(healthLimit[i] > -1)
        {
            new health = GetEntProp(i, Prop_Send, "m_iHealth") // get current health
            if(health > actualHealth[i]) // compare to inner value
            {
                actualHealth[i] = health; // correct inner value upwards
            }
            if(health > healthLimit[i]) // limit
            {
                actualHealth[i] = healthLimit[i];
            }
            
            if (healthLimit[i] == 0)
                SetEntityHealth(i, 1);
            else
                SetEntityHealth(i, actualHealth[i]);
        }
    } 
}

public OnClientDisconnect(client)
{
    healthLimit[client] = -1;
}

// Events
public Action:Command_LimitHealth(client, args)
{
    decl String:target[10], String:health[10], String:mod[32];
    new targetID;
    new targetCl;
	new nHealth;
    
	if (args < 2) //check args
	{
		ReplyToCommand(client, "[SM] Usage: sm_limithealth <userid> <amount> (-1 to reset)");
		return Plugin_Handled;
	}
	else  //get args
    {
		GetCmdArg(1, target, sizeof(target));
		GetCmdArg(2, health, sizeof(health));
        
        targetID = StringToInt(target);
        targetCl = GetClientOfUserId(targetID)
		nHealth = StringToInt(health);
	}
    
    if(nHealth == -1) //reset limit
    {
        healthLimit[targetCl] = -1;
    }
    else if (nHealth < 0) //send error
    {
		ReplyToCommand(client, "[SM] Health must be greater than zero.");
		return Plugin_Handled;
	}
    
    if(targetCl > 0) //check if client is valid
    {
        healthLimit[targetCl] = nHealth;
        actualHealth[targetCl] = nHealth;
        
        SetEntityHealth(targetCl, nHealth);
    }
    else
    {
        ReplyToCommand(client, "[SM] Client not connected!.");
    }
    
    return Plugin_Handled;
}

public Action:Event_PlayerHurt(Handle:event, const String:Name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new health = GetEventInt(event, "health")
    
    actualHealth[client] = health;
    
    return Plugin_Handled;
}

public Action:Event_PlayerDied(Handle:event, const String:Name[], bool:dontBroadcast )
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    actualHealth[client] = healthLimit[client];
    
    return Plugin_Handled;
}

// private 
InitHealthLimit()
{
    for(new i = 0; i < MAXPLAYERS + 1; i++)
    {
        healthLimit[i] = -1;
    }
}