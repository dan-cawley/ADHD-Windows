using System;
using System.Linq;
using System.IO;
using System.Collections.Generic;
using System.Globalization;

namespace AdhdWarrior {
 public class Familiar {
  public string Species {get;set;} public int EggStage {get;set;} public int Growth {get;set;}
  public int Level {get;set;} public int XP {get;set;} public int Skill {get;set;} public int Points {get;set;}
  public Familiar() {EggStage=1;Level=1;Points=1;}
 }
 public class BossRecord {public int Index {get;set;} public string Week {get;set;} public string Outcome {get;set;} public int HP {get;set;} }
 public class JourneyState {
  public List<Familiar> Pets {get;set;} public string Active {get;set;} public List<string> Gear {get;set;}
  public int Completions {get;set;} public int BossIndex {get;set;} public int BossHP {get;set;} public int BossMaxHP {get;set;}
  public string Week {get;set;} public List<BossRecord> History {get;set;} public List<string> Journal {get;set;}
  public JourneyState() {Pets=new List<Familiar>{new Familiar {Species="drake"}};Active="drake";Gear=new List<string>();Week="";History=new List<BossRecord>();Journal=new List<string>();}
 }
 public class PetDefinition {
  public string Id,Name; public string[] Art; public int Threshold;
  public PetDefinition(string id,string name,int threshold,params string[] art){Id=id;Name=name;Threshold=threshold;Art=art;}
 }
 public class GearDefinition {
  public string Id,Name,Rarity,Slot,Sheet; public int Tile;
  public GearDefinition(string id,string name,string rarity,string slot,string sheet,int tile){Id=id;Name=name;Rarity=rarity;Slot=slot;Sheet=sheet;Tile=tile;}
  public int BaseBonus {get {return Rarity=="UNCOMMON"?2:Rarity=="RARE"?5:Rarity=="EPIC"?8:Rarity=="UNIQUE"?12:0;}}
  public int Price {get {return Rarity=="COMMON"?20:BaseBonus*20;}}
 }
 public static class Journey {
  public static readonly PetDefinition[] Species={
   new PetDefinition("drake","Arcane Drake",100,"arcane_drake_egg","tiny_purple_drake","winged_arcane_drake","ancient_arcane_dragon"),
   new PetDefinition("basilisk","Silent Basilisk",80,"silent_basilisk_egg","grey_stone_scaled_basilisk","spiked_forest_basilisk","elder_stone_gaze_basilisk"),
   new PetDefinition("gryphon","Storm Gryphon",120,"storm_gryphon_egg","fluffy_gold_gryphon_chick","sleek_sky_gryphon","regal_storm_gryphon"),
   new PetDefinition("hydra","Wild Hydra",140,"wild_hydra_egg","small_green_two_headed_hydra","three_headed_swamp_hydra","colossal_seven_headed_hydra")};
  public static readonly string[] Bosses={"Mire Collosus","Gelatinous Cube","Acidic Jelly","Barbaric Thwamp","Wasting Minotaur","One Armed Skeleton","Blind Mummy","Meat Hummunculus","Vampiric Vines","Ashen Basilisk","Frostbound Chimera","Stormforged Cyclops","Hollow Wyrm","Ember Maw Drake","Moonlit Harpy Queen","Ironroot Treant","Rift Stalker","Crypt Warden"};
  public static Familiar ActivePet(SaveData data){return data.Journey.Pets.Single(p=>p.Species==data.Journey.Active);}
  public static PetDefinition Definition(Familiar p){return Species.Single(s=>s.Id==p.Species);}
  public static int Stage(Familiar p){return p.EggStage<4?0:Math.Min(3,p.Level);}
  public static int PetNextXP(Familiar p){return checked(100+(p.Level-1)*30);}
  public static string WeekKey(DateTime day){return day.Date.AddDays(-(((int)day.DayOfWeek+6)%7)).ToString("yyyy-MM-dd");}
  public static int TargetHP(JourneyState j){return Math.Max(300,(350*(90+j.BossIndex*2)/100)*(100+j.Gear.Count*5)/100);}
  public static bool RefreshWeek(SaveData data,DateTime day) {
   var j=data.Journey;string week=WeekKey(day);
   if(j.Week==""){j.Week=week;j.BossMaxHP=TargetHP(j);j.BossHP=j.BossMaxHP;return true;}
   if(String.CompareOrdinal(week,j.Week)<=0)return false;
   AddHistory(j,"Carried forward");j.Week=week;j.BossHP=Math.Min(j.BossMaxHP,j.BossHP+Math.Max(1,j.BossMaxHP/2));
   Log(j,"A new week begins. "+Bosses[j.BossIndex]+" recovered up to half its health.");return true;
  }
  static void AddHistory(JourneyState j,string outcome){j.History.Insert(0,new BossRecord {Index=j.BossIndex,Week=j.Week,Outcome=outcome,HP=j.BossHP});if(j.History.Count>30)j.History.RemoveAt(30);}
  public static void Log(JourneyState j,string text){j.Journal.Insert(0,text);if(j.Journal.Count>50)j.Journal.RemoveAt(50);}
  public static int GearBonus(SaveData data,Quest q,DateTime day) {
   int total=0;foreach(string id in data.Journey.Gear){var g=GearCatalog.All.Single(x=>x.Id==id);int b=g.BaseBonus;if(b==0)continue;
    if(q.Repeat=="Daily"){if(g.Slot=="ACCESSORY")total++;if(g.Slot=="HEAD")total+=b;if(g.Slot=="CHEST")total+=Math.Max(1,b/2);}
    else {if(g.Slot=="ACCESSORY"||g.Slot=="RING")total++;if(g.Slot=="OFFHAND"&&q.Steps.Count>0)total+=Math.Max(1,b/2);if(g.Slot=="HANDS")total+=Math.Max(1,b-1);if(g.Slot=="WEAPON")total+=b;if(g.Slot=="CHEST")total+=Math.Max(1,b/2);if(g.Slot=="LEGS"&&(q.Steps.Count>=2||(!String.IsNullOrEmpty(q.Due)&&String.CompareOrdinal(q.Due,day.ToString("yyyy-MM-dd"))<=0)))total+=Math.Max(1,b/2);}
    if(g.Rarity=="EPIC")total+=2;if(g.Rarity=="UNIQUE")total+=3;
   }
   var required=new[]{"HEAD","CHEST","HANDS","LEGS","FEET","WEAPON","ACCESSORY"};
   if(GearCatalog.All.Where(g=>data.Journey.Gear.Contains(g.Id)).GroupBy(g=>g.Sheet).Any(set=>required.All(slot=>set.Any(g=>g.Slot==slot))))total+=q.Repeat=="Daily"?8:10;
   return total;
  }
  public static int Bonus(SaveData data,Quest q,DateTime day){var p=ActivePet(data);return GearBonus(data,q,day)+(p.EggStage==4?p.Skill*Stage(p):0);}
  public static void OnCompletion(SaveData data,int awardedXP,DateTime day) {
   RefreshWeek(data,day);var j=data.Journey;var p=ActivePet(data);j.Completions=checked(j.Completions+1);
   if(p.EggStage<4){p.Growth+=20;while(p.Growth>=Definition(p).Threshold&&p.EggStage<4){p.Growth-=Definition(p).Threshold;p.EggStage++;}if(p.EggStage==4){p.Growth=0;Log(j,Definition(p).Name+" hatched! It is now your active companion.");}}
   else {p.XP+=20;while(p.XP>=PetNextXP(p)){p.XP-=PetNextXP(p);p.Level++;p.Points++;Log(j,Definition(p).Name+" reached level "+p.Level+". You gained a skill point.");}}
   j.BossHP=Math.Max(0,j.BossHP-awardedXP);
   if(j.BossHP==0){AddHistory(j,"Defeated");Log(j,"Defeated "+Bosses[j.BossIndex]+"!");AwardGear(j,true);j.BossIndex=(j.BossIndex+1)%Bosses.Length;j.BossMaxHP=TargetHP(j);j.BossHP=j.BossMaxHP;}
   if(j.Completions%6==0)AwardGear(j,false);
  }
  static void AwardGear(JourneyState j,bool highTier){var item=GearCatalog.All.FirstOrDefault(g=>!j.Gear.Contains(g.Id)&&(!highTier||g.Rarity=="RARE"||g.Rarity=="EPIC"||g.Rarity=="UNIQUE"));if(item==null){Log(j,"Collection complete. Your adventure continues!");return;}j.Gear.Add(item.Id);Log(j,"Collected "+item.Name+". Its bonuses apply automatically.");}
  public static void BuyGear(SaveData data,string id){var g=GearCatalog.All.Single(x=>x.Id==id);if(data.Journey.Gear.Contains(id))throw new InvalidOperationException("You already own this item.");if(data.Coins<g.Price)throw new InvalidOperationException("Not enough coins.");data.Coins-=g.Price;data.Journey.Gear.Add(id);Log(data.Journey,"Purchased "+g.Name+".");}
  public static void Adopt(SaveData data,string id){if(!Species.Any(s=>s.Id==id))throw new InvalidOperationException("Unknown familiar.");if(data.Journey.Pets.Any(p=>p.Species==id))throw new InvalidOperationException("You already have this familiar.");if(data.Coins<150)throw new InvalidOperationException("An egg costs 150 coins.");data.Coins-=150;data.Journey.Pets.Add(new Familiar {Species=id});data.Journey.Active=id;Log(data.Journey,"Adopted a "+Species.Single(s=>s.Id==id).Name+" egg.");}
  public static void Train(SaveData data,string id){var p=data.Journey.Pets.Single(x=>x.Species==id);if(p.EggStage<4||p.Points<1)throw new InvalidOperationException("Hatch your familiar and earn a skill point first.");p.Points--;p.Skill++;}
  public static void Validate(JourneyState j) {
   if(j==null||j.Pets==null||j.Pets.Count<1||j.Pets.Count>4||j.Pets.Any(p=>p==null)||j.Pets.Select(p=>p.Species).Distinct().Count()!=j.Pets.Count||!j.Pets.Any(p=>p.Species==j.Active)||j.Gear==null||j.Gear.Count>GearCatalog.All.Length||j.Gear.Distinct().Count()!=j.Gear.Count||j.Gear.Any(id=>!GearCatalog.All.Any(g=>g.Id==id))||j.Completions<0||j.BossIndex<0||j.BossIndex>=Bosses.Length||j.History==null||j.History.Count>30||j.Journal==null||j.Journal.Count>50||j.Journal.Any(x=>x==null||x.Length>1000))throw new InvalidDataException("Invalid adventure data.");
   DateTime d;if(j.Week==null||j.Week!=""&&(!ParseDate(j.Week,out d)||WeekKey(d)!=j.Week)||j.BossHP<0||j.BossHP>j.BossMaxHP||j.BossMaxHP>1000000||j.Week!=""&&(j.BossHP==0||j.BossMaxHP<300))throw new InvalidDataException("Invalid weekly boss data.");
   foreach(var p in j.Pets)if(!Species.Any(s=>s.Id==p.Species)||p.EggStage<1||p.EggStage>4||p.Level<1||p.Level>100000||p.XP<0||p.XP>=PetNextXP(p)||p.Growth<0||p.Growth>=Definition(p).Threshold||p.Points<0||p.Skill<0||(long)p.Points+p.Skill!=p.Level||p.EggStage<4&&(p.Level!=1||p.XP!=0||p.Skill!=0)||p.EggStage==4&&p.Growth!=0)throw new InvalidDataException("Invalid familiar progression.");
   foreach(var h in j.History)if(h==null||h.Index<0||h.Index>=18||h.HP<0||h.HP>1000000||!ParseDate(h.Week,out d)||WeekKey(d)!=h.Week||h.Outcome!="Defeated"&&h.Outcome!="Carried forward")throw new InvalidDataException("Invalid boss history.");
  }
  static bool ParseDate(string text,out DateTime date){return DateTime.TryParseExact(text,"yyyy-MM-dd",CultureInfo.InvariantCulture,DateTimeStyles.None,out date);}
 }
}
