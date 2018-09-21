mixin class item_qgeneric {
  string m_sModel;
  string m_sSound;
  CScheduledFunction@ m_pRotFunc;
  CScheduledFunction@ m_pEndFunc;
  CBasePlayer@ m_pPlayer;

  void CommonSpawn() {
    Precache();
    BaseClass.Spawn();
    self.FallInit();
    g_EntityFuncs.SetModel(self, m_sModel);
    self.pev.noise = m_sSound; // this actually doesn't work, so have to schedule later
    @m_pRotFunc = @g_Scheduler.SetInterval(this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES);
    @m_pEndFunc = null;
    @m_pPlayer = null;
  }

  void Precache() {
    g_Game.PrecacheModel(m_sModel);
    g_SoundSystem.PrecacheSound(m_sSound);     
  }

  void RotateThink() {
    self.pev.angles.y += 1.0;
  }

  bool AddToPlayer(CBasePlayer@ pPlayer) {
    // CBasePlayerItem@ pPrev = pPlayer.m_pActiveItem;
    if(BaseClass.AddToPlayer(pPlayer)) {
      // pPlayer.SwitchWeapon(pPrev);
      if (ApplyEffects(pPlayer)) {
        NetworkMessage message(MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict());
        message.WriteString(self.pszName());
        message.End();
        g_Scheduler.RemoveTimer(m_pRotFunc);
        @m_pRotFunc = null;
        q1_ScheduleItemSound(pPlayer, m_sSound);
        @m_pPlayer = @pPlayer;
        return true;
      }
    }
    return false;
  }

  void UpdateOnRemove() {
    if (!(m_pRotFunc is null))
      g_Scheduler.RemoveTimer(m_pRotFunc);
    if (!(m_pEndFunc is null))
      g_Scheduler.RemoveTimer(m_pEndFunc);
    BaseClass.UpdateOnRemove();
  }

  void KillSelf() {
    if (m_pPlayer.HasPlayerItem(self))
      m_pPlayer.RemovePlayerItem(self);
    g_EntityFuncs.Remove(self);
  }

  CBasePlayerWeapon@ GetWeaponPtr() {
    return null;
  }
}

// turns out using BasePlayerItem is not the way to make actual items
// but it's too late now
class item_qquad : ScriptBasePlayerItemEntity, item_qgeneric {
  void Spawn() {
    m_sModel = "models/quake1/w_quad.mdl";
    m_sSound = "quake1/quad.wav";
    g_SoundSystem.PrecacheSound("quake1/quad_s.wav");
    CommonSpawn();
  }

  bool ApplyEffects(CBasePlayer@ pPlayer) {
    pPlayer.pev.renderfx = kRenderFxGlowShell;
    pPlayer.pev.rendercolor.z = 255;
    pPlayer.pev.renderamt = 1;
    @m_pEndFunc = @g_Scheduler.SetTimeout(this, "RemoveEffects", 30.0);
    return true;
  }

  void RemoveEffects() {
    if (m_pPlayer is null) return;
    m_pPlayer.pev.rendercolor.z = 0;
    if (m_pPlayer.HasNamedPlayerItem("item_qsuit") is null && m_pPlayer.HasNamedPlayerItem("item_qinvul") is null) {
      m_pPlayer.pev.renderfx = kRenderFxNone;
      m_pPlayer.pev.renderamt = 0;
    }
    KillSelf();
  }

  bool GetItemInfo(ItemInfo& out info) {
    info.iWeight = -1;
    return true;
  }
}

class item_qinvul : ScriptBasePlayerItemEntity, item_qgeneric {
  void Spawn() {
    m_sModel = "models/quake1/w_invul.mdl";
    m_sSound = "quake1/invul.wav";
    CommonSpawn();
  }

  bool ApplyEffects(CBasePlayer@ pPlayer) {
    pPlayer.pev.renderfx = kRenderFxGlowShell;
    pPlayer.pev.rendercolor.x = 255;
    pPlayer.pev.renderamt = 1;
    pPlayer.pev.flags |= FL_GODMODE;
    @m_pEndFunc = @g_Scheduler.SetTimeout(this, "RemoveEffects", 30.0);
    return true;
  }

  void RemoveEffects() {
    if (m_pPlayer is null) return;
    m_pPlayer.pev.rendercolor.x = 0;
    if (m_pPlayer.HasNamedPlayerItem("item_qquad") is null && m_pPlayer.HasNamedPlayerItem("item_qsuit") is null) {
      m_pPlayer.pev.renderfx = kRenderFxNone;
      m_pPlayer.pev.renderamt = 0;
    }
    m_pPlayer.pev.flags &= ~FL_GODMODE;
    KillSelf();
  }

  bool GetItemInfo(ItemInfo& out info) {
    info.iWeight = -1;
    return true;
  }
}

class item_qsuit : ScriptBasePlayerItemEntity, item_qgeneric {
  void Spawn() {
    m_sModel = "models/quake1/w_suit.mdl";
    m_sSound = "quake1/suit.wav";
    CommonSpawn();
  }

  bool ApplyEffects(CBasePlayer@ pPlayer) {
    pPlayer.pev.renderfx = kRenderFxGlowShell;
    pPlayer.pev.rendercolor.y = 255;
    pPlayer.pev.renderamt = 1;
    pPlayer.pev.flags |= FL_IMMUNE_WATER | FL_IMMUNE_LAVA | FL_IMMUNE_SLIME;
    pPlayer.pev.radsuit_finished = g_Engine.time + 30.0;
    @m_pEndFunc = @g_Scheduler.SetTimeout(this, "RemoveEffects", 30.0);
    return true;
  }

  void RemoveEffects() {
    if (m_pPlayer is null) return;
    m_pPlayer.pev.rendercolor.y = 0;
    if (m_pPlayer.HasNamedPlayerItem("item_qquad") is null && m_pPlayer.HasNamedPlayerItem("item_qinvul") is null) {
      m_pPlayer.pev.renderfx = kRenderFxNone;
      m_pPlayer.pev.renderamt = 0;
    }
    m_pPlayer.pev.flags &= ~(FL_IMMUNE_WATER | FL_IMMUNE_LAVA | FL_IMMUNE_SLIME);
    KillSelf();
  }

  bool GetItemInfo(ItemInfo& out info) {
    info.iWeight = -1;
    return true;
  }
}

class item_qinvis : ScriptBasePlayerItemEntity, item_qgeneric {
  void Spawn() {
    m_sModel = "models/quake1/w_invis.mdl";
    m_sSound = "quake1/invis.wav";
    g_SoundSystem.PrecacheSound("quake1/quad_s.wav");
    CommonSpawn();
  }

  bool ApplyEffects(CBasePlayer@ pPlayer) {
    pPlayer.pev.rendermode = kRenderTransColor;
    pPlayer.pev.renderamt = 1;
    pPlayer.pev.flags |= FL_NOTARGET;
    @m_pEndFunc = @g_Scheduler.SetTimeout(this, "RemoveEffects", 30.0);
    return true;
  }

  void RemoveEffects() {
    if (m_pPlayer is null) return;
    m_pPlayer.pev.rendermode = kRenderNormal;
    m_pPlayer.pev.flags &= ~FL_NOTARGET;
    KillSelf();
  }

  bool GetItemInfo(ItemInfo& out info) {
    info.iWeight = -1;
    return true;
  }
}

mixin class item_qarmor {
  int m_iArmor;

  bool ApplyEffects(CBasePlayer@ pPlayer) {
    if (pPlayer.pev.armorvalue >= m_iArmor) return false;
    pPlayer.pev.armorvalue += m_iArmor;
    if (pPlayer.pev.armorvalue > m_iArmor)
      pPlayer.pev.armorvalue = m_iArmor;
    @m_pEndFunc = @g_Scheduler.SetTimeout(this, "RemoveEffects", 0.1);
    return true;
  }

  void RemoveEffects() {
    if (m_pPlayer is null) return;
    KillSelf();
  }

  bool GetItemInfo(ItemInfo& out info) {
    info.iWeight = -1;
    return true;
  }
}

class item_qarmor1 : ScriptBasePlayerItemEntity, item_qgeneric, item_qarmor {
  void Spawn() {
    m_iArmor = 25;
    m_sModel = "models/quake1/w_armor_g.mdl";
    m_sSound = "quake1/armor.wav";
    CommonSpawn();
  }
}

class item_qarmor2 : ScriptBasePlayerItemEntity, item_qgeneric, item_qarmor {
  void Spawn() {
    m_iArmor = 50;
    m_sModel = "models/quake1/w_armor_y.mdl";
    m_sSound = "quake1/armor.wav";
    CommonSpawn();
  }
}

class item_qarmor3 : ScriptBasePlayerItemEntity, item_qgeneric, item_qarmor {
  void Spawn() {
    m_iArmor = 100;
    m_sModel = "models/quake1/w_armor_r.mdl";
    m_sSound = "quake1/armor.wav";
    CommonSpawn();
  }
}

// backpack
// gotta make this a separate class for now

class item_qbackpack : ScriptBaseEntity {
  CBasePlayerItem@ m_pWeapon = null;
  int m_iAmmoShells;
  int m_iAmmoNails;
  int m_iAmmoRockets;
  int m_iAmmoCells;

  float m_fDeathTime;

  void Spawn() {
    Precache();
    BaseClass.Spawn();

    self.pev.movetype = MOVETYPE_TOSS;
    self.pev.solid = SOLID_TRIGGER;
    g_EntityFuncs.SetModel(self, "models/quake1/w_backpack.mdl");
    g_EntityFuncs.SetSize(self.pev, Vector(-16, -16, 0), Vector(16, 16, 56));

    m_fDeathTime = g_Engine.time + 120.0;
    self.pev.nextthink = g_Engine.time + 0.01;
  }

  void Precache() {
    g_Game.PrecacheModel("models/quake1/w_backpack.mdl");
    g_SoundSystem.PrecacheSound("quake1/ammo.wav");
    g_SoundSystem.PrecacheSound("quake1/weapon.wav");
  }

  void Think() {
    self.pev.angles.y += 1.25;
    if (m_fDeathTime < g_Engine.time)
      Die();
    else
      self.pev.nextthink = g_Engine.time + 0.01;
  }

  void Die() {
    if (m_pWeapon !is null)
      g_EntityFuncs.Remove(m_pWeapon);
    g_EntityFuncs.Remove(self);
  }

  void Touch(CBaseEntity@ pOther) {
    if (pOther is null) return;
    if (!pOther.IsPlayer()) return;
    if (pOther.pev.health <= 0) return;

    int iRemove = 0;
    CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);

    if (m_iAmmoShells > 0 && pPlayer.GiveAmmo(m_iAmmoShells, "buckshot", 100, false) >= 0)
      iRemove = 1;
    if (m_iAmmoNails > 0 && pPlayer.GiveAmmo(m_iAmmoNails, "bolts", 200, false) >= 0)
      iRemove = 1;
    if (m_iAmmoRockets > 0 && pPlayer.GiveAmmo(m_iAmmoRockets, "rockets", 100, false) >= 0)
      iRemove = 1;
    if (m_iAmmoCells > 0 && pPlayer.GiveAmmo(m_iAmmoCells, "uranium", 100, false) >= 0)
      iRemove = 1;

    if (m_pWeapon !is null && pPlayer.HasNamedPlayerItem(m_pWeapon.GetClassname()) is null) {
      pPlayer.GiveNamedItem(m_pWeapon.GetClassname());
      iRemove = 2;
    }

    if (iRemove > 0) {
      g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, iRemove == 1 ? "quake1/ammo.wav" : "quake1/weapon.wav", 1.0, ATTN_NORM);
      Die();
    }
  }
}

item_qbackpack@ q1_SpawnBackpack(CBaseEntity@ pOwner) {
  Vector vecVelocity = Vector(Math.RandomFloat(-100, 100), Math.RandomFloat(-100, 100), 200);
  CBaseEntity@ pPackEnt = q1_ShootCustomProjectile("item_qbackpack", "models/quake1/w_backpack.mdl", 
                                                   pOwner.pev.origin, vecVelocity, 
                                                   g_vecZero, pOwner);
  return cast<item_qbackpack@>(CastToScriptClass(pPackEnt));
}

// fucking schedulers again
// gotta do this AFTER pickup to override the default pickup sound
void q1_ScheduleItemSound(CBasePlayer @pPlayer, string m_sSound) {
  g_Scheduler.SetTimeout("q1_ScheduledItemSound", 0.001, @pPlayer, m_sSound);
}

void q1_ScheduledItemSound(CBasePlayer @pPlayer, string m_sSound) {
  g_SoundSystem.StopSound(pPlayer.edict(), CHAN_ITEM, "items/gunpickup2.wav", true);
  g_SoundSystem.EmitSound(pPlayer.edict(), CHAN_ITEM, m_sSound, 1.0, ATTN_NORM);
}

void q1_RegisterItems() {
  // precache item and ammo models right away
  g_Game.PrecacheModel("models/quake1/w_quad.mdl");
  g_Game.PrecacheModel("models/quake1/w_invul.mdl");
  g_Game.PrecacheModel("models/quake1/w_invis.mdl");
  g_Game.PrecacheModel("models/quake1/w_suit.mdl");
  g_Game.PrecacheModel("models/quake1/w_armor_g.mdl");
  g_Game.PrecacheModel("models/quake1/w_armor_y.mdl");
  g_Game.PrecacheModel("models/quake1/w_armor_r.mdl");
  g_Game.PrecacheModel("models/quake1/w_backpack.mdl");

  g_CustomEntityFuncs.RegisterCustomEntity("item_qquad", "item_qquad");
  g_ItemRegistry.RegisterItem("item_qquad", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qinvul", "item_qinvul");
  g_ItemRegistry.RegisterItem("item_qinvul", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qsuit", "item_qsuit");
  g_ItemRegistry.RegisterItem("item_qsuit", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qinvis", "item_qinvis");
  g_ItemRegistry.RegisterItem("item_qinvis", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qarmor1", "item_qarmor1");
  g_ItemRegistry.RegisterItem("item_qarmor1", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qarmor2", "item_qarmor2");
  g_ItemRegistry.RegisterItem("item_qarmor2", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qarmor3", "item_qarmor3");
  g_ItemRegistry.RegisterItem("item_qarmor3", "quake1/items");
  g_CustomEntityFuncs.RegisterCustomEntity("item_qbackpack", "item_qbackpack");
  g_ItemRegistry.RegisterItem("item_qbackpack", "quake1/items");
}

