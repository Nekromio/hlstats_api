void ConnectCallBack(Database hDB, const char[] szError, any data) // Пришел результат соединения
{
    if (hDB == null || szError[0]) // Соединение неудачное
    {
        SetFailState("[Error] ConnectCallBack Ошибка подключения к базе: %s", szError); // Отключаем плагин
        return;
    }

    hDatabase = hDB;
    hDatabase.SetCharset("utf8");
}

// Берём данные одного игрока
void HLS_GetClientData(int client)
{
    char query[1024], steam[32];
    FormatSteamID(client, steam, sizeof(steam));

    FormatEx(query, sizeof(query),
        "SELECT p.playerId, p.kills, p.deaths, p.suicides, p.skill, p.shots, p.hits, p.headshots, p.kill_streak, p.death_streak, \
                p.teamkills, p.connection_time, \
                (SELECT COUNT(*) FROM hlstats_Players) as total_players, \
                (SELECT COUNT(*) + 1 FROM hlstats_Players WHERE skill > p.skill) AS rank_position, \
                p.createdate \
        FROM hlstats_Players p \
        INNER JOIN hlstats_PlayerUniqueIds u ON p.playerId = u.playerId \
        WHERE u.uniqueId = '%s';",
        steam);

    hDatabase.Query(HLS_GetClientData_Callback, query, GetClientUserId(client));
}

public void HLS_GetClientData_Callback(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any userID)
{
    if (sError[0])
    {
        LogError("HLS_GetClientData_Callback: %s", sError);
        return;
    }

    int client = GetClientOfUserId(userID);
    if (!client) return;

    if (hResults.FetchRow()) // Если нашли игрока
    {
        stats[client].playerId = hResults.FetchInt(0);
        stats[client].kills = hResults.FetchInt(1);
        stats[client].deaths = hResults.FetchInt(2);
        stats[client].suicides = hResults.FetchInt(3);
        stats[client].skill = hResults.FetchInt(4);
        stats[client].shots = hResults.FetchInt(5);
        stats[client].hits = hResults.FetchInt(6);
        stats[client].headshots = hResults.FetchInt(7);
        stats[client].kill_streak = hResults.FetchInt(8);
        stats[client].death_streak = hResults.FetchInt(9);
        stats[client].teamkills = hResults.FetchInt(10);
        stats[client].playtime = hResults.FetchInt(11);       // Время на сервере (в секундах)
        stats[client].total_players = hResults.FetchInt(12);  // Общее количество игроков
        stats[client].rank = hResults.FetchInt(13);           // Ранг игрока (позиция в рейтинге)
        stats[client].createdate = hResults.FetchInt(14);     // Дата регистрации в Unix
    }
    else
    {
        stats[client].Reset();
    }
}

// Берём данные сразу всех игроков
void HLS_GetClientDataAll()
{
    char query[4096], steamList[2048] = "";
    char steamID[32];
    int count = 0;

    // Собираем список SteamID всех игроков на сервере
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            FormatSteamID(i, steamID, sizeof(steamID));

            if (count > 0)
                StrCat(steamList, sizeof(steamList), ", ");

            // Добавляем SteamID в список (SQL требует кавычек)
            char temp[40];
            Format(temp, sizeof(temp), "'%s'", steamID);
            StrCat(steamList, sizeof(steamList), temp);
            
            count++;
        }
    }

    if (count == 0)
        return; // Нет игроков на сервере

    // Формируем SQL-запрос только для текущих игроков
    FormatEx(query, sizeof(query),
        "SELECT u.uniqueId, p.playerId, p.kills, p.deaths, p.suicides, p.skill, p.shots, p.hits, p.headshots, p.kill_streak, \
                p.death_streak, p.teamkills, p.connection_time, \
                (SELECT COUNT(*) FROM hlstats_Players) as total_players, \
                (SELECT COUNT(*) + 1 FROM hlstats_Players WHERE skill > p.skill) AS rank_position, \
                p.createdate \
        FROM hlstats_Players p \
        INNER JOIN hlstats_PlayerUniqueIds u ON p.playerId = u.playerId \
        WHERE u.uniqueId IN (%s);", steamList);

    hDatabase.Query(HLS_GetClientDataAll_Callback, query, 0);
}

public void HLS_GetClientDataAll_Callback(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any userID)
{
    if (sError[0])
    {
        LogError("HLS_GetClientDataAll_Callback: %s", sError);
        return;
    }

    while (hResults.FetchRow()) // Перебираем всех найденных игроков
    {
        char steamID[32];
        hResults.FetchString(0, steamID, sizeof(steamID)); // uniqueId из базы

        int client = FindClientBySteamID(steamID);
        if (!client) continue; // Пропускаем, если игрок не найден

        stats[client].playerId = hResults.FetchInt(1);
        stats[client].kills = hResults.FetchInt(2);
        stats[client].deaths = hResults.FetchInt(3);
        stats[client].suicides = hResults.FetchInt(4);
        stats[client].skill = hResults.FetchInt(5);
        stats[client].shots = hResults.FetchInt(6);
        stats[client].hits = hResults.FetchInt(7);
        stats[client].headshots = hResults.FetchInt(8);
        stats[client].kill_streak = hResults.FetchInt(9);
        stats[client].death_streak = hResults.FetchInt(10);
        stats[client].teamkills = hResults.FetchInt(11);
        stats[client].playtime = hResults.FetchInt(12);
        stats[client].total_players = hResults.FetchInt(13);
        stats[client].rank = hResults.FetchInt(14); // Ранг игрока
        stats[client].createdate = hResults.FetchInt(15);
    }
}