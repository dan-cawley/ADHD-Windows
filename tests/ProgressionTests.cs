using System;
using System.Linq;
namespace AdhdWarrior {
 public static class ProgressionTests {
  static int count;
  static void Check(bool ok,string message){if(!ok)throw new Exception(message);count++;}
  public static int Run(){
   count=0;
   for(int i=1;i<Progression.Thresholds.Length;i++){int xp=Progression.Thresholds[i];Check(Progression.Level(xp-1)==i&&Progression.Level(xp)==i+1,"Level threshold boundary "+xp);}
   Check(Progression.Level(Int32.MaxValue)==20&&Progression.Remaining(Int32.MaxValue)==0&&Progression.Current(Int32.MaxValue)==1&&Progression.Span(Int32.MaxValue)==1,"Level cap is stable without overflow");
   Check(Progression.Remaining(300)==600&&Progression.Current(450)==150&&Progression.Span(450)==600,"Level bar uses current level interval");
   Check(Progression.Rarities.Select(Progression.QuestXP).SequenceEqual(new[]{50,75,100,150,225}),"iOS rarity rewards");
   var old=new SaveData {Version=3,XP=1200,Coins=99};old.Quests.Add(new Quest {Title="Existing custom reward",XP=135});
   var migrated=Storage.Decode(Storage.Encode(old).Replace("\"Rarity\":\"Common\",",""));
   Check(migrated.Version==12&&migrated.Quests[0].Rarity=="Common"&&migrated.Quests[0].XP==135&&migrated.XP==1200&&migrated.Coins==99,"Older saves preserve balances and custom quest rewards");
   var oldPet=new SaveData {Version=4};oldPet.Journey.Pets[0].EggStage=4;oldPet.Journey.Pets[0].Level=3;oldPet.Journey.Pets[0].Points=1;oldPet.Journey.Pets[0].Skill=2;
   var petMigrated=Storage.Decode(Storage.Encode(oldPet));Check(petMigrated.Journey.Pets[0].Skill==0&&petMigrated.Journey.Pets[0].QuestSkill==2&&petMigrated.Journey.Pets[0].Points==1,"Generic Windows pet skill migrates to iOS Quest XP skill");
   var day=new DateTime(2026,9,15);var data=new SaveData();var q=new Quest {Title="Recurring epic",Rarity="Epic",Repeat="Weekly",XP=175};data.Quests.Add(q);Game.Complete(data,new[]{q},day);
   Check(data.Quests[1].Rarity=="Epic"&&data.Quests[1].XP==175,"Recurring quest preserves rarity and custom XP");
   data.Journey.Gear.AddRange(new[]{"standard_5","standard_7","standard_8","standard_9"});
   var unique=new Quest {Title="Unique task",Rarity="Unique"};Check(Journey.GearBonus(data,unique,day)==13,"Unique quest gets feet, offhand, accessory and flat epic bonuses");
   unique.Repeat="Daily";Check(Journey.GearBonus(data,unique,day)==3,"Daily slot rules precede unique slot rules as in iOS");
   string json="{\"quests\":[{\"id\":\"aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa\",\"title\":\"Imported legendary\",\"category\":\"Life\",\"rarity\":\"legendary\",\"xp\":225}],\"xpEvents\":[],\"coinBalance\":0,\"inventory\":{}}";
   Check(IosImport.Parse(json,TimeZoneInfo.Utc).Data.Quests[0].Rarity=="Unique","iOS legendary alias maps to Unique");
   bool rejected=false;try{data.Quests[0].Rarity="Invalid";Storage.Decode(Storage.Encode(data));}catch{rejected=true;}Check(rejected,"Unknown rarity cannot corrupt a Windows save");
   return count;
  }
 }
}
