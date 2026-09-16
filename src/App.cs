using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Windows.Forms;
using System.Collections.Generic;
using System.Threading;

namespace AdhdWarrior {
 static class Program {
  [STAThread] static int Main(string[] args) {
   Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
   if(args.Contains("--self-test")) return Tests.Run();
   bool first; using(var mutex=new Mutex(true,"Local\\AdhdWarriorWindows"+(args.Contains("--preview-test")?"Test":""),out first)) {
    if(!first) {MessageBox.Show("ADHD Warrior is already running.");return 0;}
    try {Application.Run(new MainWindow(args.Contains("--preview-test")));return 0;} catch(Exception ex) {MessageBox.Show(ex.Message,"ADHD Warrior could not start",MessageBoxButtons.OK,MessageBoxIcon.Error);return 1;}
   }
  }
 }
 public partial class MainWindow : Form {
  SaveData data; string path=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"AdhdWarrior","save.json");
  Label stats=new Label(), heading=new Label(), status=new Label(); TextBox capture=new TextBox(), search=new TextBox();
  FlowLayoutPanel cards=new FlowLayoutPanel(); string view="Today"; HashSet<string> selected=new HashSet<string>();
  Color ink=Color.FromArgb(41,49,58), green=Color.FromArgb(49,101,84), paper=Color.FromArgb(248,246,240);
  public MainWindow(bool testMode=false) {
   if(testMode) path=Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"test-state","save.json");
   data=Storage.Load(path); Journey.RefreshWeek(data,DateTime.Today); Text="ADHD Warrior — Windows 0.3"+(testMode?" [TEST DATA]":""); MinimumSize=new Size(1000,680); Size=new Size(1200,820); StartPosition=FormStartPosition.CenterScreen; Font=new Font("Segoe UI",10); BackColor=paper; ForeColor=ink; AutoScaleMode=AutoScaleMode.Dpi;
   var layout=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=2,RowCount=1}; layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,220));layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100)); Controls.Add(layout);
   var nav=new FlowLayoutPanel {Dock=DockStyle.Fill,FlowDirection=FlowDirection.TopDown,WrapContents=false,AutoScroll=true,Padding=new Padding(18,28,12,12),BackColor=Color.FromArgb(231,235,225)};layout.Controls.Add(nav,0,0);
   nav.Controls.Add(new Label {Text="ADHD\nWARRIOR",Font=new Font("Segoe UI",21,FontStyle.Bold),AutoSize=false,Size=new Size(165,90)});
   nav.Controls.Add(new Label {Text="Small steps. Real progress.",AutoSize=true,MaximumSize=new Size(165,0),Margin=new Padding(0,0,0,22)});
   foreach(string v in new[]{"Today","All quests","Review","Character","Familiars","Boss map","Equipment","Rewards","Completed","Archive","Backup & settings"}) {string target=v;var b=Button(v,()=>{view=target;selected.Clear();Render();});b.AutoSize=false;b.Width=165;b.Height=36;nav.Controls.Add(b);}
   var body=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=1,RowCount=6,Padding=new Padding(30,24,30,14)};layout.Controls.Add(body,1,0);
   foreach(int h in new[]{54,50,52,52}) body.RowStyles.Add(new RowStyle(SizeType.Absolute,h)); body.RowStyles.Add(new RowStyle(SizeType.Percent,100));body.RowStyles.Add(new RowStyle(SizeType.Absolute,44));
   heading.Font=new Font("Segoe UI",25,FontStyle.Bold);heading.Dock=DockStyle.Fill;body.Controls.Add(heading,0,0);
   stats.Dock=DockStyle.Fill;stats.ForeColor=green;body.Controls.Add(stats,0,1);
   var quick=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=3};quick.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));quick.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,108));quick.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,110));
   capture.Dock=DockStyle.Fill;capture.MaxLength=500;capture.AccessibleName="Quick capture quest title";capture.KeyDown+=(s,e)=>{if(e.KeyCode==Keys.Enter){AddQuick();e.SuppressKeyPress=true;}};
   quick.Controls.Add(capture,0,0);quick.Controls.Add(Button("+ Capture",AddQuick),1,0);quick.Controls.Add(Button("+ Details",()=>Edit(null)),2,0);body.Controls.Add(quick,0,2);
   var bar=new FlowLayoutPanel {Dock=DockStyle.Fill};search.Width=150;search.AccessibleName="Search quests";search.TextChanged+=(s,e)=>Render();bar.Controls.Add(new Label {Text="Search",AutoSize=true,Padding=new Padding(0,6,4,0)});bar.Controls.Add(search);bar.Controls.Add(Button("Complete selected",CompleteSelected));bar.Controls.Add(Button("Archive selected",ArchiveSelected));body.Controls.Add(bar,0,3);
   cards.Dock=DockStyle.Fill;cards.AutoScroll=true;cards.FlowDirection=FlowDirection.TopDown;cards.WrapContents=false;cards.SizeChanged+=(s,e)=>ResizeCards();body.Controls.Add(cards,0,4);
   status.Dock=DockStyle.Fill;status.ForeColor=green;status.Text="Capture a thought above. Enter adds it to today.";body.Controls.Add(status,0,5);Render();
   FormClosed+=(s,e)=>{foreach(var item in artCache.Values)item.Dispose();};
  }
  Button Button(string title,Action action) {var b=new Button {Text=title,AutoSize=true,Height=34,FlatStyle=FlatStyle.Flat,BackColor=Color.White,ForeColor=ink,Margin=new Padding(0,0,8,8),Padding=new Padding(7,3,7,3)};b.FlatAppearance.BorderColor=Color.FromArgb(203,211,201);b.Click+=(s,e)=>action();return b;}
  bool Change(Action action,string message) {
   var before=Storage.Encode(data);
   try {action();Storage.Save(path,data);} catch(Exception ex) {data=Storage.Decode(before);Render();MessageBox.Show(this,"Your change was not saved. "+ex.Message,"Save problem",MessageBoxButtons.OK,MessageBoxIcon.Error);return false;}
   status.Text=message;Render();return true;
  }
  void AddQuick() {var title=capture.Text.Trim();if(title.Length==0){capture.Focus();return;}if(Change(()=>data.Quests.Add(new Quest {Title=title,Due=DateTime.Today.ToString("yyyy-MM-dd")}),"Captured. One small step is enough."))capture.Clear();capture.Focus();}
  void Edit(Quest q) {using(var editor=new QuestEditor(q)) if(editor.ShowDialog(this)==DialogResult.OK) {Change(()=>{if(q==null)data.Quests.Add(editor.Result);else {int index=data.Quests.IndexOf(q);data.Quests[index]=editor.Result;}},"Quest saved.");}}
  List<Quest> Selection() {return data.Quests.Where(q=>selected.Contains(q.Id)&&!q.Done&&!q.Archived).ToList();}
  void CompleteSelected() {var list=Selection();if(list.Count==0){status.Text="Select one or more active quests first.";return;}CompleteQuests(list);}
  void ArchiveSelected() {var list=Selection();if(list.Count==0){status.Text="Select active quests to archive. You can restore them later.";return;}Change(()=>{foreach(var q in list)q.Archived=true;},"Moved to Archive. Restore whenever you need.");selected.Clear();}
  void ResizeCards() {foreach(Control c in cards.Controls){c.Width=Math.Max(500,cards.ClientSize.Width-26);foreach(Control child in c.Controls) if(child is CheckBox)child.Width=c.Width-32;}}
  void Note(string text) {cards.Controls.Add(new Label {Text=text,AutoSize=false,Height=120,Padding=new Padding(15),Font=new Font("Segoe UI",12),BackColor=Color.White});}
  void Render() {
   cards.SuspendLayout();foreach(Control c in cards.Controls.Cast<Control>().ToArray()){cards.Controls.Remove(c);c.Dispose();}
   heading.Text=view; stats.Text="LEVEL "+(1+data.XP/500)+"     /     "+data.XP+" XP     /     "+data.Coins+" COINS     /     "+Game.Streak(data,DateTime.Today)+" DAY STREAK";
   if(view=="Character")ShowCharacter();
   else if(view=="Familiars")ShowPets();
   else if(view=="Boss map")ShowBosses();
   else if(view=="Equipment")ShowGear();
   else if(view=="Rewards") {Note("Every step counts.\n\n"+data.Quests.Count(q=>q.Done)+" quests completed • "+data.XP+" lifetime XP • "+data.Coins+" coins available");Note("Next level in "+(500-data.XP%500)+" XP.\n\nQuest rewards: XP you choose, plus 1 coin per 5 XP. Completing a quest also completes its remaining steps.");foreach(var entry in data.Journey.Journal)Note(entry);}
   else if(view=="Backup & settings") {
    Note("Windows preview 0.3\n\nYour progress is saved on this computer after every change. No account is required.");
    cards.Controls.Add(Button("Export Windows backup…",Export));cards.Controls.Add(Button("Restore Windows backup…",Import));cards.Controls.Add(Button("Preview iOS import…",ImportIos));
    Note("Save location:\n"+path+"\n\nThe previous save is retained as save.json.bak.");Note("Backups use Windows format 3. Older Windows backups upgrade automatically. iOS import supports quests, balances and equipment; review its limitations before applying.\n\nKeyboard: Enter to capture; Tab to move between controls; Space to select.");
   } else {
    string today=DateTime.Today.ToString("yyyy-MM-dd");
    IEnumerable<Quest> list=data.Quests;
    if(view=="Completed")list=list.Where(q=>q.Done&&!q.Archived);
    else if(view=="Archive")list=list.Where(q=>q.Archived);
    else {list=list.Where(q=>!q.Done&&!q.Archived);if(view=="Today")list=list.Where(q=>String.IsNullOrEmpty(q.Due)||String.CompareOrdinal(q.Due,today)<=0);if(view=="Review")list=list.Where(q=>!String.IsNullOrEmpty(q.Due)&&String.CompareOrdinal(q.Due,today)<0);}
    list=list.Where(q=>q.Title.IndexOf(search.Text,StringComparison.OrdinalIgnoreCase)>=0).OrderBy(q=>q.Due).ToList();
    if(!list.Any())Note(view=="Review"?"Nothing overdue. You have room to breathe.":"No quests here yet. Capture a small next step above.");
    foreach(var q in list)AddCard(q,today);
   }
   ResizeCards();cards.ResumeLayout();
  }
  void AddCard(Quest q,string today) {
   var panel=new FlowLayoutPanel {FlowDirection=FlowDirection.TopDown,WrapContents=false,AutoSize=false,Height=136+q.Steps.Count*28,BackColor=Color.White,Padding=new Padding(14),Margin=new Padding(0,0,0,12)};
   var check=new CheckBox {Text=q.Title,Checked=selected.Contains(q.Id),AutoSize=false,AutoEllipsis=true,Width=650,Height=30,Font=new Font("Segoe UI",12,FontStyle.Bold),Enabled=!q.Done&&!q.Archived};check.CheckedChanged+=(s,e)=>{if(check.Checked)selected.Add(q.Id);else selected.Remove(q.Id);};panel.Controls.Add(check);
   bool overdue=!q.Done&&!String.IsNullOrEmpty(q.Due)&&String.CompareOrdinal(q.Due,today)<0;
   panel.Controls.Add(new Label {Text=q.Category+"   •   "+q.XP+" XP   •   "+(String.IsNullOrEmpty(q.Due)?"Anytime":q.Due)+(overdue?"  ·  Overdue":"")+(q.Repeat=="None"?"":"   •   "+q.Repeat),AutoSize=true,ForeColor=overdue?Color.FromArgb(154,78,41):green,Margin=new Padding(0,0,0,8)});
   foreach(var step in q.Steps) {var item=step;var cb=new CheckBox {Text=item.Title,Checked=item.Done,AutoSize=false,Width=630,Height=24,Enabled=!q.Done&&!q.Archived};cb.CheckedChanged+=(s,e)=>Change(()=>item.Done=cb.Checked,"Small step saved.");panel.Controls.Add(cb);}
   var actions=new FlowLayoutPanel {AutoSize=true,WrapContents=false};
   if(q.Archived) actions.Controls.Add(Button("Restore",()=>Change(()=>q.Archived=false,"Quest restored.")));
   else if(!q.Done) {actions.Controls.Add(Button("Complete",()=>CompleteQuests(new[]{q})));actions.Controls.Add(Button("Edit",()=>Edit(q)));if(overdue)actions.Controls.Add(Button("Move to today",()=>Change(()=>q.Due=today,"A fresh start. Quest moved to today.")));}
   else actions.Controls.Add(new Label {Text="Completed "+q.Completed+" · Awarded "+q.AwardedXP+" XP",AutoSize=true});
   panel.Controls.Add(actions);cards.Controls.Add(panel);
  }
  void Export() {using(var dialog=new SaveFileDialog {Filter="JSON backup|*.json",FileName="adhd-warrior-"+DateTime.Today.ToString("yyyy-MM-dd")+".json"}) if(dialog.ShowDialog(this)==DialogResult.OK) {try {File.WriteAllText(dialog.FileName,Storage.Encode(data));status.Text="Backup exported.";}catch(Exception ex){MessageBox.Show(this,ex.Message,"Export failed");}}}
  void Import() {using(var dialog=new OpenFileDialog {Filter="JSON backup|*.json"}) if(dialog.ShowDialog(this)==DialogResult.OK) {try {var incoming=Storage.Decode(File.ReadAllText(dialog.FileName));if(MessageBox.Show(this,"Restore "+incoming.Quests.Count+" quests from this Windows backup? Your current progress will be retained in a recovery backup.","Restore backup",MessageBoxButtons.OKCancel)!=DialogResult.OK)return;Storage.Save(path+".before-restore-"+DateTime.Now.ToString("yyyyMMdd-HHmmssfff")+".json",data);Change(()=>{data=incoming;Journey.RefreshWeek(data,DateTime.Today);},"Backup restored.");}catch(Exception ex){MessageBox.Show(this,ex.Message,"Could not restore backup");}}}
 }
 public class QuestEditor : Form {
  public Quest Result; TextBox title=new TextBox(),steps=new TextBox(); ComboBox category=new ComboBox(),repeat=new ComboBox();DateTimePicker due=new DateTimePicker();NumericUpDown xp=new NumericUpDown();Quest original;
  public QuestEditor(Quest q) {
   original=q;Text=q==null?"New quest":"Edit quest";Size=new Size(550,570);MinimumSize=Size;StartPosition=FormStartPosition.CenterParent;Font=new Font("Segoe UI",10);BackColor=Color.FromArgb(248,246,240);
   var form=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=2,RowCount=7,Padding=new Padding(22)};form.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,120));form.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));Controls.Add(form);
   title.MaxLength=500;category.Items.AddRange(new object[]{"School","Work","Home","Life","Fun"});repeat.Items.AddRange(new object[]{"None","Daily","Weekly"});category.DropDownStyle=repeat.DropDownStyle=ComboBoxStyle.DropDownList;
   due.Format=DateTimePickerFormat.Short;due.ShowCheckBox=true;due.Checked=false;xp.Minimum=5;xp.Maximum=1000;xp.Increment=5;xp.Value=50;steps.Multiline=true;steps.ScrollBars=ScrollBars.Vertical;
   string[] labels={"Quest","Category","Due date","Repeat","XP reward","Steps\n(one per line)"};Control[] inputs={title,category,due,repeat,xp,steps};
   for(int i=0;i<inputs.Length;i++){form.RowStyles.Add(new RowStyle(i==5?SizeType.Percent:SizeType.Absolute,i==5?100:48));form.Controls.Add(new Label {Text=labels[i],AutoSize=true},0,i);inputs[i].Dock=DockStyle.Fill;form.Controls.Add(inputs[i],1,i);}
   category.SelectedItem=q==null?"Life":q.Category;repeat.SelectedItem=q==null?"None":q.Repeat;
   if(q!=null) {title.Text=q.Title;xp.Value=q.XP;steps.Text=String.Join(Environment.NewLine,q.Steps.Select(s=>s.Title));DateTime d;if(DateTime.TryParse(q.Due,out d)){due.Value=d;due.Checked=true;}}
   var buttons=new FlowLayoutPanel {Dock=DockStyle.Fill,AutoSize=true};var save=new Button {Text="Save quest",AutoSize=true};var cancel=new Button {Text="Cancel",DialogResult=DialogResult.Cancel,AutoSize=true};buttons.Controls.Add(save);buttons.Controls.Add(cancel);form.Controls.Add(buttons,1,6);form.RowStyles.Add(new RowStyle(SizeType.Absolute,44));AcceptButton=save;CancelButton=cancel;
   save.Click+=(s,e)=>{
    var lines=steps.Lines.Select(x=>x.Trim()).Where(x=>x.Length>0).ToList();
    if(String.IsNullOrWhiteSpace(title.Text)||lines.Count>100||lines.Any(x=>x.Length>500)){MessageBox.Show(this,"Add a quest title and up to 100 steps of 500 characters each.");return;}
    Result=new Quest {Id=original==null?Guid.NewGuid().ToString():original.Id,Title=title.Text.Trim(),Category=(string)category.SelectedItem,Repeat=(string)repeat.SelectedItem,Due=due.Checked?due.Value.ToString("yyyy-MM-dd"):"",XP=(int)xp.Value,Steps=lines.Select((x,i)=>new Step {Title=x,Done=original!=null&&i<original.Steps.Count&&original.Steps[i].Title==x&&original.Steps[i].Done}).ToList()};DialogResult=DialogResult.OK;
   };
  }
 }
}


