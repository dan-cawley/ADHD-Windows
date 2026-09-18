using System;
using System.Linq;
using System.Collections.Generic;
using System.Globalization;
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
   Check(Journey.GearBonus(d,q,day)==0,"Collected gear does not alter ordinary quest XP");
   q.Repeat="Daily";Check(Journey.GearBonus(d,q,day)==0,"Collected gear does not alter daily quest XP");
   d.Journey.Gear=GearCatalog.All.Where(g=>g.Sheet=="standard").Select(g=>g.Id).ToList();
   q.Repeat="None";int complete=Journey.GearBonus(d,q,day);d.Journey.Gear.Remove("standard_5");Check(complete==0&&Journey.GearBonus(d,q,day)==0,"Complete and partial equipment sets remain cosmetic");
   Check(IosImport.Date(0,TimeZoneInfo.Utc)=="2001-01-01","Swift epoch, not Unix epoch");
   var west=TimeZoneInfo.CreateCustomTimeZone("Test west",TimeSpan.FromHours(-5),"Test west","Test west");
   Check(IosImport.Date(0,west)=="2000-12-31","Swift date converted to chosen local day");
   Check(Rejects(()=>IosImport.Date(1700000000000L,TimeZoneInfo.Utc)),"Millisecond timestamps rejected");
   string currentWeek=DateTime.Today.Year+"-W"+CultureInfo.CurrentCulture.Calendar.GetWeekOfYear(DateTime.Today,CalendarWeekRule.FirstDay,DayOfWeek.Sunday);
   var root=new Dictionary<string,object>{
    {"coinBalance",123},{"xpEvents",new[]{new {amount=25}}},{"inventory",new Dictionary<string,int>{{"standard_1",2},{"egg_silent_basilisk_egg",1},{"egg_fluffy_gold_gryphon_chick",1}}},
    {"quests",new[]{new {id="aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",title="iOS finished quest",category="Home",xp=50,bonusXP=7,completedAt=0,dueAt=0,subquests=new[]{new {title="Step",xp=10,isCompleted=true}}}}},
    {"backlogQuestIDs",new[]{"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"}},{"giftSigningPrivateKeyData","SYNTHETIC_PRIVATE_VALUE"},
    {"selectedPetID","pet-basilisk"},{"selectedEggItemID","egg_fluffy_gold_gryphon_chick"},{"eggLevels",new Dictionary<string,int>{{"egg_fluffy_gold_gryphon_chick",2}}},{"eggProgressByItem",new Dictionary<string,int>{{"egg_fluffy_gold_gryphon_chick",60}}},{"eggHatchesByItem",new Dictionary<string,int>()},{"pets",new[]{
     new {id="pet-basilisk",eggItemID="egg_silent_basilisk_egg",species="Silent Basilisk",level=2,xp=10,unspentSkillPoints=1,questXPSkillLevel=1,streakXPSkillLevel=0,lootChanceSkillLevel=0},
     new {id="pet-duplicate",eggItemID="egg_spiked_forest_basilisk",species="Forest Basilisk",level=1,xp=0,unspentSkillPoints=1,questXPSkillLevel=0,streakXPSkillLevel=0,lootChanceSkillLevel=0}}},
    {"activeWeeklyBossID","acidic_jelly"},{"weeklyBossCurrentHP",200},{"weeklyBossMaxHP",400},{"weeklyBossWeekKey",currentWeek},{"weeklyBossHistory",new[]{new {bossID="gelatinous_cube",bossName="Gelatinous Cube",weekKey="2001-W1",startHP=300,endHP=0,outcome="defeated",date=0}}}};
   var json=new JavaScriptSerializer();var imported=IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc);
   Check(imported.Data.XP==92&&imported.Data.Coins==123&&imported.Data.Quests[0].AwardedXP==67,"Legacy total includes completed base, bonus, completed steps and XP events exactly once");
   Check(imported.Data.Quests[0].Archived&&imported.Data.Quests[0].Done&&imported.Data.Quests[0].Due=="2001-01-01","Completion dates, steps and backlog transfer");
   Check(imported.Data.Journey.Gear.SequenceEqual(new[]{"standard_1"}),"iOS IDs do not receive Android migration");
   Check(imported.Data.Journey.Pets.Count==2&&imported.Data.Journey.Active=="basilisk"&&imported.Data.Journey.Pets[0].QuestSkill==1,"Compatible selected iOS familiar and skills transfer");
   var importedEgg=imported.Data.Journey.Pets.Single(x=>x.Species=="gryphon");Check(importedEgg.EggStage==2&&importedEgg.Growth==90,"Growing egg stage and proportional rarity progress transfer");
   Check(imported.Report.Contains("1 compatible hatched familiars; 1 growing eggs")&&imported.Report.Contains("1 familiars with"),"Preview reports imported pet, egg and duplicate familiar counts");
   Check(imported.Report.Contains("1 duplicate")&&imported.Report.Contains("1 egg units")&&imported.Report.Contains("0 other inventory"),"Preview reports unsupported inventory counts");
   Check(imported.Data.Journey.BossIndex==2&&imported.Data.Journey.BossHP==200&&imported.Data.Journey.BossMaxHP==400&&imported.Data.Journey.Week==Journey.WeekKey(DateTime.Today),"Current matching-week iOS boss identity and HP transfer");
   Check(imported.Data.Journey.History.Count==1&&imported.Data.Journey.History[0].Index==1&&imported.Data.Journey.History[0].Outcome=="Defeated"&&imported.Data.Journey.History[0].Week=="2001-01-01","Boss history uses its timestamp for a stable Windows week");
   Check(imported.Report.Contains("1 current weekly boss states; 1 boss history entries")&&imported.Report.Contains("0 boss records"),"Boss import counts appear in preview");
   Check(!Storage.Encode(imported.Data).Contains("SYNTHETIC_PRIVATE_VALUE")&&!imported.Report.Contains("SYNTHETIC_PRIVATE_VALUE"),"Private integration values are excluded from imported save and preview");
   root["totalXPEarned"]=900;root["quests"]=new[]{new {id="bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",title="Rebuild quest",category="work",xp=50,recurrence="weekly",subquests=new object[0]}};
   imported=IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc);Check(imported.Data.XP==900&&!imported.Data.Quests[0].Done&&imported.Data.Quests[0].Repeat=="Weekly","Rebuild authoritative XP and recurrence imported without inventing completion history");
   root["eggProgressByItem"]=new Dictionary<string,int>{{"egg_fluffy_gold_gryphon_chick",80}};Check(Rejects(()=>IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc)),"Impossible egg progress rejected before Apply");root["eggProgressByItem"]=new Dictionary<string,int>{{"egg_fluffy_gold_gryphon_chick",60}};
   root["eggLevels"]=new Dictionary<string,int>{{"egg_fluffy_gold_gryphon_chick",4}};imported=IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc);Check(imported.Data.Journey.Pets.Count==1&&imported.Report.Contains("2 egg units"),"Ready-to-hatch egg is reported without becoming a pet");root["eggLevels"]=new Dictionary<string,int>{{"egg_fluffy_gold_gryphon_chick",2}};
   root["weeklyBossWeekKey"]="1900-W1";imported=IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc);Check(imported.Data.Journey.Week==""&&imported.Data.Journey.History.Count==1&&imported.Report.Contains("1 boss records"),"Stale or locale-mismatched active boss resets while valid dated history remains");root["weeklyBossWeekKey"]=currentWeek;
   root["coinBalance"]=-1;Check(Rejects(()=>IosImport.Parse(json.Serialize(root),TimeZoneInfo.Utc)),"Invalid balances rejected before Apply");
   Check(Rejects(()=>IosImport.Parse("{}",TimeZoneInfo.Utc)),"Unrecognized JSON rejected");
   return count;
  }
 }
}
