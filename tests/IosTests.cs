using System;
using System.Linq;
using System.Collections.Generic;
using System.Web.Script.Serialization;
namespace AdhdWarrior {
 public static class IosTests {
  static int count;
  static void Check(bool ok,string text){if(!ok)throw new Exception(text);count++;}
  static bool Rejects(Action action){try{action();return false;}catch{return true;}}
  public static int Run(){
   count=0;var day=new DateTime(2026,9,14);
   var old=new SaveData {Version=2};old.Journey.Gear.AddRange(new[]{"standard_1","arcanist_1","gnome_3","micah_2","micah_6","stacy_2","stacy_5","stacy_6"});
   var upgraded=Storage.Decode(Storage.Encode(old));
   Check(upgraded.Journey.Gear.SequenceEqual(new[]{"standard_clothes_1","standard_1","garden_gnome_3","micah_4","micah_9","stacy_4","stacy_7","stacy_8"}),"V2 identities migrate by original equipment slot");
   Check(Storage.Encode(Storage.Decode(Storage.Encode(upgraded)))==Storage.Encode(upgraded),"V3 reload does not remap IDs a second time");
   Check(GearCatalog.All.Single(g=>g.Id=="micah_2").Slot=="RING"&&GearCatalog.All.Single(g=>g.Id=="stacy_9").Rarity=="EPIC","iOS exceptional slots and rarity preserved");
   var d=new SaveData();d.Journey.Gear.AddRange(new[]{"standard_7","standard_8","standard_9"});
   var q=new Quest {Title="Steps",Steps=new List<Step>{new Step {Title="One"}}};
   Check(Journey.GearBonus(d,q,day)==6,"Offhand, accessory and ring bonuses plus epic piece bonus");
   q.Repeat="Daily";Check(Journey.GearBonus(d,q,day)==3,"Daily accessory and epic bonus");
   d.Journey.Gear=GearCatalog.All.Where(g=>g.Sheet=="standard").Select(g=>g.Id).ToList();
   q.Repeat="None";int complete=Journey.GearBonus(d,q,day);d.Journey.Gear.Remove("standard_5");Check(complete-Journey.GearBonus(d,q,day)==10,"Full set ordinary bonus requires feet");
   Check(IosImport.Date(0,TimeZoneInfo.Utc)=="2001-01-01","Swift epoch, not Unix epoch");
   var west=TimeZoneInfo.CreateCustomTimeZone("Test west",TimeSpan.FromHours(-5),"Test west","Test west");
   Check(IosImport.Date(0,west)=="2000-12-31","Swift date converted to chosen local day");
   Check(Rejects(()=>IosImport.Date(1700000000000L,TimeZoneInfo.Utc)),"Millisecond timestamps rejected");
   var root=new Dictionary<string,object>{
    {"coinBalance",123},{"xpEvents",new[]{new {amount=25}}},{"inventory",new Dictionary<string,int>{{"standard_1",2},{"egg_silent_basilisk_egg",1}}},
    {"quests",new[]{new {id="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",title="iOS finished quest",category="Home",xp=50,bonusXP=7,completedAt=0,dueAt=0,subquests=new[]{new {title="Step",xp=10,isCompleted=true}}}}},
    {"backlogQuestIDs",new[]{"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}},{"giftSigningPrivateKeyData","SYNTHETIC_PRIVATE_VALUE"}};
   var json=new JavaScriptSerializer();var imported=IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc);
   Check(imported.Data.XP==92&&imported.Data.Coins==123&&imported.Data.Quests[0].AwardedXP==67,"Legacy total includes completed base, bonus, completed steps and XP events exactly once");
   Check(imported.Data.Quests[0].Archived&&imported.Data.Quests[0].Done&&imported.Data.Quests[0].Due=="2001-01-01","Completion dates, steps and backlog transfer");
   Check(imported.Data.Journey.Gear.SequenceEqual(new[]{"standard_1"}),"iOS IDs do not receive Android migration");
   Check(imported.Report.Contains("1 duplicate")&&imported.Report.Contains("1 eggs/other"),"Preview reports unsupported inventory counts");
   Check(!Storage.Encode(imported.Data).Contains("SYNTHETIC_PRIVATE_VALUE")&&!imported.Report.Contains("SYNTHETIC_PRIVATE_VALUE"),"Private integration values are excluded from imported save and preview");
   root["totalXPEarned"]=900;root["quests"]=new[]{new {id="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",title="Rebuild quest",category="work",xp=50,recurrence="weekly",subquests=new object[0]}};
   imported=IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc);Check(imported.Data.XP==900&&!imported.Data.Quests[0].Done&&imported.Data.Quests[0].Repeat=="Weekly","Rebuild authoritative XP and recurrence imported without inventing completion history");
   root["coinBalance"]=-1;Check(Rejects(()=>IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc)),"Invalid balances rejected before Apply");
   Check(Rejects(()=>IosImport.Parse("{}",TimeZoneInfo.Utc)),"Unrecognized JSON rejected");
   return count;
  }
 }
}
