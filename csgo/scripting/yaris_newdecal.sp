#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "ali<.d"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <warden>
#include <multicolors>
#include <emitsoundany>

#pragma newdecls required

ConVar g_tag1;
char tag1[999];

bool Yapti[MAXPLAYERS + 1],
	olsunler,
	ses,
	bunnyh,
	yarisoyunu = false,
	bCountdownUsed = false,
	bIsRace = false;
	
int ilkkac,
	kacinci = 1,
	countdown = 5,
	g_totalwinrace[MAXPLAYERS + 1];

Handle g_CountdownTimer = INVALID_HANDLE,
	g_RaceTimer = INVALID_HANDLE,
	g_drawTimer = INVALID_HANDLE;

float LR_Prisoner_Position[MAXPLAYERS + 1][3];

int BeamSprite = -1,
	HaloSprite = -1,
	LaserSprite = -1,
	LaserHalo = -1,
	redColor[] = {255, 0, 0, 255},
	greenColor[] = {0, 255, 0, 255};

float startloc[3],
	finishloc[3];

/////////////////////////////////////////////

int koyulan_markerlar;
float ikinciloc[3];
bool i_marker[MAXPLAYERS + 1];
float ucunculoc[3];
bool u_marker[MAXPLAYERS + 1];
float dordunculoc[3];
bool d_marker[MAXPLAYERS + 1];

////////////////////////////////////////////SQL
Handle g_hDB = INVALID_HANDLE;
char g_sSQLBuffer[3096];
bool g_bIsMySQl;
bool g_bChecked[MAXPLAYERS + 1];
Handle gF_OnInsertNewPlayer;

//////////////////////////
void Sifirla()
{
	yarisoyunu = false;
	ses = false;
	if (bunnyh)
	{
		ServerCommand("sm_cvar sv_enablebunnyhopping 1;sm_cvar abner_bhop 1;sm_cvar sv_airaccelerate 2000");
		bunnyh = false;
	}
	koyulan_markerlar = 0;
	startloc[0] = 0.0, startloc[1] = 0.0, startloc[2] = 0.0;
	finishloc[0] = 0.0, finishloc[1] = 0.0, finishloc[2] = 0.0;
	ikinciloc[0] = 0.0, ikinciloc[1] = 0.0, ikinciloc[2] = 0.0;
	ucunculoc[0] = 0.0, ucunculoc[1] = 0.0, ucunculoc[2] = 0.0;
	dordunculoc[0] = 0.0, dordunculoc[1] = 0.0, dordunculoc[2] = 0.0;
	kacinci = 1;
	CloseHandle(g_CountdownTimer);
	CloseHandle(g_RaceTimer);
	CloseHandle(g_drawTimer);
	g_drawTimer = INVALID_HANDLE;
	g_CountdownTimer = INVALID_HANDLE;
	g_RaceTimer = INVALID_HANDLE;
	bCountdownUsed = false;
	bIsRace = false;
	int i = 1;
	while (i <= MaxClients)
	{
		if (IsClientInGame(i))
		{
			Yapti[i] = false;
			i_marker[i] = false;
			u_marker[i] = false;
			d_marker[i] = false;
			LR_Prisoner_Position[i][0] = 0.0;
			LR_Prisoner_Position[i][1] = 0.0;
			LR_Prisoner_Position[i][2] = 0.0;
			SetEntityRenderColor(i, 255, 255, 255);
			SetEntityMoveType(i, MOVETYPE_WALK);
		}
		i++;
	}
}
///////////////////////////////
public Plugin myinfo = 
{
	name = "Yarış Yapak mı ?",
	author = PLUGIN_AUTHOR,
	description = "Fazla umuttur her şeyi mahveden.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/alikoc77"
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_yaris", command_race);
	RegConsoleCmd("sm_yarisiptal", command_cancelrace);
	RegConsoleCmd("sm_topyaris", command_topyaris);
	RegAdminCmd("sm_topyarisreset", Command_Sifirlayalimbakalim, ADMFLAG_ROOT);
	g_tag1 = CreateConVar("tag_yaris", "SM", "Pluginleri başında olmasını istediğiniz tag", FCVAR_NOTIFY);
	HookEvent("round_end", end);
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
	  	  SDKHook(i, SDKHook_SetTransmit, Hook_SetTransmit);
		}
	}
	AutoExecConfig(true, "Yaris", "alispw77");
	SQL_TConnect(OnSQLConnect, "Yaris");
}

public void OnPluginEnd()
{
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientDisconnect(client);
		}
	}
}

public void OnMapStart()
{
	Sifirla();
	GetConVarString(g_tag1, tag1, sizeof(tag1));
	BeamSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	HaloSprite = PrecacheModel("materials/sprites/glow01.vmt");
	LaserSprite = PrecacheModel("materials/sprites/laserbeam.vmt");
	LaserHalo = PrecacheModel("materials/sprites/light_glow01.vmt");
	if (g_CountdownTimer != INVALID_HANDLE)
	{
		g_CountdownTimer = INVALID_HANDLE;
	}
	char Dosya_Konumu[1000];
	Format(Dosya_Konumu, 999, "sound/alispw77/son5saniye.mp3");
	AddFileToDownloadsTable(Dosya_Konumu);	
	PrecacheSoundAny("aliswp77/son5saniye.mp3");
}

public void OnClientPostAdminCheck(int client)
{
	if(!IsFakeClient(client)) CheckSQLSteamID(client);
}

public void OnClientDisconnect(int client)
{
	if(!IsFakeClient(client) && g_bChecked[client]) SaveSQLCookies(client);
}

public Action command_topyaris(int client, int args)
{
	ShowTotal(client);
}

public Action command_cancelrace(int client, int args)
{
	if (warden_iswarden(client) || CheckCommandAccess(client, "mycommand", ADMFLAG_ROOT))
	{
		if (yarisoyunu == true)
		{
			CPrintToChatAll("[%s] {orange}Yarış Oyunu İptal Edildi", tag1);
			PrintCenterText(client, "Yarış Oyunu İptal Edildi");			
			Sifirla();
		}
		else
		{
			Sifirla();
		}
	}
	else
	{
		CPrintToChat(client, "[%s] {orange}Bu komutu sadece komutçu kullanabilir.",tag1);
	}
}

public Action command_race(int client, int args)
{
	if (warden_iswarden(client) || CheckCommandAccess(client, "mycommand", ADMFLAG_ROOT))
	{
		if (yarisoyunu == false)
		{
			Sifirla();
			Handle racemenu1 = CreateMenu(RaceStartPointHandler);
			SetMenuTitle(racemenu1, "Başlangıç Konumu Ayarlayın");
			char sMenuText[128];
			Format(sMenuText, sizeof(sMenuText), "Mevcut Konumu Ayarla");
			AddMenuItem(racemenu1, "startloc", sMenuText);
			SetMenuExitButton(racemenu1, true);
			DisplayMenu(racemenu1, client, MENU_TIME_FOREVER);						
			for (int idx = 1; idx <= MaxClients; idx++)
			{
				if (IsClientInGame(idx) && IsPlayerAlive(idx))
				{
					CPrintToChat(idx, "[%s] {orange}Yarış Yakında Başlayacak", tag1);
				}
			}
		}
		else
		{
			CPrintToChat(client, "[%s] {orange}Zaten bir yarış aktif lütfen önce kapatınız [ !yarisiptal ]", tag1);
		}
	}
	else
	{
		CPrintToChat(client, "[%s] {orange}Bu komutu sadece komutçu kullanabilir.",tag1);
	}
}

public int RaceStartPointHandler(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		if (IsPlayerAlive(client) && warden_iswarden(client) || CheckCommandAccess(client, "mycommand", ADMFLAG_ROOT))
		{
			if (GetEntityFlags(client) & FL_ONGROUND)
			{
				float f_StartPoint[3];
				GetClientAbsOrigin(client, f_StartPoint);
				f_StartPoint[2] += 10;
				
				startloc[0] = f_StartPoint[0];
				startloc[1] = f_StartPoint[1];
				startloc[2] = f_StartPoint[2];
				koyulan_markerlar++;
				g_drawTimer = CreateTimer(1.0, Timer_draw, _, TIMER_REPEAT);
				CreateRaceExtraPointMenu(client);
			}
			else
			{
				CPrintToChat(client, "[%s] {orange}Hareket etmeden sabit durunuz.", tag1);
				CreateRaceExtraPointMenu(client);
			}
		}
		else
		{
			CPrintToChat(client, "[%s] {orange}Bu komutu sadece komutçu kullanabilir.", tag1);
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void CreateRaceExtraPointMenu(int client)
{
	Handle EndPointMenu = CreateMenu(RaceExtraPointHandler);
	SetMenuTitle(EndPointMenu, "Extra Yarış Noktasını Ayarla");
	char sMenuText[64];
	if (koyulan_markerlar < 4)
	{
		Format(sMenuText, sizeof(sMenuText), "Extra Nokta-Mevcut Konumu Ayarla");
		AddMenuItem(EndPointMenu, "extrapoint", sMenuText);
	}
	Format(sMenuText, sizeof(sMenuText), "Bitiş Noktası-Mevcut Konumu Ayarla");
	AddMenuItem(EndPointMenu, "endpoint", sMenuText);	
	SetMenuExitButton(EndPointMenu, true);
	DisplayMenu(EndPointMenu, client, MENU_TIME_FOREVER);
}

public int RaceExtraPointHandler(Handle menu, MenuAction action, int client, int param2)
{
	char info[64];
	if (action == MenuAction_Select)
	{
		GetMenuItem(menu, param2, info, 64);
		if (StrEqual(info, "extrapoint", false))
		{
			if (IsPlayerAlive(client) && warden_iswarden(client) || CheckCommandAccess(client, "mycommand", ADMFLAG_ROOT))
			{
				if (GetEntityFlags(client) & FL_ONGROUND)
				{
					float f_ExtLocation[3];
					GetClientAbsOrigin(client, f_ExtLocation);
					f_ExtLocation[2] += 10;
					float f_StartLocation[3];
					if (koyulan_markerlar == 1)
					{
						ikinciloc[0] = f_ExtLocation[0];
						ikinciloc[1] = f_ExtLocation[1];
						ikinciloc[2] = f_ExtLocation[2];
						f_StartLocation[0] = startloc[0];
						f_StartLocation[1] = startloc[1];
						f_StartLocation[2] = startloc[2];
					}
					else if (koyulan_markerlar == 2)
					{
						ucunculoc[0] = f_ExtLocation[0];
						ucunculoc[1] = f_ExtLocation[1];
						ucunculoc[2] = f_ExtLocation[2];
						f_StartLocation[0] = ikinciloc[0];
						f_StartLocation[1] = ikinciloc[1];
						f_StartLocation[2] = ikinciloc[2];
					}
					else if (koyulan_markerlar == 3)
					{
						dordunculoc[0] = f_ExtLocation[0];
						dordunculoc[1] = f_ExtLocation[1];
						dordunculoc[2] = f_ExtLocation[2];
						f_StartLocation[0] = ucunculoc[0];
						f_StartLocation[1] = ucunculoc[1];
						f_StartLocation[2] = ucunculoc[2];
					}					
					float distanceBetweenPoints = GetVectorDistance(f_StartLocation, f_ExtLocation, false);
					
					if (distanceBetweenPoints > 150.0)
					{
						koyulan_markerlar++;
						CPrintToChat(client, "[%s] {orange}%i. Marker Kaydedildi.", tag1, koyulan_markerlar);
						CreateRaceExtraPointMenu(client);
					}
					else
					{
						CPrintToChat(client, "[%s] {orange} Koyulan iki nokta birbirine çok yakın", tag1);
						CreateRaceExtraPointMenu(client);
					}
				}
				else
				{
					CPrintToChat(client, "[%s] {orange}Hareket etmeden sabit durunuz.", tag1);
					CreateRaceExtraPointMenu(client);
				}
			}
			else
			{
				CPrintToChat(client, "[%s] {orange}Bu komutu sadece komutçu kullanabilir.", tag1);
			}			
		}
		else if (StrEqual(info, "endpoint", false))
		{
			if (IsPlayerAlive(client) && warden_iswarden(client) || CheckCommandAccess(client, "mycommand", ADMFLAG_ROOT))
			{
				if (GetEntityFlags(client) & FL_ONGROUND)
				{
					float f_EndLocation[3];
					GetClientAbsOrigin(client, f_EndLocation);
					f_EndLocation[2] += 10;
					float f_StartLocation[3];
					finishloc[0] = f_EndLocation[0];
					finishloc[1] = f_EndLocation[1];
					finishloc[2] = f_EndLocation[2];				
					if (koyulan_markerlar == 1)
					{
						f_StartLocation[0] = startloc[0];
						f_StartLocation[1] = startloc[1];
						f_StartLocation[2] = startloc[2];
					}
					else if (koyulan_markerlar == 2)
					{
						f_StartLocation[0] = ikinciloc[0];
						f_StartLocation[1] = ikinciloc[1];
						f_StartLocation[2] = ikinciloc[2];
					}
					else if (koyulan_markerlar == 3)
					{
						f_StartLocation[0] = ucunculoc[0];
						f_StartLocation[1] = ucunculoc[1];
						f_StartLocation[2] = ucunculoc[2];
					}
					else if (koyulan_markerlar == 4)
					{
						f_StartLocation[0] = dordunculoc[0];
						f_StartLocation[1] = dordunculoc[1];
						f_StartLocation[2] = dordunculoc[2];
					}				
					float distanceBetweenPoints = GetVectorDistance(f_StartLocation, f_EndLocation, false);
					
					if (distanceBetweenPoints > 200.0)
					{
						Kac_kisi_bitircek(client);
					}
					else
					{
						CPrintToChat(client, "[%s] {orange}Bitiş noktası diğer noktalara çok yakın", tag1);
						CreateRaceExtraPointMenu(client);
					}
				}
				else
				{
					CPrintToChat(client, "[%s] {orange}Hareket etmeden sabit durunuz.", tag1);
					CreateRaceExtraPointMenu(client);
				}
			}
			else
			{
				CPrintToChat(client, "[%s] {orange}Bu komutu sadece komutçu kullanabilir.", tag1);
			}
		}
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}	
}

void Kac_kisi_bitircek(int client)
{
	int yasayant;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
			yasayant++;
	}
	Handle menu = CreateMenu(menu_kackisi);
	SetMenuTitle(menu, "Yarışı İlk Kaç Bitirecek?");
	if (yasayant > 0)
		AddMenuItem(menu, "1", "İlk 1");
	if (yasayant > 1)
		AddMenuItem(menu, "2", "İlk 2");
	if (yasayant > 2)
		AddMenuItem(menu, "3", "İlk 3");
	if (yasayant > 4)
		AddMenuItem(menu, "5", "İlk 5");
	if (yasayant > 9)
		AddMenuItem(menu, "10", "İlk 10");
		
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

public int menu_kackisi(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		ilkkac = StringToInt(info);
		CPrintToChatAll("[%s] {orange}Yarışı İlk {green}%s {orange}bitirecek şekilde ayarlandı.", tag1, info);
		oleceklermi(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}	
}

void oleceklermi(int client)
{
	Handle menu = CreateMenu(menu_olecekmi);
	SetMenuTitle(menu, "Yapamayanlar?");
	AddMenuItem(menu, "1", "Ölsün");
	AddMenuItem(menu, "0", "Ölmesin");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);	
}

public int menu_olecekmi(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info, "1"))
		{
			olsunler = true;
			CPrintToChatAll("[%s] {orange}Yarışı bitiremeyenler {darkred}Ölsün {orange}olarak ayarlandı.", tag1);
		}
		else if (StrEqual(info, "0"))
		{
			olsunler = false;
			CPrintToChatAll("[%s] {orange}Yarışı bitiremeyenler {darkred}Ölmesin {orange}olarak ayarlandı.", tag1);
		}
		bunnyvarmi1(client);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
		if (param2 == MenuCancel_ExitBack)
	{
		Kac_kisi_bitircek(client);
	}	
}

void bunnyvarmi1(int client)
{
	Handle menu = CreateMenu(menu_bunny);
	SetMenuTitle(menu, "Bunny Hop?");
	AddMenuItem(menu, "0", "Kapalı");
	AddMenuItem(menu, "1", "Açık");
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public int menu_bunny(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_Select)
	{
		char info[32];
		GetMenuItem(menu, param2, info, sizeof(info));
		if (StrEqual(info, "1"))
		{
			bunnyh = false;
			ServerCommand("sm_cvar sv_enablebunnyhopping 1;sm_cvar abner_bhop 1;sm_cvar sv_airaccelerate 2000");
			CPrintToChatAll("[%s] {orange}Bunny Hop {darkred}Açık {orange}olarak ayarlandı.", tag1);
		}
		else if (StrEqual(info, "0"))
		{
			bunnyh = true;
			ServerCommand("sm_cvar sv_enablebunnyhopping 0;sm_cvar abner_bhop 0;sm_cvar sv_airaccelerate 2000");
			CPrintToChatAll("[%s] {orange}Bunny Hop {darkred}Kapalı {orange}olarak ayarlandı.", tag1);
		}		
		yarisoyunu = true;
		InitializeGame();
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
		if (param2 == MenuCancel_ExitBack)
	{
		oleceklermi(client);
	}	
}

void InitializeGame()
{
	float f_StartLocation[3];
	f_StartLocation[0] = startloc[0];
	f_StartLocation[1] = startloc[1];
	f_StartLocation[2] = startloc[2];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			StripAllWeapons(i);
			SetEntityMoveType(i, MOVETYPE_NONE);
			SetEntityRenderColor(i, 255, 0, 0);			
			TeleportEntity(i, f_StartLocation, NULL_VECTOR, NULL_VECTOR);
		}
	}
	
	if (g_CountdownTimer == INVALID_HANDLE)
	{
		countdown = 5;
		bIsRace = true;
		g_CountdownTimer = CreateTimer(1.0, Timer_Countdown_, _, TIMER_REPEAT);
		bilgilendirme();
	}
}

void bilgilendirme()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == 2)
		{		
			Handle hHudText = CreateHudSynchronizer();
			SetHudTextParams(-1.0, -0.60, 3.0, 255, 0, 0, 0, 2, 1.0, 0.1, 0.2);	
			ShowSyncHudText(i, hHudText, "Yarış Oyunu Başlamak Üzere\nGösterilen Yolu En Önce Bitirerek\nYarışı Kazanmalısın");
			CloseHandle(hHudText);
		}
	}
}

public Action Timer_draw(Handle timer)
{
	DrawMarkers();
}
public Action Timer_Countdown_(Handle timer)
{
	float LR_Prisoner_Positioncd[3];
	if (koyulan_markerlar == 1)
	{
		TE_SetupBeamPoints(startloc, finishloc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
	}
	else if (koyulan_markerlar == 2)
	{
		TE_SetupBeamPoints(startloc, ikinciloc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(ikinciloc, finishloc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
	}
	else if (koyulan_markerlar == 3)
	{
		TE_SetupBeamPoints(startloc, ikinciloc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(ikinciloc, ucunculoc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(ucunculoc, finishloc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
	}
	else if (koyulan_markerlar == 4)
	{	
		TE_SetupBeamPoints(startloc, ikinciloc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(ikinciloc, ucunculoc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(ucunculoc, dordunculoc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
		TE_SetupBeamPoints(dordunculoc, finishloc, LaserSprite, LaserHalo, 1, 1, 1.1, 1.0, 1.5, 0, 10.0, redColor, 200);
		TE_SendToAll(0.0);
	}	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (countdown > 0 && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			bCountdownUsed = true;
			GetClientAbsOrigin(i, LR_Prisoner_Positioncd);			
		}
		if (countdown <= 0 && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			if (IsPlayerAlive(i) && IsClientInGame(i) && GetClientTeam(i) == 2)
			{
				countdown = 0;
				bCountdownUsed = false;
			}
			if(bCountdownUsed == false && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
			{
				CPrintToChatAll("[%s] {orange}Yarış Başladı.", tag1);
				PrintCenterTextAll("> Yarış Başladı <");
				SetEntityMoveType(i, MOVETYPE_WALK);
				if (g_RaceTimer == INVALID_HANDLE)
				{
					g_RaceTimer = CreateTimer(0.1, Timer_Race, _, TIMER_REPEAT);
				}
				g_CountdownTimer = INVALID_HANDLE;
				CloseHandle(g_CountdownTimer);
				return Plugin_Stop;
			}			
		}	
	}
	if (countdown >= 0)
	{
		if (!ses)
		{
			ses = true;
			char Ses_Dosyasi[1000];
			Format(Ses_Dosyasi, 999, "leaderclan/son5saniye.mp3");
			EmitSoundToAllAny(Ses_Dosyasi, -2, 0, 75, 0, 1.0, 100, -1, NULL_VECTOR, NULL_VECTOR, true, 0.0);		
		}
		CPrintToChatAll("[%s] {orange}Yarışın Başlamasına Son {darkred}%i", tag1, countdown);
		PrintCenterTextAll("Yarışın Başlamasına Son %i...", countdown);
					
	}
	countdown--;
	return Plugin_Continue;
}

public Action Timer_Race(Handle timer)
{
	if (bIsRace == false)
	{
		if(olsunler)
		{
			for (int idx = 1; idx <= MaxClients; idx++)
			{		
				if (IsClientInGame(idx) && IsPlayerAlive(idx) && GetClientTeam(idx) == 2 && Yapti[idx] == false)
				{
					ForcePlayerSuicide(idx);
				}
			}
			CPrintToChatAll("[%s]{orange} Yapamayanlar Öldürüldü", tag1);
		}
		CPrintToChatAll("[%s] {orange}Yarış Bitti...", tag1);
		CloseHandle(g_RaceTimer);
		g_RaceTimer = INVALID_HANDLE;
		Sifirla();
		return Plugin_Stop;
	}	
	for (int idx = 1; idx <= MaxClients; idx++)
	{
		if (IsClientInGame(idx) && IsPlayerAlive(idx) && GetClientTeam(idx) == 2)
		{
			float f_EndLocation[3];
			f_EndLocation[0] = finishloc[0];
			f_EndLocation[1] = finishloc[1];
			f_EndLocation[2] = finishloc[2];
			GetClientAbsOrigin(idx, LR_Prisoner_Position[idx]);
			float f_PrisonerDistance[MAXPLAYERS + 1];
			if (koyulan_markerlar == 1)
			{
				f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], f_EndLocation, false);
				if (ilkkac >= 1)
				{
					if (kacinci <= ilkkac)
					{
						if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false)
						{
							Ekran_Renk_Olustur(idx, 0, 255, 0, 100);
							SetEntityRenderColor(idx, 0, 255, 0, 255);			
							CPrintToChatAll("[%s] {orange}[ %N ] {green}Yarışı %i. Bitirdi!", tag1, idx, kacinci);
							g_totalwinrace[idx]++;
							SaveSQLCookies(idx);						
							Yapti[idx] = true;
							kacinci++;
						}		
					}
					else
					{
						bIsRace = false;
					}
				}
			}
			else if (koyulan_markerlar == 2)
			{
				if (ilkkac >= 1 && i_marker[idx] == true)
				{
					if (kacinci <= ilkkac)
					{
						f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], f_EndLocation, false);
						if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false)
						{
							Ekran_Renk_Olustur(idx, 0, 255, 0, 100);
							SetEntityRenderColor(idx, 0, 255, 0, 255);			
							CPrintToChatAll("[%s] {orange}[ %N ] {green}Yarışı %i. Bitirdi!", tag1, idx, kacinci);
							g_totalwinrace[idx]++;
							SaveSQLCookies(idx);
							Yapti[idx] = true;
							kacinci++;
						}		
					}
					else
					{
						bIsRace = false;
					}
				}
				if (i_marker[idx] == false && u_marker[idx] == false && d_marker[idx] == false)
					f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], ikinciloc, false);
					
				if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false && i_marker[idx] == false)
				{
					CPrintToChat(idx, "[%s] {orange}İlk daireye girdin şimdi diğerine git!", tag1);
					Ekran_Renk_Olustur(idx, 255, 255, 0, 100);
					i_marker[idx] = true;
				}
			}
			else if (koyulan_markerlar == 3)
			{
				if (ilkkac >= 1 && u_marker[idx] == true && i_marker[idx] == true)
				{
					if (kacinci <= ilkkac)
					{
						f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], f_EndLocation, false);
						if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false)
						{
							Ekran_Renk_Olustur(idx, 0, 255, 0, 100);
							SetEntityRenderColor(idx, 0, 255, 0, 255);			
							CPrintToChatAll("[%s] {orange}[ %N ] {green}Yarışı %i. Bitirdi!", tag1, idx, kacinci);
							g_totalwinrace[idx]++;
							SaveSQLCookies(idx);
							Yapti[idx] = true;
							kacinci++;
						}		
					}
					else
					{
						bIsRace = false;
					}
				}
				if (i_marker[idx] == false && u_marker[idx] == false && d_marker[idx] == false)
					f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], ikinciloc, false);
					
				else if (i_marker[idx] == true && u_marker[idx] == false && d_marker[idx] == false)
					f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], ucunculoc, false);
					
				if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false && i_marker[idx] == false)
				{
					CPrintToChat(idx, "[%s] {orange}İlk daireye girdin şimdi diğerine git!", tag1);
					Ekran_Renk_Olustur(idx, 255, 255, 0, 100);
					i_marker[idx] = true;
				}
				else if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false && u_marker[idx] == false)
				{
					CPrintToChat(idx, "[%s] {orange}İkinci daireye girdin şimdi diğerine git!", tag1);
					Ekran_Renk_Olustur(idx, 255, 255, 0, 100);
					u_marker[idx] = true;
				}
			}
			else if (koyulan_markerlar == 4)
			{
				if (ilkkac >= 1 && d_marker[idx] == true && u_marker[idx] == true && i_marker[idx] == true)
				{
					if (kacinci <= ilkkac)
					{
						f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], f_EndLocation, false);
						if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false)
						{
							Ekran_Renk_Olustur(idx, 0, 255, 0, 100);
							SetEntityRenderColor(idx, 0, 255, 0, 255);			
							CPrintToChatAll("[%s] {orange}[ %N ] {green}Yarışı %i. Bitirdi!", tag1, idx, kacinci);
							g_totalwinrace[idx]++;
							SaveSQLCookies(idx);
							Yapti[idx] = true;
							kacinci++;
						}		
					}
					else
					{
						bIsRace = false;
					}
				}
				if (i_marker[idx] == false && u_marker[idx] == false && d_marker[idx] == false)
					f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], ikinciloc, false);
					
				else if (i_marker[idx] == true && u_marker[idx] == false && d_marker[idx] == false)
					f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], ucunculoc, false);
					
				else if (i_marker[idx] == true && u_marker[idx] == true && d_marker[idx] == false)
					f_PrisonerDistance[idx] = GetVectorDistance(LR_Prisoner_Position[idx], dordunculoc, false);
					
				if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false && i_marker[idx] == false)
				{
					CPrintToChat(idx, "[%s] {orange}İlk daireye girdin şimdi diğerine git!", tag1);
					Ekran_Renk_Olustur(idx, 255, 255, 0, 100);
					i_marker[idx] = true;
				}
				else if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false && u_marker[idx] == false)
				{
					CPrintToChat(idx, "[%s] {orange}İkinci daireye girdin şimdi diğerine git!", tag1);
					Ekran_Renk_Olustur(idx, 255, 255, 0, 100);
					u_marker[idx] = true;
				}
				else if (f_PrisonerDistance[idx] < 75.0 && Yapti[idx] == false && d_marker[idx] == false)
				{
					CPrintToChat(idx, "[%s] {orange}Üçüncü daireye girdin şimdi diğerine git!", tag1);
					Ekran_Renk_Olustur(idx, 255, 255, 0, 100);
					d_marker[idx] = true;
				}				
			}			
		}
	}
	return Plugin_Continue;
}

void DrawMarkers()
{
	int randomcolor[4];
	randomcolor[3] = 255;	
	if (startloc[0] != 0.0)
	{
		TE_SetupBeamRingPoint(startloc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, redColor, 1, 0);
		TE_SendToAll(0.1);
		startloc[2] += 10;
		TE_SetupBeamRingPoint(startloc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, redColor, 1, 0);
		TE_SendToAll(0.1);
		startloc[2] -= 10;
	}
	if (ikinciloc[0] != 0.0)
	{
		randomcolor[0] = GetRandomInt(0, 255);
		randomcolor[1] = GetRandomInt(0, 255);
		randomcolor[2] = GetRandomInt(0, 255);		
		TE_SetupBeamRingPoint(ikinciloc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, randomcolor, 1, 0);
		TE_SendToAll(0.1);
		ikinciloc[2] += 10;
		TE_SetupBeamRingPoint(ikinciloc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, randomcolor, 1, 0);
		TE_SendToAll(0.1);
		ikinciloc[2] -= 10;
	}
	if (ucunculoc[0] != 0.0)
	{
		randomcolor[0] = GetRandomInt(0, 255);
		randomcolor[1] = GetRandomInt(0, 255);
		randomcolor[2] = GetRandomInt(0, 255);		
		TE_SetupBeamRingPoint(ucunculoc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, randomcolor, 1, 0);
		TE_SendToAll(0.1);
		ucunculoc[2] += 10;
		TE_SetupBeamRingPoint(ucunculoc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, randomcolor, 1, 0);
		TE_SendToAll(0.1);
		ucunculoc[2] -= 10;
	}
	if (dordunculoc[0] != 0.0)
	{
		randomcolor[0] = GetRandomInt(0, 255);
		randomcolor[1] = GetRandomInt(0, 255);
		randomcolor[2] = GetRandomInt(0, 255);		
		TE_SetupBeamRingPoint(dordunculoc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, randomcolor, 1, 0);
		TE_SendToAll(0.1);
		dordunculoc[2] += 10;
		TE_SetupBeamRingPoint(dordunculoc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, randomcolor, 1, 0);
		TE_SendToAll(0.1);
		dordunculoc[2] -= 10;
	}
	if (finishloc[0] != 0)
	{
		TE_SetupBeamRingPoint(finishloc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, greenColor, 1, 0);
		TE_SendToAll();
		finishloc[2] += 10;
		TE_SetupBeamRingPoint(finishloc, 100.0, 100.1, BeamSprite, HaloSprite, 0, 15, 1.0, 2.0, 0.0, greenColor, 1, 0);
		TE_SendToAll();
		finishloc[2] -= 10;
	}
}

void Ekran_Renk_Olustur(int client, int Renk1, int Renk2, int Renk3, int Renk4)
{
	int clients[2];
	clients[0] = client;
	int Sure = 200;
	int holdtime = 40;
	int flags = 17;
	int Renk[4];
	Renk[0] = Renk1;
	Renk[1] = Renk2;
	Renk[2] = Renk3;
	Renk[3] = Renk4;
	Handle message = StartMessageEx(GetUserMessageId("Fade"), clients, 1, 0);
	if(GetUserMessageType() == UM_Protobuf)
	{
		Protobuf pb = UserMessageToProtobuf(message);
		pb.SetInt("duration", Sure, -1);
		pb.SetInt("hold_time", holdtime, -1);
		pb.SetInt("flags", flags, -1);
		pb.SetColor("clr", Renk, -1);
	}
	else
	{
		BfWriteShort(message, Sure);
		BfWriteShort(message, holdtime);
		BfWriteShort(message, flags);
		BfWriteByte(message, Renk[0]);
		BfWriteByte(message, Renk[1]);
		BfWriteByte(message, Renk[2]);
		BfWriteByte(message, Renk[3]);
	}
	EndMessage();
	return;
}

stock void StripAllWeapons(int client)
{
	int wepIdx;
	for (int i; i < 4; i++)
	{
		if ((wepIdx = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, wepIdx);
			AcceptEntityInput(wepIdx, "Kill");
		}
	}
	GivePlayerItem(client, "weapon_knife");
}

public void end(Handle event, const char[] name, bool dontBroadcast)
{
	Sifirla();
}

public Action Hook_SetTransmit(int iClient, int iOther)
{
    if (yarisoyunu && iClient != iOther && GetClientTeam(iClient) == 2 && GetClientTeam(iOther) == 2)
    {
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public int OnSQLConnect(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Database failure: %s", error);
		
		SetFailState("Databases dont work");
	}
	else
	{
		g_hDB = hndl;
		
		SQL_GetDriverIdent(SQL_ReadDriver(g_hDB), g_sSQLBuffer, sizeof(g_sSQLBuffer));
		g_bIsMySQl = StrEqual(g_sSQLBuffer,"mysql", false) ? true : false;
		
		if(g_bIsMySQl)
		{
			Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE IF NOT EXISTS `Yaris` (`playername` varchar(128) NOT NULL, `steamid` varchar(32) PRIMARY KEY NOT NULL, `total` INT( 16 ))");
			
			SQL_TQuery(g_hDB, OnSQLConnectCallback, g_sSQLBuffer);
		}
		else
		{
			Format(g_sSQLBuffer, sizeof(g_sSQLBuffer), "CREATE TABLE IF NOT EXISTS Yaris (playername varchar(128) NOT NULL, steamid varchar(32) PRIMARY KEY NOT NULL, total INTEGER)");
			
			SQL_TQuery(g_hDB, OnSQLConnectCallback, g_sSQLBuffer);
		}
	}
}
//////SQL
public int OnSQLConnectCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			OnClientPostAdminCheck(client);
		}
	}
}

public void SaveSQLCookies(int client)
{
	char steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid) );
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(g_hDB, Name, SafeName, sizeof(SafeName));
	}	

	char buffer[3096];
	Format(buffer, sizeof(buffer), "UPDATE Yaris SET playername = '%s',total = '%i' WHERE steamid = '%s';", SafeName, g_totalwinrace[client], steamid);
	SQL_TQuery(g_hDB, SaveSQLPlayerCallback, buffer);
	g_bChecked[client] = false;
}

public void CheckSQLSteamID(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid) );
	
	Format(query, sizeof(query), "SELECT total FROM Yaris WHERE steamid = '%s'", steamid);
	SQL_TQuery(g_hDB, CheckSQLSteamIDCallback, query, GetClientUserId(client));
}

public int CheckSQLSteamIDCallback(Handle owner, Handle hndl, char [] error, any data)
{
	int client;
	
	
	if((client = GetClientOfUserId(data)) == 0)
	{
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
		return;
	}
	if(!SQL_GetRowCount(hndl) || !SQL_FetchRow(hndl)) 
	{
		InsertSQLNewPlayer(client);
		return;
	}
	
	g_totalwinrace[client] = SQL_FetchInt(hndl, 0);
	g_bChecked[client] = true;
}

public void InsertSQLNewPlayer(int client)
{
	char query[255], steamid[32];
	GetClientAuthId(client, AuthId_Steam2,steamid, sizeof(steamid));
	int userid = GetClientUserId(client);
	
	char Name[MAX_NAME_LENGTH+1];
	char SafeName[(sizeof(Name)*2)+1];
	if(!GetClientName(client, Name, sizeof(Name)))
		Format(SafeName, sizeof(SafeName), "<noname>");
	else
	{
		TrimString(Name);
		SQL_EscapeString(g_hDB, Name, SafeName, sizeof(SafeName));
	}
	
	Format(query, sizeof(query), "INSERT INTO Yaris(playername, steamid,  total) VALUES('%s', '%s', '0');", SafeName, steamid);
	SQL_TQuery(g_hDB, SaveSQLPlayerCallback, query, userid);
	g_totalwinrace[client] = 0;
	
	Call_StartForward(gF_OnInsertNewPlayer);
	Call_PushCell(client);
	Call_Finish();
	
	g_bChecked[client] = true;
}

public int SaveSQLPlayerCallback(Handle owner, Handle hndl, char [] error, any data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Query failure: %s", error);
	}
}

public void ShowTotal(int client)
{
	if(g_hDB != INVALID_HANDLE)
	{
		char buffer[200];
		Format(buffer, sizeof(buffer), "SELECT playername, total, steamid FROM Yaris ORDER BY total DESC LIMIT 999");
		SQL_TQuery(g_hDB, ShowTotalCallback, buffer, client);
	}
	else
	{
		PrintToChat(client, " \x03Rank System is now not avilable");
	}
}

public int ShowTotalCallback(Handle owner, Handle hndl, char [] error, any client)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError(error);
		PrintToServer("Last Connect SQL Error: %s", error);
		return;
	}
	
	Menu menu2 = CreateMenu(DIDMenuHandler2);
	menu2.SetTitle("En Çok Yarış Kazananlar");
	
	int order = 0;
	char number[64];
	char name[64];
	char textbuffer[128];
	char steamid[128];
	int totalwinrace;
	if(SQL_HasResultSet(hndl))
	{
		while (SQL_FetchRow(hndl))
		{
			order++;
			Format(number,64, "option%i", order);
			SQL_FetchString(hndl, 0, name, sizeof(name));
			SQL_FetchString(hndl, 2, steamid, sizeof(steamid));
			totalwinrace = SQL_FetchInt(hndl, 1);
			Format(textbuffer, 128, "%s - %i Kez Yarış Bitirmiş", name, totalwinrace);
			menu2.AddItem(steamid, textbuffer);
		}
	}
	if(order < 1) 
	{
		menu2.AddItem("empty", "TOP is empty!");
	}
	
	menu2.ExitButton = true;
	menu2.Display(client, MENU_TIME_FOREVER);
}

public int DIDMenuHandler2(Menu menu2, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_End){
		delete menu2;
	}
}

public Action Command_Sifirlayalimbakalim(int client, int args)
{
	PrintToChat(client, "Yariş Verileri sıfırlandı, dene bakalim");
	char buffer[200];
	Format(buffer, sizeof(buffer), "SELECT playername, total, steamid FROM yaris ORDER BY total DESC LIMIT 99999");
	SilHepsiniAmk();
}

public void SilHepsiniAmk()
{
    if(g_hDB == INVALID_HANDLE)
    {
        return;
    }

    char buffer[1024];

    if(g_bIsMySQl)
        Format(buffer, sizeof(buffer), "DELETE FROM yaris;");
    else
        Format(buffer, sizeof(buffer), "DELETE FROM yaris;");
    SQL_TQuery(g_hDB, ResetDataBaseCallBack, buffer);
}

public int ResetDataBaseCallBack(Handle owner, Handle hndl, char [] error, any data){
    ServerCommand("sm plugins reload yaris");
}