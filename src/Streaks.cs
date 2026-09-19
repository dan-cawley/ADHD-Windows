using System;
using System.Linq;
using System.Drawing;
using System.Windows.Forms;

namespace AdhdWarrior {
 public class StreakQuest {
  public string Id {get;set;} public string Title {get;set;} public string Cadence {get;set;} public int XP {get;set;}
  public int Total {get;set;} public int Current {get;set;} public int Best {get;set;} public string LastCompleted {get;set;}
  public StreakQuest(){Id=Guid.NewGuid().ToString();Title="";Cadence="Daily";XP=15;LastCompleted="";}
 }
 public static class Streaks {
  public static string NormalizeCadence(string text){string value=(text??"").ToLowerInvariant();foreach(string day in Enum.GetNames(typeof(DayOfWeek)))if(value.Contains(day.ToLowerInvariant()))return day;return value.Contains("month")?"Monthly":value.Contains("week")?"Weekly":"Daily";}
  static bool SamePeriod(string cadence,DateTime left,DateTime right){if(cadence=="Daily")return left.Date==right.Date;if(cadence=="Monthly")return left.Year==right.Year&&left.Month==right.Month;return Journey.WeekKey(left)==Journey.WeekKey(right);}
  public static bool Ready(StreakQuest streak,DateTime day){DayOfWeek weekday;if(Enum.TryParse(streak.Cadence,out weekday)&&day.DayOfWeek!=weekday)return false;DateTime last;return !DateTime.TryParseExact(streak.LastCompleted,"yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture,System.Globalization.DateTimeStyles.None,out last)||!SamePeriod(streak.Cadence,last,day);}
  public static DateTime NextReady(StreakQuest streak,DateTime day){
   if(Ready(streak,day))return day.Date;DayOfWeek weekday;if(Enum.TryParse(streak.Cadence,out weekday)){int days=((int)weekday-(int)day.DayOfWeek+7)%7;return day.Date.AddDays(days==0?7:days);}
   if(streak.Cadence=="Daily")return day.Date.AddDays(1);if(streak.Cadence=="Monthly")return new DateTime(day.Year,day.Month,1).AddMonths(1);return day.Date.AddDays(7-(((int)day.DayOfWeek+6)%7));
  }
  public static string Status(StreakQuest streak,DateTime day){return Ready(streak,day)?"Ready now":"Next: "+NextReady(streak,day).ToString("ddd, MMM d");}
  public static int PetBonus(SaveData data){var pet=Journey.ActivePet(data);return pet.EggStage==4?pet.StreakSkill*Journey.Stage(pet):0;}
  public static int Complete(SaveData data,StreakQuest streak,DateTime day){
   if(!data.StreakQuests.Contains(streak))throw new InvalidOperationException("This streak quest is not in your save.");DayOfWeek weekday;if(Enum.TryParse(streak.Cadence,out weekday)&&day.DayOfWeek!=weekday)throw new InvalidOperationException("This streak quest is ready on "+streak.Cadence+".");if(!Ready(streak,day))throw new InvalidOperationException("This streak quest is already complete for its current cadence.");
   DateTime last;bool continues=DateTime.TryParseExact(streak.LastCompleted,"yyyy-MM-dd",System.Globalization.CultureInfo.InvariantCulture,System.Globalization.DateTimeStyles.None,out last)&&SamePeriod(streak.Cadence,last,streak.Cadence=="Monthly"?day.AddMonths(-1):streak.Cadence=="Daily"?day.AddDays(-1):day.AddDays(-7));
   streak.Current=continues?Math.Max(1,streak.Current)+1:1;streak.Best=Math.Max(streak.Best,streak.Current);streak.Total++;streak.LastCompleted=day.ToString("yyyy-MM-dd");
   int awarded=checked(streak.XP+PetBonus(data));int coins=(streak.Cadence=="Daily"?10:streak.Cadence=="Monthly"?28:18)+Math.Min(10,Math.Max(0,streak.Current-1)*2);
   data.XP=checked(data.XP+awarded);data.Coins=checked(data.Coins+coins);var quest=new Quest {Rarity=streak.Cadence=="Daily"?"Common":streak.Cadence=="Monthly"?"Epic":"Rare",AwardedXP=awarded};Journey.OnCompletion(data,quest,day);Journey.Log(data.Journey,"Streak: "+streak.Title+" · "+streak.Current+" in a row · +"+awarded+" XP · +"+coins+" coins.");return awarded;
  }
 }
 public partial class MainWindow {
  void ShowStreaks(){
   Note("Build consistency without turning it into pressure. Each streak can be completed once per cadence. Your active familiar's Streak XP skill adds a bonus based on its evolution stage.");
   cards.Controls.Add(Button("+ New streak quest",()=>EditStreak(null)));
   if(data.LastCompletion!=null&&data.LastCompletion.Kind=="Streak")cards.Controls.Add(Button("Undo last streak completion",UndoLastCompletion));
   if(data.StreakQuests.Count==0)Note("No streak quests yet. Try a small daily action such as taking medication, reading for ten minutes, or preparing tomorrow's first task.");
   foreach(var item in data.StreakQuests.ToList()){var streak=item;bool ready=Streaks.Ready(streak,DateTime.Today);int bonus=Streaks.PetBonus(data),remaining=6-streak.Total%6;var complete=Button(ready?"Complete now":"Not ready yet",()=>{int earned=0;var receipt=CompletionUndo.Capture(data,"Streak",new[]{streak.Id},streak.Title,DateTime.Now);if(Change(()=>{earned=Streaks.Complete(data,streak,DateTime.Today);data.LastCompletion=receipt;},"Streak progress saved."))status.Text="Streak complete! +"+earned+" XP.";});complete.Enabled=ready;var edit=Button("Edit",()=>EditStreak(streak));var remove=Button("Remove",()=>{if(MessageBox.Show(this,"Remove ‘"+streak.Title+"’ and its streak history?","Remove streak quest",MessageBoxButtons.YesNo,MessageBoxIcon.Question)==DialogResult.Yes)Change(()=>data.StreakQuests.Remove(streak),"Streak quest removed.");});AdventureCard(streak.Title,streak.Cadence+" · "+streak.XP+" base XP"+(bonus>0?" + "+bonus+" familiar XP":"")+"\nCurrent streak "+streak.Current+" · Best "+streak.Best+" · "+streak.Total+" total · Gear reward in "+remaining+"\n"+Streaks.Status(streak,DateTime.Today),Artwork("forest-twilight"),streak.Total%6,6,complete,edit,remove);}
  }
  void EditStreak(StreakQuest existing){
   using(var dialog=new Form {Text=existing==null?"New streak quest":"Edit streak quest",Size=new Size(430,300),FormBorderStyle=FormBorderStyle.FixedDialog,MaximizeBox=false,MinimizeBox=false,StartPosition=FormStartPosition.CenterParent,BackColor=Theme.Canvas,ForeColor=Theme.Text}){
    var title=new TextBox {Left=24,Top=48,Width=365,MaxLength=500,Text=existing==null?"":existing.Title};var cadence=new ComboBox {Left=24,Top=112,Width=210,DropDownStyle=ComboBoxStyle.DropDownList};cadence.Items.AddRange(new object[]{"Daily","Weekly","Monthly","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"});cadence.SelectedItem=existing==null?"Daily":existing.Cadence;var xp=new NumericUpDown {Left=250,Top=112,Width=139,Minimum=5,Maximum=1000,Value=existing==null?15:existing.XP};Theme.StyleInput(title);Theme.StyleInput(cadence);Theme.StyleInput(xp);
    dialog.Controls.Add(new Label {Text="What do you want to keep doing?",Left=24,Top=22,AutoSize=true});dialog.Controls.Add(title);dialog.Controls.Add(new Label {Text="Cadence",Left=24,Top=88,AutoSize=true});dialog.Controls.Add(cadence);dialog.Controls.Add(new Label {Text="Base XP",Left=250,Top=88,AutoSize=true});dialog.Controls.Add(xp);
    var save=Button(existing==null?"Create streak":"Save changes",()=>{});save.Left=250;save.Top=180;save.DialogResult=DialogResult.OK;var cancel=Button("Cancel",()=>{});cancel.Left=158;cancel.Top=180;cancel.DialogResult=DialogResult.Cancel;dialog.Controls.Add(cancel);dialog.Controls.Add(save);dialog.AcceptButton=save;dialog.CancelButton=cancel;
    if(dialog.ShowDialog(this)==DialogResult.OK){string name=title.Text.Trim(),schedule=(string)cadence.SelectedItem;if(name.Length==0){MessageBox.Show(this,"Give the streak quest a title.");return;}if(existing==null)Change(()=>data.StreakQuests.Add(new StreakQuest {Title=name,Cadence=schedule,XP=(int)xp.Value}),"Streak quest created.");else {bool cadenceChanged=existing.Cadence!=schedule;Change(()=>{existing.Title=name;existing.XP=(int)xp.Value;if(cadenceChanged){existing.Cadence=schedule;existing.Current=0;existing.LastCompleted="";}},"Streak quest updated."+(cadenceChanged?" Cadence progress restarted.":""));}}
   }
  }
 }
}
