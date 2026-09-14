using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Web.Script.Serialization;

namespace AdhdWarrior {
 public class Step { public string Title {get;set;} public bool Done {get;set;} }
 public class Quest {
  public string Id {get;set;} public string Title {get;set;} public string Category {get;set;}
  public string Due {get;set;} public string Repeat {get;set;} public int XP {get;set;}
  public bool Done {get;set;} public bool Archived {get;set;} public string Completed {get;set;}
  public List<Step> Steps {get;set;}
  public Quest() { Id=Guid.NewGuid().ToString(); Title=""; Category="Life"; Due=""; Repeat="None"; XP=50; Steps=new List<Step>(); }
 }
 public class SaveData {
  public int Version {get;set;} public int XP {get;set;} public int Coins {get;set;} public List<Quest> Quests {get;set;}
  public SaveData() {Version=1; Quests=new List<Quest>();}
 }
 public static class Game {
  public static int Complete(SaveData data, IEnumerable<Quest> quests, DateTime today) {
   int total=0;
   foreach(var q in quests.ToList()) {
    if(q.Done || q.Archived) continue;
    q.Done=true; q.Completed=today.ToString("yyyy-MM-dd"); foreach(var s in q.Steps) s.Done=true;
    total=checked(total+q.XP); data.Coins=checked(data.Coins+q.XP/5);
    if(q.Repeat!="None") {
     DateTime due; if(!DateTime.TryParseExact(q.Due,"yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture,System.Globalization.DateTimeStyles.None,out due)) due=today;
     if(due<today) due=today;
     data.Quests.Add(new Quest { Title=q.Title,Category=q.Category,Due=due.AddDays(q.Repeat=="Daily"?1:7).ToString("yyyy-MM-dd"),Repeat=q.Repeat,XP=q.XP,Steps=q.Steps.Select(s=>new Step {Title=s.Title}).ToList() });
    }
   }
   data.XP=checked(data.XP+total); return total;
  }
  public static int Streak(SaveData data, DateTime today) {
   var days=new HashSet<string>(data.Quests.Where(q=>q.Done).Select(q=>q.Completed));
   if(!days.Contains(today.ToString("yyyy-MM-dd"))) today=today.AddDays(-1);
   int count=0; while(days.Contains(today.ToString("yyyy-MM-dd"))) {count++;today=today.AddDays(-1);} return count;
  }
 }
 public static class Storage {
  static JavaScriptSerializer Json() {return new JavaScriptSerializer {MaxJsonLength=16*1024*1024};}
  public static string Encode(SaveData data) {return Json().Serialize(data);}
  public static SaveData Decode(string json) {
   var header=Json().DeserializeObject(json) as Dictionary<string,object>;
   if(header==null || !new[]{"Version","XP","Coins","Quests"}.All(header.ContainsKey)) throw new InvalidDataException("This is not a Windows backup. Required fields are missing.");
   var data=Json().Deserialize<SaveData>(json);
   if(data==null || data.Version!=1 || data.Quests==null || data.XP<0 || data.Coins<0 || data.Quests.Count>100000) throw new InvalidDataException("This is not a supported Windows backup.");
   var ids=new HashSet<string>();
   foreach(var q in data.Quests) {
    DateTime parsed;
    if(q==null || String.IsNullOrWhiteSpace(q.Id) || !ids.Add(q.Id) || String.IsNullOrWhiteSpace(q.Title) || q.Title.Length>500 || q.XP<5 || q.XP>1000 || q.Steps==null || q.Steps.Count>100 || q.Steps.Any(s=>s==null || String.IsNullOrWhiteSpace(s.Title) || s.Title.Length>500) || !new[]{"None","Daily","Weekly"}.Contains(q.Repeat) || !new[]{"School","Work","Home","Life","Fun"}.Contains(q.Category)) throw new InvalidDataException("The backup contains an invalid quest.");
    if(!String.IsNullOrEmpty(q.Due) && !DateTime.TryParseExact(q.Due,"yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture,System.Globalization.DateTimeStyles.None,out parsed)) throw new InvalidDataException("Invalid quest date.");
    if(q.Done && !DateTime.TryParseExact(q.Completed,"yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture,System.Globalization.DateTimeStyles.None,out parsed)) throw new InvalidDataException("Invalid completion date.");
   }
   return data;
  }
  public static SaveData Load(string path) {return File.Exists(path)?Decode(File.ReadAllText(path)):new SaveData();}
  public static void Save(string path, SaveData data) {
   string text=Encode(data); Decode(text);
   Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path)));
   string temp=path+".tmp"; File.WriteAllText(temp,text);
   if(File.Exists(path)) File.Replace(temp,path,path+".bak"); else File.Move(temp,path);
  }
 }
}
