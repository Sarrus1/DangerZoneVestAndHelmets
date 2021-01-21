#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required
#pragma semicolon 1

#define EF_BONEMERGE                (1 << 0)
#define EF_NOSHADOW                 (1 << 4)
#define EF_NORECEIVESHADOW          (1 << 6)
#define EF_PARENT_ANIMATES          (1 << 9)

float defaultBackPos[3] = {-5.0, 0.0, -18.0};
float defaultBackRot[3] = {0.0, 0.0, 0.0};


int VestIndex[MAXPLAYERS+1] = {-1,...},
	HelmetIndex[MAXPLAYERS+1] = {-1,...};

public Plugin myinfo =
{
	name = "DangerZoneVestAndHelmets",
	author = "Sarrus",
	description = "",
	version = "1.0",
	url = "https://github.com/Sarrus1/"
};

public void OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_death", OnPlayerDeath);

	CustomModelHandling();

	for(int i=1;i<=MAXPLAYERS+1;i++)
	{
		if(IsValidClient(i, true))
			OnClientPutInServer(i);
	}
}


public void OnMapStart()
{
	CustomModelHandling();
}


public void OnClientPutInServer(int client)
{
	return;
}


public Action OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	GiveHelmet(client);
	GiveVest(client);
	return Plugin_Continue;
}


public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("victim"));
	int vest = VestIndex[client];
	int helmet = HelmetIndex[client];

	if(IsValidEntity(vest))
		AcceptEntityInput(vest, "Kill");
	if(IsValidEntity(helmet))
		AcceptEntityInput(helmet, "Kill");
	HelmetIndex[client] = -1;
	VestIndex[client] = -1;

	return Plugin_Continue;
}


public Action Hook_SetTransmit(int entity, int client)
{
	if(!IsValidEntity(entity)||!IsValidClient(client))
		return Plugin_Continue;
	
	int owner = -1;

	if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
		owner = GetEntProp(entity, Prop_Send, "m_hOwnerEntity");

	if(entity == VestIndex[client] || entity == HelmetIndex[client] || (owner!=-1&&!IsPlayerAlive(owner)))
		return Plugin_Handled;

	return Plugin_Continue;
}

stock void GiveHelmet(int client)
{
	int helmet = CreateEntityByName("prop_dynamic_override");
	HelmetIndex[client] = helmet;
	SDKHook(helmet, SDKHook_SetTransmit, Hook_SetTransmit);
	DispatchKeyValue(helmet, "model", "models/props_survival/upgrades/upgrade_dz_helmet.mdl");
	DispatchKeyValue(helmet, "disablereceiveshadows", "1");
	DispatchKeyValue(helmet, "disableshadows", "1");
	DispatchKeyValue(helmet, "spawnflags", "256");
	DispatchKeyValue(helmet, "solid", "0");
	SetEntProp(helmet, Prop_Send, "m_CollisionGroup", 11);
	SetEntPropFloat(helmet, Prop_Data, "m_flModelScale", 0.95);
	SetEntPropEnt(helmet, Prop_Send, "m_hOwnerEntity", client);
	DispatchSpawn(helmet);



	SetVariantString("!activator");
	AcceptEntityInput(helmet, "SetParent", client);

	SetVariantString("facemask");
	AcceptEntityInput(helmet, "SetParentAttachmentMaintainOffset");

	//AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset");

	float Pos[3];
	SetVector(Pos, -5.0, 0.0, -1.0); //SetVector(Pos, In/Out, Up/Down, Left/Right);

	float Ang[3];
	SetVector(Ang, 0.0, 0.0, 0.0);

	TeleportEntity(helmet, Pos, Ang, NULL_VECTOR);

}

stock void SetVector(float target[3], float x, float y, float z)
{
	target[0] = x, target[1] = y, target[2] = z;
}


stock void GiveVest(int client)
{
	char StrName[64]; Format(StrName, sizeof(StrName), "Client%i", client);
	DispatchKeyValue(client, "targetname", StrName);   
		

	int vest = CreateEntityByName("prop_dynamic_override");
	VestIndex[client] = vest;
	SDKHook(vest, SDKHook_SetTransmit, Hook_SetTransmit);
	char StrEntityName[64]; Format(StrEntityName, sizeof(StrEntityName), "prop_dynamic_override_%i", vest); 	

	DispatchKeyValue(vest, "targetname", StrEntityName);
	DispatchKeyValue(vest, "parentname", StrName);	
	DispatchKeyValue(vest, "model", "models/props_survival/upgrades/upgrade_dz_armor.mdl");
	DispatchKeyValue(vest, "disablereceiveshadows", "1");
	DispatchKeyValue(vest, "disableshadows", "1");
	DispatchKeyValue(vest, "solid", "0");
	DispatchKeyValue(vest, "spawnflags", "256");
	SetEntProp(vest, Prop_Send, "m_CollisionGroup", 1);
	SetEntPropFloat(vest, Prop_Data, "m_flModelScale", 1.3);
	SetEntPropEnt(vest, Prop_Send, "m_hOwnerEntity", client);
	DispatchSpawn(vest);
	//SetEntProp(vest, Prop_Send, "m_fEffects", EF_BONEMERGE|EF_NOSHADOW|EF_NORECEIVESHADOW|EF_PARENT_ANIMATES);

	SetEntityMoveType(vest, MOVETYPE_NONE);
	SetVariantString("!activator"); 
	AcceptEntityInput(vest, "SetParent", client, vest, 0);

	SetVariantString("facemask"); 
	AcceptEntityInput(vest, "SetParentAttachmentMaintainOffset");
	SetVestPos(client);
}


stock void CustomModelHandling()
{
	PrecacheModel("models/props_survival/upgrades/upgrade_dz_armor.mdl", true);
	PrecacheModel("models/props_survival/upgrades/upgrade_dz_helmet.mdl", true);
}

stock void SetVestPos(int client_index)
{
float clientPos[3], clientAngles[3];
GetClientAbsOrigin(client_index, clientPos);
GetClientEyeAngles(client_index, clientAngles);
float pos[3], rot[3];

for (int i = 0; i < 3; i++)
{
	pos[i] = defaultBackPos[i];
	rot[i] = defaultBackRot[i];
}
TeleportEntity(VestIndex[client_index], pos, rot, NULL_VECTOR);
}

stock bool IsValidClient(int client, bool nobots = true)
{ 
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client)))
		return false; 
	return IsClientInGame(client); 
} 