/********************************************** 
** ZPS Infection Toolkit
** by DR RAMBONE MURDOCH PHD
**
** Visit the West Coast Zombie Hideout
**
*/
#if defined _zpsinfectiontoolkit_included
 #endinput
#endif
#define _zpsinfectiontoolkit_included

native Float:ZIT_InfectPlayerInXSeconds(player, Float:seconds);
native ZIT_DisinfectPlayer(player);
native bool:ZIT_PlayerIsInfected(player);
native Float:ZIT_GetPlayerTurnTime(player);
