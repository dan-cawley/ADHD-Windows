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
  public static string Date(object v,TimeZoneInfo zone){
   if(v==null)return "";
   if(!(v is int)&&!(v is long)&&!(v is double)&&!(v is decimal))throw new InvalidDataException("Expected a Swift date in seconds since 2001.");
   double seconds=Convert.ToDouble(v,CultureInfo.InvariantCulture);
   if(Double.IsNaN(seconds)||Double.IsInfinity(seconds)||seconds< -3155760000||seconds>6279811200)throw new InvalidDataException("iOS date is outside the supported range.");
   return TimeZoneInfo.ConvertTimeFromUtc(new DateTime(2001,1,1,0,0,0,DateTimeKind.Utc).AddSeconds(seconds),zone).ToString("yyyy-MM-dd");
  }
  public static IosImportResult Parse(string json,TimeZoneInfo zone){
   var root=Obj(new JavaScriptSerializer {MaxJsonLength=16*1024*1024}.DeserializeObject(json));
   if(root.ContainsKey("Version")||!root.ContainsKey("quests")||!root.ContainsKey("coinBalance")||!root.ContainsKey("inventory"))throw new InvalidDataException("This is not a supported iOS export.");
   if(root["quests"]==null||root["coinBalance"]==null||root["inventory"]==null)throw new InvalidDataException("The iOS export has missing progress data.");
   bool rebuild=root.ContainsKey("totalXPEarned");
   if(!rebuild&&!root.ContainsKey("xpEvents"))throw new InvalidDataException("The iOS export is missing its XP history.");
   var data=new SaveData {Coins=Number(root["coinBalance"])};
   var backlog=new HashSet<string>(ArrayValue(Value(root,"backlogQuestIDs")).Select(v=>Text(v)),StringComparer.OrdinalIgnoreCase);
   int completedXP=0;
   foreach(var value in ArrayValue(root["quests"])){
    var source=Obj(value);Guid id;
    string rawID=Text(Value(source,"id"));if(!Guid.TryParse(rawID,out id))throw new InvalidDataException("An iOS quest has an invalid ID.");
    string category=Text(Value(source,"category"),Flag(Value(source,"isSchoolQuest"))?"School":"Life");
    category=CultureInfo.InvariantCulture.TextInfo.ToTitleCase(category.ToLowerInvariant());
    var q=new Quest {Id=id.ToString(),Title=Text(Value(source,"title")),Category=category,XP=Number(Value(source,"xp"),50),Due=Date(Value(source,"dueAt"),zone),Completed=Date(Value(source,"completedAt"),zone),Archived=backlog.Contains(rawID)};
    q.Done=!String.IsNullOrEmpty(q.Completed);
    if(rebuild)q.Repeat=CultureInfo.InvariantCulture.TextInfo.ToTitleCase(Text(Value(source,"recurrence"),"none").ToLowerInvariant());
    int stepXP=0;
    foreach(var rawStep in ArrayValue(Value(source,"subquests"))){var step=Obj(rawStep);bool done=Flag(Value(step,"isCompleted"));q.Steps.Add(new Step {Title=Text(Value(step,"title")),Done=done});if(done)stepXP=checked(stepXP+Math.Max(1,Number(Value(step,"xp"),50)));}
    if(q.Done){q.AwardedXP=checked(q.XP+Number(Value(source,"bonusXP"))+stepXP);completedXP=checked(completedXP+q.AwardedXP);}
    data.Quests.Add(q);
   }
   if(rebuild)data.XP=Number(root["totalXPEarned"]);
   else {data.XP=completedXP;foreach(var raw in ArrayValue(root["xpEvents"]))data.XP=checked(data.XP+Number(Value(Obj(raw),"amount")));}
   int extraCopies=0,otherItems=0;
   foreach(var pair in Obj(root["inventory"])){
    int count=Number(pair.Value);if(count==0)continue;
    if(GearCatalog.All.Any(g=>g.Id==pair.Key)){data.Journey.Gear.Add(pair.Key);extraCopies=checked(extraCopies+count-1);}else otherItems=checked(otherItems+count);
   }
   data.Journey.Completions=Math.Max(data.Quests.Count(q=>q.Done),Number(Value(root,"completionEventsCount")));
   // Validate everything before offering Apply. Never clamp incompatible values silently.
   data=Storage.Decode(Storage.Encode(data));
   string report=(rebuild?"iOS Rebuild export":"iOS legacy export")+"\r\n\r\nWill transfer:\r\n"+data.Quests.Count+" quests ("+data.Quests.Count(q=>q.Done)+" completed; "+data.Quests.Count(q=>q.Archived)+" backlog entries become archived)\r\n"+data.XP+" lifetime XP; "+data.Coins+" coins\r\n"+data.Journey.Gear.Count+" distinct equipment pieces\r\n\r\nLimitations in this preview:\r\n"+
    "Pet and egg progression, boss progress/history, reward claims, streak quests, daily templates, settings, friends and integrations do not transfer. Windows starts a new familiar and boss journey.\r\n"+
    extraCopies+" duplicate equipment copies and "+otherItems+" eggs/other inventory units are not imported.\r\n"+
    "Quest rarity, separate subquest XP, due times, calendar links and other mobile-only metadata are not retained. Completed legacy quest rewards are included in lifetime XP. Active quests use Windows reward rules.\r\n"+
    (rebuild?"Rebuild exports do not contain completed quest dates; reward history is not converted into completed quests.\r\n":"Legacy daily templates are not recreated as recurring quests.\r\n")+
    "Dates use this computer's time zone: "+zone.DisplayName+".\r\n\r\nApplying replaces your Windows progress after saving a recovery backup. Keep the original iOS export for features that do not yet transfer; this app leaves that file unchanged.";
   return new IosImportResult {Data=data,Report=report};
  }
 }
 public partial class MainWindow {
  void ImportIos(){
   using(var picker=new OpenFileDialog {Filter="iOS JSON export|*.json",Title="Preview an iOS export"})if(picker.ShowDialog(this)==DialogResult.OK)try{
    var preview=IosImport.Parse(File.ReadAllText(picker.FileName),TimeZoneInfo.Local);
    using(var dialog=new Form {Text="Review iOS import",Size=new Size(730,670),MinimumSize=new Size(550,450),StartPosition=FormStartPosition.CenterParent}){
     var details=new TextBox {Multiline=true,ReadOnly=true,ScrollBars=ScrollBars.Vertical,Dock=DockStyle.Fill,Text=preview.Report,Font=new Font("Segoe UI",11)};
     var actions=new FlowLayoutPanel {Dock=DockStyle.Bottom,Height=55,FlowDirection=FlowDirection.RightToLeft,Padding=new Padding(8)};
     var cancel=new Button {Text="Cancel",DialogResult=DialogResult.Cancel,AutoSize=true};
     var apply=new Button {Text="Apply partial import",DialogResult=DialogResult.OK,AutoSize=true};
     actions.Controls.Add(cancel);actions.Controls.Add(apply);dialog.Controls.Add(details);dialog.Controls.Add(actions);dialog.CancelButton=cancel;
     if(dialog.ShowDialog(this)!=DialogResult.OK)return;
    }
    Storage.Save(path+".before-ios-import-"+DateTime.Now.ToString("yyyyMMdd-HHmmssfff")+".json",data);
    Change(()=>{data=preview.Data;Journey.RefreshWeek(data,DateTime.Today);},"iOS quests, balances and equipment imported. Recovery backup saved.");
   }catch(Exception ex){MessageBox.Show(this,ex.Message,"Could not import iOS export");}
  }
 }
}
