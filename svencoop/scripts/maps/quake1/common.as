#include "ammo"
#include "items"
#include "triggers"
#include "monsters/monsters"
#include "weapons/projectile"
#include "weapons/weapon_qaxe"
#include "weapons/weapon_qshotgun"
#include "weapons/weapon_qshotgun2"
#include "weapons/weapon_qnailgun"
#include "weapons/weapon_qnailgun2"
#include "weapons/weapon_qgrenade"
#include "weapons/weapon_qrocket"
#include "weapons/weapon_qthunder"

/* TODO 
- mixin class weapon_qgeneric, shit's getting ridiculous
- keys/runes
*/

void q1_InitCommon() {
  q1_PrecachePlayerSounds();

  q1_RegisterProjectiles();
  q1_RegisterAmmo();
  q1_RegisterItems();
  q1_RegisterTriggers();
  q1_RegisterWeapon_AXE();
  q1_RegisterWeapon_SHOTGUN();
  q1_RegisterWeapon_SHOTGUN2();
  q1_RegisterWeapon_NAILGUN();
  q1_RegisterWeapon_NAILGUN2();
  q1_RegisterWeapon_GRENADE();
  q1_RegisterWeapon_ROCKET();
  q1_RegisterWeapon_THUNDER();

  g_Hooks.RegisterHook(Hooks::Player::PlayerSpawn, @q1_PlayerSpawn);
  g_Hooks.RegisterHook(Hooks::Player::PlayerKilled, @q1_PlayerKilled);
  g_Hooks.RegisterHook(Hooks::Player::PlayerPostThink, @q1_PlayerPostThink);
}

HookReturnCode q1_PlayerSpawn(CBasePlayer@ pPlayer) {
  q1_SetAmmoCaps(pPlayer);
  CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
  pCustom.SetKeyvalue("$fl_lastHealth", pPlayer.pev.health);
  pCustom.SetKeyvalue("$fl_lastPain", 0.0);
  return HOOK_CONTINUE;
}

HookReturnCode q1_PlayerKilled(CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib) {
  if (pPlayer.pev.health > -30) {
    // AUTHENTIC DEATH SOUNDS
    if (pPlayer.pev.waterlevel == WATERLEVEL_HEAD) {
      g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "quake1/player/drown.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
    } else {
      int iNum = Math.RandomLong(1, 5);
      string sName = "quake1/player/death" + string(iNum) + ".wav";
      g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, sName, Math.RandomFloat(0.95, 1.0), ATTN_NORM);
    }  
  }

  // spawn a backpack, moving player's weapon and ammo into it
  item_qbackpack@ pPack = q1_SpawnBackpack(pPlayer);
  @pPack.m_pWeapon = cast<CBasePlayerItem@>(pPlayer.m_hActiveItem.GetEntity());
  pPlayer.RemovePlayerItem(cast<CBasePlayerItem@>(pPlayer.m_hActiveItem.GetEntity()));
  pPack.m_iAmmoShells = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"));
  pPack.m_iAmmoNails = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("bolts"));
  pPack.m_iAmmoRockets = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("rockets"));
  pPack.m_iAmmoCells = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("uranium"));
  pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"), 0);
  pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("bolts"), 0);
  pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("rockets"), 0);
  pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("uranium"), 0);
  if (pPack.m_pWeapon is null && pPack.m_iAmmoShells == 0 && pPack.m_iAmmoNails == 0 && pPack.m_iAmmoRockets == 0 && pPack.m_iAmmoCells == 0)
    g_EntityFuncs.Remove(pPack.self);
  return HOOK_CONTINUE;
}

HookReturnCode q1_PlayerPostThink(CBasePlayer@ pPlayer) {
  q1_PlayPlayerPainSounds(pPlayer);
  q1_PlayPlayerJumpSounds(pPlayer);
  return HOOK_CONTINUE;
}

void q1_PlayPlayerPainSounds(CBasePlayer@ pPlayer) {
  // get all damage we've accumulated and play AUTHENTIC PAIN SOUNDS
  // there's no robust way to actually get damage that the player
  // received during the previous frame, so we store his previous health
  // in a custom keyvalue and also a pain timeout to not scream too often
  CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
  float flLastHealth = pCustom.GetKeyvalue("$fl_lastHealth").GetFloat();
  float flLastPain = pCustom.GetKeyvalue("$fl_lastPain").GetFloat();

  if (flLastHealth <= pPlayer.pev.health) return;
  pCustom.SetKeyvalue("$fl_lastHealth", pPlayer.pev.health); 
  if (flLastPain > g_Engine.time) return;
  if (pPlayer.pev.health <= 0) return;

  float flDmg = pPlayer.m_lastPlayerDamageAmount;
  if (flDmg < 5.0 || (flLastHealth - pPlayer.pev.health < 5.0)) return;

  int iDmgType = pPlayer.m_bitsDamageType;
  string sName;
  if ((iDmgType & DMG_BURN) != 0 || (iDmgType & DMG_ACID) != 0) {
    // we're in lava or acid or some shit, scream properly
    sName = "quake1/player/burn" + string(Math.RandomLong(1, 2)) + ".wav";
  } else if ((iDmgType & DMG_FALL) != 0) {
    // fell
    sName = "quake1/player/fall.wav";
  } else {
    // scream with intensity proportional to damage value
    int iNum = 1 + int(flDmg / 20) + Math.RandomLong(0, 2);
    if (iNum > 6) iNum = 6;
    if (iNum < 1) iNum = 1;
    sName = "quake1/player/pain" + string(iNum) + ".wav";
  }
  pCustom.SetKeyvalue("$fl_lastPain", g_Engine.time + 1.0);
  g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, sName, Math.RandomFloat(0.95, 1.0), ATTN_NORM);
}

void q1_PlayPlayerJumpSounds(CBasePlayer@ pPlayer) {
  if (pPlayer.pev.health < 1) return; // don't HUP if dead
  if ((pPlayer.m_afButtonPressed & IN_JUMP) != 0 && (pPlayer.pev.waterlevel < WATERLEVEL_WAIST)) {
    TraceResult tr;
    // gotta trace it because we already jumped at this point
    // this is a hack, but there's no PlayerJump hook or anything, so it'll do
    g_Utility.TraceHull(pPlayer.pev.origin, pPlayer.pev.origin + Vector(0, 0, -5), dont_ignore_monsters, human_hull, pPlayer.edict(), tr);
    if (tr.flFraction < 1.0)
      g_SoundSystem.EmitSoundDyn(pPlayer.edict(), CHAN_VOICE, "quake1/player/jump.wav", Math.RandomFloat(0.95, 1.0), ATTN_NORM);
  }
}

void q1_PrecachePlayerSounds() {
  g_SoundSystem.PrecacheSound("quake1/player/pain1.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain2.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain3.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain4.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain5.wav");
  g_SoundSystem.PrecacheSound("quake1/player/pain6.wav");
  g_SoundSystem.PrecacheSound("quake1/player/burn1.wav");
  g_SoundSystem.PrecacheSound("quake1/player/burn2.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death1.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death2.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death3.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death4.wav");
  g_SoundSystem.PrecacheSound("quake1/player/death5.wav");
  g_SoundSystem.PrecacheSound("quake1/player/drown.wav");
  g_SoundSystem.PrecacheSound("quake1/player/jump.wav");
  g_SoundSystem.PrecacheSound("quake1/gib.wav");
}
