#if defined _hlstats_api_included
    #endinput
#endif
#define _hlstats_api_included

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
    HLS_RANKALL         // Сколько всего человек в статистике
};

enum HLStatsFloatInfo
{
    HLS_KD              // К/Д (убийства / смерти), `float`
};

enum HLStatsStringInfo
{
    HLS_CREATEDATE,     // Дата создания профиля (строка)
    HLS_PLAYTIME        // Общее время, проведённое на сервере (формат: "5 дней, 14 часов" или "10 часов 15 минут")
};

/**
 * Получить числовую статистику игрока (int)
 *
 * @param client - Индекс игрока
 * @param infoType - Один из параметров HLStatsIntInfo
 * 
 * @return Значение параметра, -1 в случае ошибки
 */
native int HLS_GetClientIntInfo(int client, HLStatsIntInfo infoType);

/**
 * Получить числовую статистику игрока (float) через `any`
 *
 * @param client - Индекс игрока
 * @param infoType - Один из параметров HLStatsFloatInfo
 * 
 * @return Значение параметра (float, передаётся через any), -1.0 в случае ошибки
 */
native any HLS_GetClientFloatInfo(int client, HLStatsFloatInfo infoType);

/**
 * Получить строковую статистику игрока (char[])
 *
 * @param client - Индекс игрока
 * @param infoType - Один из параметров HLStatsStringInfo
 * @param buffer - Буфер, в который будет записано значение
 * @param maxlen - Максимальная длина строки
 * 
 * @return Всегда `0`
 */
native int HLS_GetClientStringInfo(int client, HLStatsStringInfo infoType, char[] buffer, int maxlen);

public SharedPlugin __pl_hlstats_api = 
{
    name = "hlstats_api",
    file = "hlstats_api",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_hlstats_api_SetNTVOptional()
{
    MarkNativeAsOptional("HLS_GetClientIntInfo");
    MarkNativeAsOptional("HLS_GetClientFloatInfo");
    MarkNativeAsOptional("HLS_GetClientStringInfo");
}
#endif