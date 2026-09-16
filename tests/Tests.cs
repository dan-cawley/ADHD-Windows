using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Windows.Forms;
using System.Drawing;
namespace AdhdWarrior {
 public static class Tests {
  static int count;
  static void Check(bool value,string description) {if(!value)throw new Exception(description);count++;}
  public static int Run() {
   string folder=Path.Combine(Path.GetTempPath(),"adhd-warrior-tests-"+Guid.NewGuid());Directory.CreateDirectory(folder);
   var lines=new List<string>();
   try {
    DateTime today=new DateTime(2026,9,14);var data=new SaveData();var q=new Quest {Title="Test recurring quest",Repeat="Daily",Due="2026-09-01",Steps=new List<Step>{new Step {Title="First step"}}};data.Quests.Add(q);
    Check(Game.Complete(data,new[]{q},today)==50,"Completion XP");Check(data.XP==50&&data.Coins==10&&q.Done&&q.Steps[0].Done,"Rewards and step completion");
    Check(data.Quests.Count==2&&data.Quests[1].Due=="2026-09-15"&&!data.Quests[1].Steps[0].Done,"Recurrence resumes after today");
    Check(Game.Complete(data,new[]{q},today)==0&&data.XP==50&&data.Quests.Count==2,"Duplicate completion cannot award rewards");
    var archived=new Quest {Title="Archived",Archived=true};Check(Game.Complete(data,new[]{archived},today)==0,"Archived quests cannot earn rewards");
    Check(Game.Streak(data,today)==1&&Game.Streak(data,today.AddDays(1))==1&&Game.Streak(data,today.AddDays(2))==0,"Streak boundary");
    var weekly=new Quest {Title="Weekly",Repeat="Weekly",Due="2026-09-20"};data.Quests.Add(weekly);Game.Complete(data,new[]{weekly},today);Check(data.Quests.Last().Due=="2026-09-27","Weekly recurrence");
    string path=Path.Combine(folder,"save.json");Storage.Save(path,data);var loaded=Storage.Load(path);Check(loaded.XP==100&&loaded.Quests.Count==4&&loaded.Quests[0].Steps[0].Done,"Save round trip");
    data.Coins=99;Storage.Save(path,data);Check(Storage.Load(path+".bak").Coins==20&&Storage.Load(path).Coins==99,"Atomic save keeps previous version");
    bool rejected=false;try {Storage.Decode("{\"Version\":9}");} catch {rejected=true;}Check(rejected,"Invalid backup rejected");
    rejected=false;try {Storage.Decode("{}");} catch {rejected=true;}Check(rejected,"Empty JSON cannot replace user progress");
    rejected=false;data.Quests[0].XP=-1;try{Storage.Save(path,data);}catch{rejected=true;}Check(rejected&&Storage.Load(path).Coins==99,"Invalid save leaves existing data intact");
    count+=JourneyTests.Run(folder);count+=IosTests.Run();count+=ProgressionTests.Run();count+=CurrentFeatureTests.Run();
    lines.Add("PASS: "+count+" assertions. Test storage: "+folder);
    File.WriteAllLines(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"test-results.txt"),lines);return 0;
   }catch(Exception ex){File.WriteAllText(Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"test-results.txt"),"FAIL: "+ex);return 1;}
  }
 }
}
