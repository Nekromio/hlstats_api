#pragma semicolon 1
#pragma newdecls required

Database
	hDatabase;

enum HLStatsIntInfo
{
    HLS_ID,             // playerId (уникальный идентификатор игрока) int
    HLS_KILLS,          // Количество убийств
    HLS_DEATHS,         // Количество смертей
    HLS_SUICIDES,       // Количество самоубийств
    HLS_SKILL,          // Очки "скилла"
    HLS_SHOTS,          // Количество сделанных выстрелов
    HLS_HITS,           // Количество попаданий
    HLS_HEADSHOTS,      // Количество убийств в голову
    HLS_KILL_STREAK,    // Самая длинная серия убийств
    HLS_DEATH_STREAK,   // Самая длинная серия смертей
    HLS_TEAMKILLS,      // Количество тимкилов
    HLS_RANKME,         // Ранг игрока в статистике
    HLS_RANKALL         // Общее количество игроков в статистике
};

enum HLStatsFloatInfo
{
    HLS_KD              // К/Д (убийства / смерти), `float`
};

enum HLStatsStringInfo
{
    HLS_CREATEDATE,     // Дата создания профиля (строка)
    HLS_PLAYTIME        // Время на сервере ("5 дней, 14 часов" или "10 часов 15 минут")
};

enum struct PlayerStats
{
    int playerId;       // Уникальный идентификатор игрока в базе HLstatsX
    int kills;          // Количество убийств игрока
    int deaths;         // Количество смертей игрока
    int suicides;       // Количество самоубийств игрока
    int skill;          // Очки "скилла"
    int shots;          // Количество сделанных выстрелов
    int hits;           // Количество попаданий по врагам
    int headshots;      // Количество убийств в голову
    int kill_streak;    // Самая длинная серия убийств без смерти
    int death_streak;   // Самая длинная серия смертей без убийства
    int teamkills;      // Количество тимкилов
    int rank;           // Ранг игрока в статистике
    int total_players;  // Всего игроков в статистике
    int playtime;       // Время на сервере (переведенное в часы/дни) в секундах
    int createdate;     // Дата в unix создания профиля

    void Reset()
    {
        this.playerId = 0;
        this.kills = 0;
        this.deaths = 0;
        this.suicides = 0;
        this.skill = 0;
        this.shots = 0;
        this.hits = 0;
        this.headshots = 0;
        this.kill_streak = 0;
        this.death_streak = 0;
        this.teamkills = 0;
        this.rank = 0;
        this.total_players = 0;
        this.playtime = 0;
        this.createdate = 0;
    }
}

PlayerStats stats[MAXPLAYERS+1];

char sFile[2][512];

#include "hlstats_api/db.sp"
#include "hlstats_api/api.sp"

public APLRes AskPluginLoad2()
{
    CreateNative("HLS_GetClientIntInfo", Native_GetClientIntInfo);
    CreateNative("HLS_GetClientFloatInfo", Native_GetClientFloatInfo);
    CreateNative("HLS_GetClientStringInfo", Native_GetClientStringInfo);

    RegPluginLibrary("hlstats_api");

    return APLRes_Success;
}

public Plugin myinfo = 
{
    name = "HLStats API",
    author = "Nek.'a 2x2",
    description = "HLStats API",
    version = "1.0.0 100",
    url = "ggwp.site || vk.com/nekromio || t.me/sourcepwn"
};

public void OnPluginStart()
{
    BuildPath(Path_SM, sFile[0], sizeof(sFile[]), "logs/hlstats_connect.log");
    BuildPath(Path_SM, sFile[1], sizeof(sFile[]), "logs/hlstats_timer.log");
}

public void OnConfigsExecuted()
{
    Database.Connect(ConnectCallBack, "hlstats");

    CreateTimer(30.0, Timer_GetHLSData, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE );
}

public void OnClientPostAdminCheck(int client)
{
    if(IsFakeClient(client))
        return;
    
    HLS_GetClientData(client);
}

public void OnClientDisconnect(int client)
{
    stats[client].Reset();
}

bool IsValidClient(int client)
{
    return 0 < client <= MaxClients && IsClientInGame(client);
}

Action Timer_GetHLSData(Handle hTimer)
{
    HLS_GetClientDataAll();
    return Plugin_Continue;
}

void FormatSteamID(int client, char[] steamOut, int maxlen)
{
    if (!IsValidClient(client))
    {
        strcopy(steamOut, maxlen, "INVALID"); // Записываем ошибку
        return;
    }

    char steam[32], steamParts[3][16];
    GetClientAuthId(client, AuthId_Steam2, steam, sizeof(steam));

    // Разбиваем SteamID на части
    if (ExplodeString(steam, ":", steamParts, 3, 16) != 3)
    {
        strcopy(steamOut, maxlen, "ERROR"); // Ошибка разбиения
        return;
    }

    // Формируем новый SteamID
    Format(steamOut, maxlen, "%s:%s", steamParts[1], steamParts[2]);
}

int FindClientBySteamID(const char[] dbSteamID)
{
    char clientSteam[32];

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            GetClientAuthId(i, AuthId_Steam2, clientSteam, sizeof(clientSteam));

            // Преобразуем `STEAM_X:Y:Z` в `Y:Z`
            char parts[3][16];
            if (ExplodeString(clientSteam, ":", parts, 3, 16) == 3)
            {
                char formattedSteam[32];
                Format(formattedSteam, sizeof(formattedSteam), "%s:%s", parts[1], parts[2]);

                if (StrEqual(formattedSteam, dbSteamID, false))
                {
                    return i; // Найден соответствующий игрок
                }
            }
        }
    }
    return 0; // Игрок не найден
}