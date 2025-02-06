public int Native_GetClientIntInfo(Handle hPlugin, int iNumParams)
{
    int client = GetNativeCell(1);
    HLStatsIntInfo infoType = view_as<HLStatsIntInfo>(GetNativeCell(2));

    if (!IsValidClient(client))
        return -1;

    switch (infoType)
    {
        case HLS_ID:           return stats[client].playerId;
        case HLS_KILLS:        return stats[client].kills;
        case HLS_DEATHS:       return stats[client].deaths;
        case HLS_SUICIDES:     return stats[client].suicides;
        case HLS_SKILL:        return stats[client].skill;
        case HLS_SHOTS:        return stats[client].shots;
        case HLS_HITS:         return stats[client].hits;
        case HLS_HEADSHOTS:    return stats[client].headshots;
        case HLS_KILL_STREAK:  return stats[client].kill_streak;
        case HLS_DEATH_STREAK: return stats[client].death_streak;
        case HLS_TEAMKILLS:    return stats[client].teamkills;
        case HLS_RANKME:       return stats[client].rank;
        case HLS_RANKALL:      return stats[client].total_players;
    }

    return -1;
}

public any Native_GetClientFloatInfo(Handle hPlugin, int iNumParams)
{
    int client = GetNativeCell(1);
    HLStatsFloatInfo infoType = view_as<HLStatsFloatInfo>(GetNativeCell(2));

    if (!IsValidClient(client))
        return view_as<any>(-1.0);

    switch (infoType)
    {
        case HLS_KD:
        {
            char buffer[12];

            if (stats[client].deaths == 0)
            {
                Format(buffer, sizeof(buffer), "%.2f", float(stats[client].kills));
                return view_as<any>(StringToFloat(buffer)); // Если смертей нет, K/D = kills
            }
                
            float kd = float(stats[client].kills) / float(stats[client].deaths);
            Format(buffer, sizeof(buffer), "%.2f", kd);
            return view_as<any>(StringToFloat(buffer)); // ✅ Теперь передаем buffer
        }
    }

    return view_as<any>(-1.0);
}

public int Native_GetClientStringInfo(Handle hPlugin, int iNumParams)
{
    int client = GetNativeCell(1);
    HLStatsStringInfo infoType = view_as<HLStatsStringInfo>(GetNativeCell(2));
    char buffer[64];
    int maxlen = GetNativeCell(3);

    if (!IsValidClient(client))
    {
        strcopy(buffer, maxlen, "N/A");
        SetNativeString(3, buffer, maxlen);
        return 0;
    }

    switch (infoType)
    {
        case HLS_CREATEDATE:
        {
            if (stats[client].createdate > 0)
            {
                FormatTime(buffer, maxlen, "%Y-%m-%d %H:%M:%S", stats[client].createdate);
            }
            else
            {
                strcopy(buffer, maxlen, "N/A");
            }
        }

        case HLS_PLAYTIME:
        {
            int totalSeconds = stats[client].playtime;
            int days = totalSeconds / 86400;  // 86400 секунд в дне
            int hours = (totalSeconds % 86400) / 3600;
            int minutes = (totalSeconds % 3600) / 60;

            if (days > 0)
                Format(buffer, maxlen, "%d дней, %d часов", days, hours);
            else
                Format(buffer, maxlen, "%d часов %d минут", hours, minutes);
        }
    }

    SetNativeString(3, buffer, maxlen);
    return 0;
}