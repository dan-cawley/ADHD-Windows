using System;
using System.IO;
using System.Linq;

namespace AdhdWarrior {
 public static class JourneyTests {
  static int assertions;
  static void Expect(bool value,string name){if(!value)throw new Exception(name);assertions++;}
  static Quest Complete(SaveData d,DateTime day,int xp=50){var q=new Quest {Title="Adventure test",XP=xp};d.Quests.Add(q);Game.Complete(d,new[]{q},day);return q;}
  static bool Rejects(Action action){try{action();return false;}catch{return true;}}
  public static int Run(string folder) {
   assertions=0;var day=new DateTime(2026,9,14);
   string old="{\"Version\":1,\"XP\":200,\"Coins\":40,\"Quests\":[]}";
   var migrated=Storage.Decode(old);Expect(migrated.Version==3&&migrated.XP==200&&migrated.Coins==40&&migrated.Journey.Pets.Count==1,"V1 migration preserves balances and grants exactly one starter egg");
   var again=Storage.Decode(Storage.Encode(migrated));Expect(again.Journey.Pets.Count==1&&again.Coins==40,"V2 reload cannot duplicate starter rewards");
   Expect(Rejects(()=>Storage.Decode("{\"Version\":2,\"XP\":0,\"Coins\":0,\"Quests\":[]}")),"V2 requires adventure section");
   var data=new SaveData();Journey.RefreshWeek(data,day);Expect(data.Journey.BossHP==315&&data.Journey.Week=="2026-09-14","Initial boss budget and Monday week key");
   for(int i=0;i<14;i++)Complete(data,day);Expect(Journey.ActivePet(data).EggStage==3&&Journey.ActivePet(data).Growth==80,"Egg needs all three growth stages");
   var last=Complete(data,day);var pet=Journey.ActivePet(data);Expect(pet.EggStage==4&&pet.Level==1&&pet.Points==1&&pet.Growth==0,"Egg hatches exactly at threshold");
   string before=Storage.Encode(data);Game.Complete(data,new[]{last},day);Expect(Storage.Encode(data)==before,"Repeated completion cannot duplicate XP, pet growth, gear, boss damage or journal events");
   for(int i=0;i<18;i++)Complete(data,day);Expect(pet.Level==3&&pet.XP==130&&pet.Points==3&&Journey.Stage(pet)==3,"Pet progression carries XP across multiple levels and evolves");
   Journey.Train(data,"drake");Expect(pet.Points==2&&pet.Skill==1,"Training consumes one skill point");
   var ordinary=new Quest {Title="Bonus quest"};Expect(Journey.Bonus(data,ordinary,day)-Journey.GearBonus(data,ordinary,day)==3,"Ascended pet skill scales quest bonus");
   data.Coins=500;Journey.Adopt(data,"basilisk");Expect(data.Coins==350&&data.Journey.Active=="basilisk"&&data.Journey.Pets.Count==2,"Adoption spends earned coins and selects the egg");
   int oldXP=pet.XP;Complete(data,day);Expect(pet.XP==oldXP&&Journey.ActivePet(data).Growth==20,"Only active familiar advances");
   Expect(Rejects(()=>Journey.Adopt(data,"basilisk"))&&data.Journey.Pets.Count==2,"Duplicate adoption rejected");
   Expect(Rejects(()=>Journey.Train(data,"basilisk")),"Unhatched eggs cannot spend skill points");
   var shop=new SaveData {Coins=150};Journey.BuyGear(shop,"standard_2");Expect(shop.Coins==50&&Journey.GearBonus(shop,ordinary,day)==2,"Owned chest gear automatically grants ordinary quest XP");
   Expect(Rejects(()=>Journey.BuyGear(shop,"standard_2"))&&shop.Coins==50,"Cannot pay twice for an owned item");
   Expect(Rejects(()=>Journey.BuyGear(shop,"nightveil_2"))&&shop.Coins==50,"Insufficient balance cannot purchase gear");
   var earned=Complete(shop,day);Expect(earned.AwardedXP==52&&shop.XP==52&&shop.Coins==60,"Quest receipt records bonus XP while coins follow base XP");
   var victory=new SaveData();Journey.RefreshWeek(victory,day);victory.Journey.BossHP=5;var winner=Complete(victory,day);Expect(victory.Journey.BossIndex==1&&victory.Journey.History.Count==1&&victory.Journey.History[0].HP==0,"Victory records history and advances to next boss");
   Expect(victory.Journey.Gear.Count==1&&GearCatalog.All.Single(g=>g.Id==victory.Journey.Gear[0]).Rarity=="RARE","Boss drops rare-or-better gear");
   int hp=victory.Journey.BossHP;Game.Complete(victory,new[]{winner},day);Expect(victory.Journey.BossHP==hp&&victory.Journey.History.Count==1,"Boss victory cannot be replayed");
   var rollover=new SaveData();Journey.RefreshWeek(rollover,day);rollover.Journey.BossHP=20;Journey.RefreshWeek(rollover,day.AddDays(7));Expect(rollover.Journey.BossHP==177&&rollover.Journey.History.Count==1,"New week heals half HP and retains encounter");
   Expect(!Journey.RefreshWeek(rollover,day.AddDays(8))&&!Journey.RefreshWeek(rollover,day)&&rollover.Journey.BossHP==177,"Same week and backward clock changes do not heal repeatedly");
   Expect(Journey.WeekKey(new DateTime(2027,1,1))=="2026-12-28","Week key remains stable across year boundary");
   var drops=new SaveData();for(int i=0;i<6;i++)Complete(drops,day,5);Expect(drops.Journey.Gear.SequenceEqual(new[]{"library_1"}),"Six completions grant a unique collection item");
   string save=Path.Combine(folder,"adventure.json");Storage.Save(save,data);var loaded=Storage.Load(save);Expect(Storage.Encode(loaded)==Storage.Encode(data),"Adventure state round trips including history, skills, receipts and inventory");
   data.Journey.Gear.Add("unknown");Expect(Rejects(()=>Storage.Save(save,data))&&Storage.Encode(Storage.Load(save))==Storage.Encode(loaded),"Invalid gear cannot overwrite an existing save");
   var corrupt=Storage.Decode(Storage.Encode(loaded));corrupt.Journey.Pets[0].Skill=100;Expect(Rejects(()=>Storage.Decode(Storage.Encode(corrupt))),"Invalid skill-point allocation rejected");
   Expect(GearCatalog.All.Length==81&&GearCatalog.All.Select(g=>g.Id).Distinct().Count()==81,"All 81 iOS gear definitions ported with unique IDs");
   foreach(var definition in Journey.Species)foreach(var name in definition.Art)Expect(File.Exists(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"assets",name+".png")),"Familiar artwork packaged: "+name);
   return assertions;
  }
 }
}
