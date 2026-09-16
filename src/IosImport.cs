using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Globalization;
using System.Web.Script.Serialization;
using System.Windows.Forms;
using System.Drawing;

namespace AdhdWarrior {
 public class IosImportResult {public SaveData Data;public string Report;}
 public static class IosImport {
  static object Value(Dictionary<string,object> o,string key){object v;return o.TryGetValue(key,out v)?v:null;}
  static Dictionary<string,object> Obj(object v){var o=v as Dictionary<string,object>;if(o==null)throw new InvalidDataException("Expected an iOS object.");return o;}
  static object[] ArrayValue(object v){if(v==null)return new object[0];var a=v as object[];if(a==null)throw new InvalidDataException("Expected an iOS list.");return a;}
  static int Number(object v,int fallback=0){if(v==null)return fallback;if(!(v is int)&&!(v is long)&&!(v is decimal))throw new InvalidDataException("Invalid iOS numeric value.");decimal n=Convert.ToDecimal(v);if(n<0||n>Int32.MaxValue||n!=Math.Truncate(n))throw new InvalidDataException("Invalid iOS numeric value.");return (int)n;}
  static string Text(object v,string fallback=""){if(v==null)return fallback;if(!(v is string))throw new InvalidDataException("Invalid iOS text.");return (string)v;}
  static bool Flag(object v){if(v==null)return false;if(!(v is bool))throw new InvalidDataException("Invalid iOS completion flag.");return (bool)v;}
  static string PetFamily(string species,string egg){string value=(species+" "+egg).ToLowerInvariant();if(value.Contains("basilisk"))return "basilisk";if(value.Contains("gryphon"))return "gryphon";if(value.Contains("hydra"))return "hydra";if(value.Contains("drake")||value.Contains("dragon"))return "drake";return "";}
  static Dictionary<string,object> DictionaryValue(object v){return v==null?new Dictionary<string,object>():Obj(v);}
  static int EggThreshold(string id){string value=id.ToLowerInvariant();if(value.Contains("ancient")||value.Contains("colossal")||value.Contains("elder"))return 140;if(value.Contains("three_headed")||value.Contains("wild_hydra")||value.Contains("regal"))return 120;if(value.Contains("arcane")||value.Contains("storm")||value.Contains("spiked"))return 100;return 80;}
  static string BossKey(string value){return new string((value??"").ToLowerInvariant().Where(Char.IsLetterOrDigit).ToArray());}
  static int BossIndex(string value){string key=BossKey(value);for(int i=0;i<Journey.Bosses.Length;i++)if(BossKey(Journey.Bosses[i])==key)return i;return -1;}
  static HashSet<string> CurrentMobileWeekKeys(DateTime day){var calendar=CultureInfo.CurrentCulture.Calendar;return new HashSet<string>{day.Year+"-W"+calendar.GetWeekOfYear(day,CalendarWeekRule.FirstDay,DayOfWeek.Sunday),day.Year+"-W"+calendar.GetWeekOfYear(day,CalendarWeekRule.FirstFourDayWeek,DayOfWeek.Monday)};}
  public static string Date(object v,TimeZoneInfo zone){
   if(v==null)return "";
   if(!(v is int)&&!(v is long)&&!(v is double)&&!(v is decimal))throw new InvalidDataException("Expected a Swift date in seconds since 2001.");
   double seconds=Convert.ToDouble(v,CultureInfo.InvariantCulture);
   if(Double.IsNaN(seconds)||Double.IsInfinity(seconds)||seconds< -3155760000||seconds>6279811200)throw new InvalidDataException("iOS date is outside the supported range.");
   return TimeZoneInfo.ConvertTimeFromUtc(new DateTime(2001,1,1,0,0,0,DateTimeKind.Utc).AddSeconds(seconds),zone).ToString("yyyy-MM-dd");
  }
  static string Time(object v,string text,TimeZoneInfo zone){if(v!=null){double seconds=Convert.ToDouble(v,CultureInfo.InvariantCulture);return TimeZoneInfo.ConvertTimeFromUtc(new DateTime(2001,1,1,0,0,0,DateTimeKind.Utc).AddSeconds(seconds),zone).ToString("HH:mm");}DateTime parsed;return DateTime.TryParse(text,CultureInfo.CurrentCulture,DateTimeStyles.AllowWhiteSpaces,out parsed)?parsed.ToString("HH:mm"):"";}
  public static IosImportResult Parse(string json,TimeZoneInfo zone){
   var root=Obj(new JavaScriptSerializer {MaxJsonLength=16*1024*1024}.DeserializeObject(json));
   if(root.ContainsKey("Version")||!root.ContainsKey("quests")||!root.ContainsKey("coinBalance")||!root.ContainsKey("inventory"))throw new InvalidDataException("This is not a supported iOS export.");
   if(root["quests"]==null||root["coinBalance"]==null||root["inventory"]==null)throw new InvalidDataException("The iOS export has missing progress data.");
   bool rebuild=root.ContainsKey("totalXPEarned");
   if(!rebuild&&!root.ContainsKey("xpEvents"))throw new InvalidDataException("The iOS export is missing its XP history.");
   var data=new SaveData {Coins=Number(root["coinBalance"]),DisplayName=Text(Value(root,"myDisplayName"),"Player")};if(String.IsNullOrWhiteSpace(data.DisplayName))data.DisplayName="Boggins";
   var backlog=new HashSet<string>(ArrayValue(Value(root,"backlogQuestIDs")).Select(v=>Text(v)),StringComparer.OrdinalIgnoreCase);
   int completedXP=0;
   foreach(var value in ArrayValue(root["quests"])){
    var source=Obj(value);Guid id;
    string rawID=Text(Value(source,"id"));if(!Guid.TryParse(rawID,out id))throw new InvalidDataException("An iOS quest has an invalid ID.");
    string category=Text(Value(source,"category"),Flag(Value(source,"isSchoolQuest"))?"School":"Life");
    category=CultureInfo.InvariantCulture.TextInfo.ToTitleCase(category.ToLowerInvariant());
    var q=new Quest {Id=id.ToString(),Title=Text(Value(source,"title")),Category=category,XP=Number(Value(source,"xp"),50),Due=Date(Value(source,"dueAt"),zone),DueTime=Time(Value(source,"dueAt"),Text(Value(source,"dueTimeText")),zone),Completed=Date(Value(source,"completedAt"),zone),Archived=backlog.Contains(rawID),DailyTemplateId=Text(Value(source,"dailyTemplateID")),GeneratedDay=Text(Value(source,"generatedDayKey"))};
    q.Rarity=CultureInfo.InvariantCulture.TextInfo.ToTitleCase(Text(Value(source,"rarity"),"Common").Trim().ToLowerInvariant());if(q.Rarity=="Legendary")q.Rarity="Unique";
    q.Done=!String.IsNullOrEmpty(q.Completed);
    if(rebuild)q.Repeat=CultureInfo.InvariantCulture.TextInfo.ToTitleCase(Text(Value(source,"recurrence"),"none").ToLowerInvariant());else if(!q.Done&&!String.IsNullOrEmpty(Text(Value(source,"dailyTemplateID"))))q.Repeat="Daily";
    if(!String.IsNullOrEmpty(q.DailyTemplateId)&&!String.IsNullOrEmpty(q.GeneratedDay))q.Repeat="None";else {q.DailyTemplateId="";q.GeneratedDay="";}
    int stepXP=0;
    foreach(var rawStep in ArrayValue(Value(source,"subquests"))){var step=Obj(rawStep);bool done=Flag(Value(step,"isCompleted"));q.Steps.Add(new Step {Title=Text(Value(step,"title")),Done=done});if(done)stepXP=checked(stepXP+Math.Max(1,Number(Value(step,"xp"),50)));}
    if(q.Done){q.AwardedXP=checked(q.XP+Number(Value(source,"bonusXP"))+stepXP);completedXP=checked(completedXP+q.AwardedXP);}
    data.Quests.Add(q);
   }
   int streaksImported=0;
   foreach(var value in ArrayValue(Value(root,"streakQuests"))){
    var source=Obj(value);Guid id;string rawID=Text(Value(source,"id"));if(!Guid.TryParse(rawID,out id))throw new InvalidDataException("An iOS streak quest has an invalid ID.");
    var streak=new StreakQuest {Id=id.ToString(),Title=Text(Value(source,"title")),Cadence=Streaks.NormalizeCadence(Text(Value(source,"cadenceText"),"Daily")),XP=Number(Value(source,"xpPerCompletion"),15),Total=Number(Value(source,"totalCompletions")),Current=Number(Value(source,"currentStreak")),Best=Number(Value(source,"bestStreak")),LastCompleted=Date(Value(source,"lastCompletedAt"),zone)};
    data.StreakQuests.Add(streak);streaksImported++;
   }
   if(rebuild)data.XP=Number(root["totalXPEarned"]);
   else {data.XP=completedXP;foreach(var raw in ArrayValue(root["xpEvents"]))data.XP=checked(data.XP+Number(Value(Obj(raw),"amount")));}
   int extraCopies=0,otherItems=0;var inventory=Obj(root["inventory"]);
   foreach(var pair in inventory){
    int count=Number(pair.Value);if(count==0)continue;
    if(GearCatalog.All.Any(g=>g.Id==pair.Key)){data.Journey.Gear.Add(pair.Key);extraCopies=checked(extraCopies+count-1);}else if(!pair.Key.StartsWith("egg_"))otherItems=checked(otherItems+count);
   }
   string importedAvatar=Identity.FromIosAsset(Text(Value(root,"preferredAvatarAssetName")));if(Identity.Unlocked(data,Identity.Avatars.Single(x=>x.Id==importedAvatar)))data.AvatarSet=importedAvatar;
   int templatesImported=0,rewardsImported=0,rewardsSkipped=0;
   if(root.ContainsKey("dailyQuestTemplates")){
    data.DailyTemplates.Clear();foreach(var raw in ArrayValue(Value(root,"dailyQuestTemplates"))){var source=Obj(raw);Guid id;string rawID=Text(Value(source,"id"));if(!Guid.TryParse(rawID,out id))throw new InvalidDataException("An iOS daily template has an invalid ID.");var weekdays=ArrayValue(Value(source,"activeWeekdays")).Select(x=>Number(x)).Where(x=>x>=1&&x<=7).Distinct().ToList();if(weekdays.Count==0)weekdays=Enumerable.Range(1,7).ToList();string window=Text(Value(source,"window"),"Morning");window=CultureInfo.InvariantCulture.TextInfo.ToTitleCase(window.ToLowerInvariant());data.DailyTemplates.Add(new DailyTemplate {Id=id.ToString(),Title=Text(Value(source,"title")),XP=Math.Max(5,Number(Value(source,"xp"),10)),Enabled=Value(source,"isEnabled")==null||Flag(Value(source,"isEnabled")),Weekdays=weekdays,Window=window});templatesImported++;}
    data.AutoGenerateDaily=Value(root,"autoGenerateDailyQuests")==null||Flag(Value(root,"autoGenerateDailyQuests"));
   }else {data.DailyTemplates.Clear();data.AutoGenerateDaily=false;}
   var pendingGear=new HashSet<string>();foreach(var raw in ArrayValue(Value(root,"pendingRewards"))){var source=Obj(raw);Guid id;string rawID=Text(Value(source,"id")),gearID=Text(Value(source,"lootItemID"));if(!Guid.TryParse(rawID,out id)||!GearCatalog.All.Any(g=>g.Id==gearID)||data.Journey.Gear.Contains(gearID)||!pendingGear.Add(gearID)){rewardsSkipped++;continue;}data.PendingRewards.Add(new PendingReward {Id=id.ToString(),GearId=gearID,Source=Text(Value(source,"sourceText"),"iOS reward")});rewardsImported++;}
   data.ClaimedMilestones=ArrayValue(Value(root,"claimedConsistencyMilestones")).Select(x=>Number(x)).Where(x=>DailyTemplatesEngine.Milestones.Contains(x)).Distinct().ToList();
   int petsImported=0,petConflicts=0;var selected=Text(Value(root,"selectedPetID"));var petIDs=new Dictionary<string,string>();var families=new HashSet<string>();var importedPets=new List<Familiar>();
   foreach(var rawPet in ArrayValue(Value(root,"pets"))){
    var mobile=Obj(rawPet);string family=PetFamily(Text(Value(mobile,"species")),Text(Value(mobile,"eggItemID")));if(family==""||!families.Add(family)){petConflicts++;continue;}
    var pet=new Familiar {Name=Text(Value(mobile,"name")),Species=family,EggStage=4,Level=Number(Value(mobile,"level"),1),XP=Number(Value(mobile,"xp")),Points=Number(Value(mobile,"unspentSkillPoints"),1),QuestSkill=Number(Value(mobile,"questXPSkillLevel")),StreakSkill=Number(Value(mobile,"streakXPSkillLevel")),LootSkill=Number(Value(mobile,"lootChanceSkillLevel"))};
    importedPets.Add(pet);petIDs[Text(Value(mobile,"id"))]=family;petsImported++;
   }
   int eggsImported=0,eggUnitsSkipped=0;var selectedEgg=Text(Value(root,"selectedEggItemID"));var eggIDs=new Dictionary<string,string>();var eggLevels=DictionaryValue(Value(root,"eggLevels"));var eggProgress=DictionaryValue(Value(root,"eggProgressByItem"));var eggHatches=DictionaryValue(Value(root,"eggHatchesByItem"));
   foreach(var pair in inventory.Where(x=>x.Key.StartsWith("egg_"))){
    int available=Math.Max(0,Number(pair.Value)-Number(Value(eggHatches,pair.Key)));if(available==0)continue;string family=PetFamily("",pair.Key);int stage=Number(Value(eggLevels,pair.Key),1),progress=Number(Value(eggProgress,pair.Key)),sourceThreshold=EggThreshold(pair.Key);
    if(progress>=sourceThreshold)throw new InvalidDataException("An iOS egg has invalid growth progress.");
    if(family==""||stage<1||stage>=4||!families.Add(family)){eggUnitsSkipped=checked(eggUnitsSkipped+available);continue;}
    int targetThreshold=Journey.Species.Single(x=>x.Id==family).Threshold;var egg=new Familiar {Species=family,EggStage=stage,Growth=progress*targetThreshold/sourceThreshold};importedPets.Add(egg);eggIDs[pair.Key]=family;eggsImported++;eggUnitsSkipped=checked(eggUnitsSkipped+available-1);
   }
   if(importedPets.Count>0){data.Journey.Pets=importedPets;string active;if(petIDs.TryGetValue(selected,out active)||eggIDs.TryGetValue(selectedEgg,out active))data.Journey.Active=active;else data.Journey.Active=importedPets[0].Species;}
   int bossStateImported=0,bossEntriesImported=0,bossEntriesSkipped=0;string bossID=Text(Value(root,rebuild?"activeBossID":"activeWeeklyBossID"));if(bossID=="")bossID=Text(Value(root,"activeBossID"));if(bossID=="")bossID=Text(Value(root,"activeWeeklyBossID"));
   if(bossID!=""){
    int index=BossIndex(bossID),hp=Number(Value(root,"weeklyBossCurrentHP")),maxHP=Number(Value(root,"weeklyBossMaxHP"));string mobileWeek=Text(Value(root,"weeklyBossWeekKey"));
    if(index>=0&&hp>0&&maxHP>=300&&hp<=maxHP&&maxHP<=1000000&&CurrentMobileWeekKeys(DateTime.Today).Contains(mobileWeek)){data.Journey.BossIndex=index;data.Journey.BossHP=hp;data.Journey.BossMaxHP=maxHP;data.Journey.Week=Journey.WeekKey(DateTime.Today);bossStateImported=1;}else bossEntriesSkipped++;
   }
   foreach(var rawHistory in ArrayValue(Value(root,"weeklyBossHistory"))){
    if(data.Journey.History.Count>=30){bossEntriesSkipped++;continue;}var mobile=Obj(rawHistory);int index=BossIndex(Text(Value(mobile,"bossID")));if(index<0)index=BossIndex(Text(Value(mobile,"bossName")));string outcome=Text(Value(mobile,"outcome")).ToLowerInvariant();int hp=Number(Value(mobile,"endHP"));DateTime encounter;
    if(index<0||(outcome!="defeated"&&outcome!="survived")||hp>1000000||!DateTime.TryParseExact(Date(Value(mobile,"date"),zone),"yyyy-MM-dd",CultureInfo.InvariantCulture,DateTimeStyles.None,out encounter)){bossEntriesSkipped++;continue;}
    data.Journey.History.Add(new BossRecord {Index=index,Week=Journey.WeekKey(encounter),Outcome=outcome=="defeated"?"Defeated":"Carried forward",HP=hp});bossEntriesImported++;
   }
   data.Journey.Completions=Math.Max(data.Quests.Count(q=>q.Done),Number(Value(root,"completionEventsCount")));
   // Validate everything before offering Apply. Never clamp incompatible values silently.
   data=Storage.Decode(Storage.Encode(data));
   string report=(rebuild?"iOS Rebuild export":"iOS legacy export")+"\r\n\r\nWill transfer:\r\nCharacter name, compatible avatar theme, and familiar names\r\n"+data.Quests.Count+" quests ("+data.Quests.Count(q=>q.Done)+" completed; "+data.Quests.Count(q=>q.Archived)+" backlog entries become archived)\r\n"+streaksImported+" streak quests with cadence and progress\r\n"+templatesImported+" daily templates; "+rewardsImported+" pending rewards\r\n"+data.XP+" lifetime XP; "+data.Coins+" coins\r\n"+data.Journey.Gear.Count+" distinct equipment pieces\r\n"+petsImported+" compatible hatched familiars; "+eggsImported+" growing eggs\r\n"+bossStateImported+" current weekly boss states; "+bossEntriesImported+" boss history entries\r\n\r\nLimitations in this preview:\r\n"+
    rewardsSkipped+" pending rewards are skipped because their equipment is unsupported, already owned, duplicated, or malformed.\r\n"+
    bossEntriesSkipped+" boss records are reset or skipped because their identity, HP, date, history limit or locale-dependent current-week label cannot be represented safely.\r\n"+
    petConflicts+" familiars with an unsupported or duplicate Windows family are not imported. Familiar names and exact mobile evolution stages are not retained.\r\n"+
    eggUnitsSkipped+" egg units are not imported because Windows supports one familiar per family and cannot yet represent stage-4 ready eggs. Egg growth is proportionally translated between iOS rarity and Windows family thresholds.\r\n"+
    extraCopies+" duplicate equipment copies and "+otherItems+" other inventory units are not imported.\r\n"+
    "Separate subquest XP, calendar links and other mobile-only metadata are not retained. Completed legacy quest rewards are included in lifetime XP. Active quests use Windows reward rules.\r\n"+
    (rebuild?"Rebuild exports do not contain completed quest dates; reward history is not converted into completed quests.\r\n":"Legacy active daily-template quests retain their template identity when present.\r\n")+
    "Dates use this computer's time zone: "+zone.DisplayName+".\r\n\r\nApplying replaces your Windows progress after saving a recovery backup. Keep the original iOS export for features that do not yet transfer; this app leaves that file unchanged.";
   return new IosImportResult {Data=data,Report=report};
  }
 }
 public partial class MainWindow {
  void ImportIos(){
   using(var picker=new OpenFileDialog {Filter="iOS JSON export|*.json",Title="Preview an iOS export"})if(picker.ShowDialog(this)==DialogResult.OK)try{
    var preview=IosImport.Parse(File.ReadAllText(picker.FileName),TimeZoneInfo.Local);
    using(var dialog=new Form {Text="Review iOS import",Size=new Size(730,670),MinimumSize=new Size(550,450),StartPosition=FormStartPosition.CenterParent,BackColor=Theme.Canvas,ForeColor=Theme.Text}){
     var details=new TextBox {Multiline=true,ReadOnly=true,ScrollBars=ScrollBars.Vertical,Dock=DockStyle.Fill,Text=preview.Report,Font=new Font("Segoe UI",11)};
     Theme.StyleInput(details);
     var actions=new FlowLayoutPanel {Dock=DockStyle.Bottom,Height=55,FlowDirection=FlowDirection.RightToLeft,Padding=new Padding(8)};
     var cancel=new ThemedButton {Text="Cancel",DialogResult=DialogResult.Cancel,AutoSize=true};
     var apply=new ThemedButton {Text="Apply partial import",DialogResult=DialogResult.OK,AutoSize=true};
     Theme.StyleButton(cancel);Theme.StyleButton(apply,true);actions.Controls.Add(cancel);actions.Controls.Add(apply);dialog.Controls.Add(details);dialog.Controls.Add(actions);dialog.CancelButton=cancel;
     if(dialog.ShowDialog(this)!=DialogResult.OK)return;
    }
    Storage.Save(path+".before-ios-import-"+DateTime.Now.ToString("yyyyMMdd-HHmmssfff")+".json",data);
    Change(()=>{data=preview.Data;Journey.RefreshWeek(data,DateTime.Today);},"iOS quests, streaks, balances and equipment imported. Recovery backup saved.");
   }catch(Exception ex){MessageBox.Show(this,ex.Message,"Could not import iOS export");}
  }
 }
}
