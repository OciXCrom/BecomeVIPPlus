#if defined _becomevip_included
    #endinput
#endif

#define _becomevip_included

/**
 * Returns the flags that VIP users get as a bitsum.
 *
 * @return          Flags that VIP users get as a bitsum
 */
native becomevip_get_flags()

/**
 * Returns the number of kills needed to become VIP.
 *
 * @return         	Number of kills needed to become VIP
 */
native becomevip_get_kills_needed()

/**
 * Returns the save type for players' kills.
 *
 * @return         	Save type for players' kills
 */
native becomevip_get_save_type()

/**
 * Returns the number of kills the player has.
 *
 * @param id     	Client index
 *
 * @return         	Save type for players' kills
 */
native becomevip_get_user_kills(const id)

/**
 * Checks whether HUD messages are enabled for the plugin.
 *
 * @return         	true if they are, false otherwise
 */
native bool:becomevip_is_hud_enabled()

/**
 * Checks whether the player has the flags offered by the plugin.
 *
 * @return         	true if he has, false otherwise
 */
native bool:becomevip_user_has_flags(const id)