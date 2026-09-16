using System;
using System.Linq;
using System.Drawing;
using System.Windows.Forms;
using System.Collections.Generic;
using System.Globalization;

namespace AdhdWarrior {
 public class ReminderSettings {
  public bool Enabled {get;set;} public bool QuestDue {get;set;} public bool Streaks {get;set;}
  public string DailyTime {get;set;} public string QuietStart {get;set;} public string QuietEnd {get;set;} public List<string> Sent {get;set;}
  public ReminderSettings(){QuestDue=true;Streaks=true;DailyTime="09:00";QuietStart="21:00";QuietEnd="08:00";Sent=new List<string>();}
 }
 public partial class MainWindow {
  NotifyIcon reminderIcon; System.Windows.Forms.Timer reminderTimer;
  void SetupReminders(){
   reminderIcon=new NotifyIcon {Icon=SystemIcons.Information,Text="ADHD Warrior reminders",Visible=data.Reminders.Enabled};
   reminderIcon.DoubleClick+=(s,e)=>{Show();WindowState=FormWindowState.Normal;Activate();};
   reminderTimer=new System.Windows.Forms.Timer {Interval=60000,Enabled=true};reminderTimer.Tick+=(s,e)=>CheckReminders(DateTime.Now);Shown+=(s,e)=>BeginInvoke((Action)(()=>CheckReminders(DateTime.Now)));
  }
  void DisposeReminders(){if(reminderTimer!=null)reminderTimer.Dispose();if(reminderIcon!=null){reminderIcon.Visible=false;reminderIcon.Dispose();}}
  static TimeSpan Clock(string text){return DateTime.ParseExact(text,"HH:mm",CultureInfo.InvariantCulture).TimeOfDay;}
  bool QuietNow(DateTime now){TimeSpan start=Clock(data.Reminders.QuietStart),end=Clock(data.Reminders.QuietEnd),time=now.TimeOfDay;if(start==end)return false;return start<end?time>=start&&time<end:time>=start||time<end;}
  string StreakPeriod(StreakQuest streak,DateTime day){return streak.Cadence=="Daily"?day.ToString("yyyyMMdd"):streak.Cadence=="Monthly"?day.ToString("yyyyMM"):Journey.WeekKey(day);}
  void CheckReminders(DateTime now){
   var settings=data.Reminders;reminderIcon.Visible=settings.Enabled;if(!settings.Enabled||QuietNow(now))return;var messages=new List<string>();var tokens=new List<string>();
   if(settings.QuestDue)foreach(var q in data.Quests.Where(x=>!x.Done&&!x.Archived&&!String.IsNullOrEmpty(x.Due))){DateTime due;if(!DateTime.TryParseExact(q.Due,"yyyy-MM-dd",CultureInfo.InvariantCulture,DateTimeStyles.None,out due))continue;due=due.Add(String.IsNullOrEmpty(q.DueTime)?Clock(settings.DailyTime):Clock(q.DueTime));string token="quest:"+q.Id+":"+q.Due+":"+q.DueTime;if(now>=due&&!settings.Sent.Contains(token)){messages.Add("Quest: "+q.Title);tokens.Add(token);}}
   if(settings.Streaks&&now.TimeOfDay>=Clock(settings.DailyTime))foreach(var streak in data.StreakQuests.Where(x=>AdhdWarrior.Streaks.Ready(x,now.Date))){string token="streak:"+streak.Id+":"+StreakPeriod(streak,now.Date);if(!settings.Sent.Contains(token)){messages.Add("Streak: "+streak.Title);tokens.Add(token);}}
   if(messages.Count==0)return;settings.Sent.AddRange(tokens);while(settings.Sent.Count>500)settings.Sent.RemoveAt(0);try{Storage.Save(path,data);}catch(Exception ex){reminderTimer.Stop();status.Text="Reminders paused because their history could not be saved: "+ex.Message;return;}
   ShowReminder(String.Join("\n",messages.Take(3))+(messages.Count>3?"\n+ "+(messages.Count-3)+" more":""));
  }
  void ShowReminder(string message){reminderIcon.Visible=true;reminderIcon.BalloonTipTitle="ADHD Warrior";reminderIcon.BalloonTipText=message;reminderIcon.BalloonTipIcon=ToolTipIcon.Info;reminderIcon.ShowBalloonTip(8000);}
  void ShowReminderSettings(){
   Note("Quiet Windows reminders\nReminders are optional and appear only while ADHD Warrior is running. Due-time quests use their exact time; date-only quests and ready streaks use the daily reminder time. Each item alerts once per due date or cadence.");
   var panel=new FlowLayoutPanel {FlowDirection=FlowDirection.TopDown,WrapContents=false,AutoSize=false,Height=285,Padding=new Padding(18),BackColor=Theme.Surface,Margin=new Padding(0,0,0,12)};Theme.Frame(panel,Theme.Blue);
   var enabled=new CheckBox {Text="Enable reminders while the app is running",Checked=data.Reminders.Enabled,AutoSize=true};var quests=new CheckBox {Text="Quest due reminders",Checked=data.Reminders.QuestDue,AutoSize=true};var streaks=new CheckBox {Text="Streak cadence reminders",Checked=data.Reminders.Streaks,AutoSize=true};panel.Controls.Add(enabled);panel.Controls.Add(quests);panel.Controls.Add(streaks);
   var row=new FlowLayoutPanel {AutoSize=true,WrapContents=false,Margin=new Padding(0,12,0,8)};var daily=new TextBox {Text=data.Reminders.DailyTime,Width=58,MaxLength=5};var quietStart=new TextBox {Text=data.Reminders.QuietStart,Width=58,MaxLength=5};var quietEnd=new TextBox {Text=data.Reminders.QuietEnd,Width=58,MaxLength=5};Theme.StyleInput(daily);Theme.StyleInput(quietStart);Theme.StyleInput(quietEnd);row.Controls.Add(new Label {Text="Daily time",AutoSize=true,Padding=new Padding(0,6,4,0)});row.Controls.Add(daily);row.Controls.Add(new Label {Text="Quiet from",AutoSize=true,Padding=new Padding(12,6,4,0)});row.Controls.Add(quietStart);row.Controls.Add(new Label {Text="to",AutoSize=true,Padding=new Padding(8,6,4,0)});row.Controls.Add(quietEnd);panel.Controls.Add(row);
   var actions=new FlowLayoutPanel {AutoSize=true,WrapContents=false};actions.Controls.Add(Button("Save reminder settings",()=>{DateTime parsed;if(!DateTime.TryParseExact(daily.Text,"HH:mm",CultureInfo.InvariantCulture,DateTimeStyles.None,out parsed)||!DateTime.TryParseExact(quietStart.Text,"HH:mm",CultureInfo.InvariantCulture,DateTimeStyles.None,out parsed)||!DateTime.TryParseExact(quietEnd.Text,"HH:mm",CultureInfo.InvariantCulture,DateTimeStyles.None,out parsed)){MessageBox.Show(this,"Use 24-hour times in HH:mm format, such as 09:00 or 21:30.","Reminder times");return;}if(Change(()=>{data.Reminders.Enabled=enabled.Checked;data.Reminders.QuestDue=quests.Checked;data.Reminders.Streaks=streaks.Checked;data.Reminders.DailyTime=daily.Text;data.Reminders.QuietStart=quietStart.Text;data.Reminders.QuietEnd=quietEnd.Text;},"Reminder settings saved.")){reminderIcon.Visible=data.Reminders.Enabled;CheckReminders(DateTime.Now);}}));actions.Controls.Add(Button("Send test reminder",()=>ShowReminder("Your reminder preview is working.")));panel.Controls.Add(actions);cards.Controls.Add(panel);
  }
 }
}
