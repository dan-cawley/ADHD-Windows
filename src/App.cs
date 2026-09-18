using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Windows.Forms;
using System.Collections.Generic;
using System.Threading;
using System.Runtime.InteropServices;

namespace AdhdWarrior {
 static class Program {
  [DllImport("user32.dll",SetLastError=true)]static extern IntPtr FindWindow(string className,string windowName);
  [DllImport("user32.dll")]static extern bool ShowWindow(IntPtr window,int command);
  [DllImport("user32.dll")]static extern bool SetForegroundWindow(IntPtr window);
  static bool RestoreExisting(){var window=FindWindow(null,"ADHD Warrior — Windows 0.22.0");if(window==IntPtr.Zero)return false;ShowWindow(window,9);SetForegroundWindow(window);return true;}
  [STAThread] static int Main(string[] args) {
   Application.EnableVisualStyles(); Application.SetCompatibleTextRenderingDefault(false);
   if(args.Contains("--self-test")) return Tests.Run();
   bool first; using(var mutex=new Mutex(true,"Local\\AdhdWarriorWindows"+(args.Contains("--preview-test")?"Test":""),out first)) {
    if(!first) {if(!RestoreExisting())MessageBox.Show("ADHD Warrior is already running in the notification area.");return 0;}
    try {Application.Run(new MainWindow(args.Contains("--preview-test"),args.Contains("--background")));return 0;} catch(Exception ex) {MessageBox.Show(ex.Message,"ADHD Warrior could not start",MessageBoxButtons.OK,MessageBoxIcon.Error);return 1;}
   }
  }
 }
 public partial class MainWindow : Form {
  const int WM_SETREDRAW=0x000B;
  [DllImport("user32.dll")]static extern IntPtr SendMessage(IntPtr window,int message,IntPtr wParam,IntPtr lParam);
  SaveData data; string path=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"AdhdWarrior","save.json");
  Label stats=new Label(), heading=new Label(), status=new Label(); TextBox capture=new TextBox(), search=new TextBox();
  BufferedFlowLayoutPanel cards=new BufferedFlowLayoutPanel(); string view="Today"; HashSet<string> selected=new HashSet<string>();
  Color ink=Theme.Text, green=Theme.Emerald, paper=Theme.Canvas;bool testMode,startHidden;
  public MainWindow(bool testMode=false,bool startHidden=false) {
   this.testMode=testMode;this.startHidden=startHidden;
   if(testMode) path=Path.Combine(AppDomain.CurrentDomain.BaseDirectory,"test-state","save.json");
   data=Storage.Load(path); Journey.RefreshWeek(data,DateTime.Today);if(DailyTemplatesEngine.EnsureToday(data,DateTime.Today))Storage.Save(path,data); Text="ADHD Warrior — Windows 0.22.0"+(testMode?" [TEST DATA]":"");Icon=Icon.ExtractAssociatedIcon(Application.ExecutablePath); MinimumSize=new Size(1000,680); Size=new Size(1240,860); StartPosition=FormStartPosition.CenterScreen; Font=new Font("Segoe UI",10); BackColor=paper; ForeColor=ink; AutoScaleMode=AutoScaleMode.Dpi;
   var layout=new ForestLayout {BackgroundImage=Artwork("forest-twilight"),Dock=DockStyle.Fill,ColumnCount=2,RowCount=1}; layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,220));layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100)); Controls.Add(layout);
   var nav=new FlowLayoutPanel {Dock=DockStyle.Fill,FlowDirection=FlowDirection.TopDown,WrapContents=false,AutoScroll=true,Padding=new Padding(18,28,12,12),BackColor=Theme.Sidebar,ForeColor=Theme.Text};layout.Controls.Add(nav,0,0);
   nav.Controls.Add(new Label {Text="ADHD\nWARRIOR",Font=new Font("Georgia",18,FontStyle.Bold),ForeColor=Theme.Gold,AutoSize=false,Size=new Size(165,90)});
   nav.Controls.Add(new Label {Text="Small steps. Real progress.",ForeColor=Theme.Muted,AutoSize=true,MaximumSize=new Size(165,0),Margin=new Padding(0,0,0,22)});
   foreach(string v in new[]{"Today","All quests","Review","Daily templates","Streak quests","Character","Familiars","Boss map","Equipment","Rewards","Completed","Archive","Settings"}) {string target=v;var b=Button(v,()=>{view=target;selected.Clear();Render();});b.AutoSize=false;b.Width=165;b.Height=36;b.TextAlign=ContentAlignment.MiddleLeft;b.Padding=new Padding(12,3,7,3);b.FlatAppearance.BorderSize=0;b.BackColor=Theme.Sidebar;b.Paint+=(sender,e)=>{if(view==target)using(var pen=new Pen(Theme.Gold,3))e.Graphics.DrawLine(pen,1,8,1,b.Height-8);};navigation.Add(v,b);nav.Controls.Add(b);}
   var body=new TableLayoutPanel {BackColor=Color.Transparent,Dock=DockStyle.Fill,ColumnCount=1,RowCount=6,Padding=new Padding(30,24,30,14)};layout.Controls.Add(body,1,0);
   foreach(int h in new[]{58,88,52,52}) body.RowStyles.Add(new RowStyle(SizeType.Absolute,h)); body.RowStyles.Add(new RowStyle(SizeType.Percent,100));body.RowStyles.Add(new RowStyle(SizeType.Absolute,44));
   heading.Font=new Font("Georgia",25);heading.ForeColor=Theme.Text;heading.BackColor=Color.Transparent;heading.Dock=DockStyle.Fill;body.Controls.Add(heading,0,0);
   body.Controls.Add(BuildMetrics(),0,1);Theme.StyleInput(capture);Theme.StyleInput(search);
   var quick=new TableLayoutPanel {BackColor=Color.Transparent,Dock=DockStyle.Fill,ColumnCount=3};quick.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));quick.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,108));quick.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,110));
   capture.Dock=DockStyle.Fill;capture.MaxLength=500;capture.AccessibleName="Quick capture quest title";capture.KeyDown+=(s,e)=>{if(e.KeyCode==Keys.Enter){AddQuick();e.SuppressKeyPress=true;}};
   quick.Controls.Add(capture,0,0);quick.Controls.Add(Button("+ Capture",AddQuick),1,0);quick.Controls.Add(Button("+ Details",()=>Edit(null)),2,0);body.Controls.Add(quick,0,2);
   var bar=new FlowLayoutPanel {BackColor=Color.Transparent,Dock=DockStyle.Fill};search.Width=150;search.AccessibleName="Search quests";search.TextChanged+=(s,e)=>Render();bar.Controls.Add(new Label {Text="Search",AutoSize=true,Padding=new Padding(0,6,4,0)});bar.Controls.Add(search);bar.Controls.Add(Button("Complete selected",CompleteSelected));bar.Controls.Add(Button("Archive selected",ArchiveSelected));body.Controls.Add(bar,0,3);
   cards.BackColor=Color.Transparent;cards.Dock=DockStyle.Fill;cards.AutoScroll=true;cards.FlowDirection=FlowDirection.TopDown;cards.WrapContents=false;cards.SizeChanged+=(s,e)=>ResizeCards();body.Controls.Add(cards,0,4);
   status.BackColor=Color.Transparent;status.Dock=DockStyle.Fill;status.ForeColor=green;status.Text="Capture a thought above. Enter adds it to today.";body.Controls.Add(status,0,5);Render();SetupReminders();
   FormClosed+=(s,e)=>{DisposeReminders();foreach(var item in artCache.Values)item.Dispose();};
  }
  Button Button(string title,Action action) {var b=new ThemedButton {Text=title,AutoSize=true,Height=34,FlatStyle=FlatStyle.Flat,BackColor=Theme.Raised,ForeColor=ink,Margin=new Padding(0,0,8,8),Padding=new Padding(7,3,7,3)};Theme.StyleButton(b,title=="Complete"||title=="+ Capture"||title=="Save quest");b.Click+=(s,e)=>action();return b;}
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
  void ResizeCards() {foreach(Control c in cards.Controls){c.Width=Math.Max(500,cards.ClientSize.Width-26);if(c is Label)c.Height=Math.Max(72,TextRenderer.MeasureText(c.Text,c.Font,new Size(c.Width-c.Padding.Horizontal,0),TextFormatFlags.WordBreak).Height+c.Padding.Vertical+8);foreach(Control child in c.Controls) if(child is CheckBox)child.Width=c.Width-32;}}
  void Note(string text) {cards.Controls.Add(new Label {Text=text,AutoSize=false,Height=100,Padding=new Padding(18),Font=new Font("Segoe UI",10),BackColor=Theme.Surface,ForeColor=Theme.Muted,Margin=new Padding(0,0,0,12)});}
  void Render() {
   bool redraw=IsHandleCreated;if(redraw)SendMessage(Handle,WM_SETREDRAW,IntPtr.Zero,IntPtr.Zero);cards.SuspendLayout();try{foreach(Control c in cards.Controls.Cast<Control>().ToArray()){cards.Controls.Remove(c);c.Dispose();}
   RefreshTheme();heading.Text=view; stats.Text="LEVEL "+Progression.Level(data.XP)+"     /     "+data.XP+" XP     /     "+data.Coins+" COINS     /     "+Game.Streak(data,DateTime.Today)+" DAY STREAK";
   if(view=="Streak quests")ShowStreaks();
   else if(view=="Daily templates")ShowDailyTemplates();
   else if(view=="Character")ShowCharacter();
   else if(view=="Familiars")ShowPets();
   else if(view=="Boss map")ShowBosses();
   else if(view=="Equipment")ShowGear();
   else if(view=="Rewards")ShowRewards();
   else if(view=="Settings") {
    Note("Windows preview 0.22.0\n\nYour progress is saved on this computer after every change. No account is required.");
    ShowCalendarSettings();ShowReminderSettings();cards.Controls.Add(Button("Export Windows backup…",Export));cards.Controls.Add(Button("Restore Windows backup…",Import));cards.Controls.Add(Button("Preview iOS import…",ImportIos));
    Note("Save location:\n"+path+"\n\nThe previous save is retained as save.json.bak.");Note("Backups use Windows format 12. Older Windows backups upgrade automatically. Encrypted calendar addresses stay on this Windows account and is excluded from backups.\n\nStill missing from Settings: appearance and text-size controls, sound and animation preferences, cloud sync, automatic updates, focus and body-double controls, and account or friend features.\n\nKeyboard: Enter to capture; Tab to move between controls; Space to select.");
   } else {
    if(view=="Today")ShowWelcome();
    string today=DateTime.Today.ToString("yyyy-MM-dd");
    IEnumerable<Quest> list=data.Quests;
    if(view=="Completed")list=list.Where(q=>q.Done&&!q.Archived);
    else if(view=="Archive")list=list.Where(q=>q.Archived);
    else {list=list.Where(q=>!q.Done&&!q.Archived);if(view=="Today")list=list.Where(q=>String.IsNullOrEmpty(q.Due)||String.CompareOrdinal(q.Due,today)<=0);if(view=="Review")list=list.Where(q=>!String.IsNullOrEmpty(q.Due)&&String.CompareOrdinal(q.Due,today)<0);}
    list=list.Where(q=>q.Title.IndexOf(search.Text,StringComparison.OrdinalIgnoreCase)>=0).OrderBy(q=>q.Due).ToList();
    if(!list.Any())Note(view=="Review"?"Nothing overdue. You have room to breathe.":"No quests here yet. Capture a small next step above.");
    foreach(var q in list)AddCard(q,today);
   }
   ResizeCards();}finally{cards.ResumeLayout(true);if(redraw){SendMessage(Handle,WM_SETREDRAW,new IntPtr(1),IntPtr.Zero);Invalidate(true);Update();}}
  }
  void AddCard(Quest q,string today) {
   var pet=Journey.ActivePet(data);var petDefinition=Journey.Definition(pet);int stage=Journey.Stage(pet),lootChance=pet.EggStage==4?Math.Min(100,pet.LootSkill*stage):0,bonus=q.Done?Math.Max(0,q.AwardedXP-q.XP):Journey.Bonus(data,q,DateTime.Today),reward=q.Done?q.AwardedXP:q.XP+bonus,boss=data.Journey.BossIndex;
   var panel=new TableLayoutPanel {ColumnCount=3,RowCount=1,Height=Math.Max(210,174+q.Steps.Count*27),BackColor=Theme.Surface,Padding=new Padding(12),Margin=new Padding(0,0,0,12)};panel.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,124));panel.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));panel.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,124));Theme.Frame(panel,Theme.Category(q.Category));
   var bossPanel=new TableLayoutPanel {Dock=DockStyle.Fill,RowCount=2,ColumnCount=1,BackColor=Color.FromArgb(35,45,59),Margin=new Padding(0,0,10,0)};bossPanel.RowStyles.Add(new RowStyle(SizeType.Percent,100));bossPanel.RowStyles.Add(new RowStyle(SizeType.Absolute,42));bossPanel.Controls.Add(new PictureBox {Dock=DockStyle.Fill,Image=Artwork(boss<9?"weekly_monsters_1_9":"weekly_monsters_10_18",boss%9),SizeMode=PictureBoxSizeMode.Zoom,Padding=new Padding(5),AccessibleName=Journey.Bosses[boss]+" boss"},0,0);bossPanel.Controls.Add(new Label {Text="FIGHTS\n"+Journey.Bosses[boss],Dock=DockStyle.Fill,TextAlign=ContentAlignment.MiddleCenter,Font=new Font("Segoe UI",7.5f,FontStyle.Bold),ForeColor=Theme.Coral,AutoEllipsis=true},0,1);panel.Controls.Add(bossPanel,0,0);
   var details=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=1,RowCount=4,Margin=new Padding(0)};details.RowStyles.Add(new RowStyle(SizeType.Absolute,34));details.RowStyles.Add(new RowStyle(SizeType.Absolute,48));details.RowStyles.Add(new RowStyle(SizeType.Percent,100));details.RowStyles.Add(new RowStyle(SizeType.Absolute,42));
   var check=new CheckBox {Text=q.Title,Checked=selected.Contains(q.Id),Dock=DockStyle.Fill,AutoEllipsis=true,Font=new Font("Segoe UI",12,FontStyle.Bold),Enabled=!q.Done&&!q.Archived};check.CheckedChanged+=(s,e)=>{if(check.Checked)selected.Add(q.Id);else selected.Remove(q.Id);};details.Controls.Add(check,0,0);
   bool overdue=!q.Done&&!String.IsNullOrEmpty(q.Due)&&String.CompareOrdinal(q.Due,today)<0;
   var rewards=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=3,RowCount=1,Margin=new Padding(0,2,0,4)};for(int i=0;i<3;i++)rewards.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,33.33f));string xpText=reward+" XP"+(bonus>0?"  ("+q.XP+" + "+bonus+")":"");string[] rewardText={xpText,lootChance+"% LOOT",pet.EggStage<4?"+20 GROWTH":"+20 PET XP"};Color[] rewardColor={Theme.Blue,Theme.Gold,Theme.Violet};for(int i=0;i<3;i++){var tile=new Label {Text=rewardText[i],Dock=DockStyle.Fill,TextAlign=ContentAlignment.MiddleCenter,Font=new Font("Segoe UI",9,FontStyle.Bold),ForeColor=rewardColor[i],BackColor=Color.FromArgb(37,50,68),Margin=new Padding(i==0?0:4,0,0,0)};rewards.Controls.Add(tile,i,0);}details.Controls.Add(rewards,0,1);
   var questBody=new FlowLayoutPanel {Dock=DockStyle.Fill,FlowDirection=FlowDirection.TopDown,WrapContents=false,Margin=new Padding(0)};questBody.Controls.Add(new Label {Text=q.Category+"   •   "+q.Rarity+"   •   "+(String.IsNullOrEmpty(q.Due)?"Anytime":q.Due+(String.IsNullOrEmpty(q.DueTime)?"":" at "+q.DueTime))+(overdue?"  ·  Overdue":"")+(q.Repeat=="None"?"":"   •   "+q.Repeat),AutoSize=true,ForeColor=overdue?Theme.Coral:Theme.Category(q.Category),Margin=new Padding(0,2,0,5)});foreach(var step in q.Steps) {var item=step;var cb=new CheckBox {Text=item.Title,Checked=item.Done,AutoSize=false,Width=520,Height=24,Enabled=!q.Done&&!q.Archived};cb.CheckedChanged+=(s,e)=>Change(()=>item.Done=cb.Checked,"Small step saved.");questBody.Controls.Add(cb);}details.Controls.Add(questBody,0,2);
   var actions=new FlowLayoutPanel {AutoSize=true,WrapContents=false};
   if(q.Archived) actions.Controls.Add(Button("Restore",()=>Change(()=>q.Archived=false,"Quest restored.")));
   else if(!q.Done) {actions.Controls.Add(Button("Complete",()=>CompleteQuests(new[]{q})));actions.Controls.Add(Button("Edit",()=>Edit(q)));if(overdue)actions.Controls.Add(Button("Move to today",()=>Change(()=>q.Due=today,"A fresh start. Quest moved to today.")));}
   else actions.Controls.Add(new Label {Text="Completed "+q.Completed+" · Awarded "+q.AwardedXP+" XP",AutoSize=true});
   details.Controls.Add(actions,0,3);panel.Controls.Add(details,1,0);
   var petPanel=new TableLayoutPanel {Dock=DockStyle.Fill,RowCount=2,ColumnCount=1,BackColor=Color.FromArgb(35,45,59),Margin=new Padding(10,0,0,0)};petPanel.RowStyles.Add(new RowStyle(SizeType.Percent,100));petPanel.RowStyles.Add(new RowStyle(SizeType.Absolute,42));petPanel.Controls.Add(new PictureBox {Dock=DockStyle.Fill,Image=Artwork(petDefinition.Art[stage]),SizeMode=PictureBoxSizeMode.Zoom,Padding=new Padding(5),AccessibleName=Journey.PetName(pet)+" familiar"},0,0);petPanel.Controls.Add(new Label {Text=(pet.EggStage<4?"GROWS\n":"GAINS XP\n")+Journey.PetName(pet),Dock=DockStyle.Fill,TextAlign=ContentAlignment.MiddleCenter,Font=new Font("Segoe UI",7.5f,FontStyle.Bold),ForeColor=Theme.Violet,AutoEllipsis=true},0,1);panel.Controls.Add(petPanel,2,0);cards.Controls.Add(panel);
  }
  void Export() {using(var dialog=new SaveFileDialog {Filter="JSON backup|*.json",FileName="adhd-warrior-"+DateTime.Today.ToString("yyyy-MM-dd")+".json"}) if(dialog.ShowDialog(this)==DialogResult.OK) {try {File.WriteAllText(dialog.FileName,Storage.Encode(data));status.Text="Backup exported.";}catch(Exception ex){MessageBox.Show(this,ex.Message,"Export failed");}}}
  void Import() {using(var dialog=new OpenFileDialog {Filter="JSON backup|*.json"}) if(dialog.ShowDialog(this)==DialogResult.OK) {try {var incoming=Storage.Decode(File.ReadAllText(dialog.FileName));if(MessageBox.Show(this,"Restore "+incoming.Quests.Count+" quests from this Windows backup? Your current progress will be retained in a recovery backup.","Restore backup",MessageBoxButtons.OKCancel)!=DialogResult.OK)return;Storage.Save(path+".before-restore-"+DateTime.Now.ToString("yyyyMMdd-HHmmssfff")+".json",data);Change(()=>{data=incoming;Journey.RefreshWeek(data,DateTime.Today);},"Backup restored.");}catch(Exception ex){MessageBox.Show(this,ex.Message,"Could not restore backup");}}}
 }
 public class QuestEditor : Form {
  public Quest Result; TextBox title=new TextBox(),steps=new TextBox(); ComboBox category=new ComboBox(),repeat=new ComboBox(),rarity=new ComboBox();DateTimePicker due=new DateTimePicker(),time=new DateTimePicker();NumericUpDown xp=new NumericUpDown();Quest original;
  public QuestEditor(Quest q) {
   original=q;Text=q==null?"New quest":"Edit quest";Size=new Size(580,690);MinimumSize=Size;StartPosition=FormStartPosition.CenterParent;Font=new Font("Segoe UI",10);BackColor=Theme.Canvas;ForeColor=Theme.Text;
   var form=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=2,RowCount=9,Padding=new Padding(22)};form.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,120));form.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));Controls.Add(form);
   title.MaxLength=500;rarity.Items.AddRange(Progression.Rarities);rarity.DropDownStyle=ComboBoxStyle.DropDownList;category.Items.AddRange(new object[]{"School","Work","Home","Life","Fun"});repeat.Items.AddRange(new object[]{"None","Daily","Weekly"});category.DropDownStyle=repeat.DropDownStyle=ComboBoxStyle.DropDownList;
   due.Format=DateTimePickerFormat.Short;due.ShowCheckBox=true;due.Checked=false;time.Format=DateTimePickerFormat.Custom;time.CustomFormat="h:mm tt";time.ShowCheckBox=true;time.Checked=false;time.Enabled=false;due.ValueChanged+=(s,e)=>time.Enabled=due.Checked;xp.Minimum=5;xp.Maximum=1000;xp.Increment=5;xp.Value=50;steps.Multiline=true;steps.ScrollBars=ScrollBars.Vertical;
   string[] labels={"Quest","Category","Due date","Due time","Repeat","Rarity","XP reward","Steps\n(one per line)"};Control[] inputs={title,category,due,time,repeat,rarity,xp,steps};
   for(int i=0;i<inputs.Length;i++){form.RowStyles.Add(new RowStyle(i==7?SizeType.Percent:SizeType.Absolute,i==7?100:48));form.Controls.Add(new Label {Text=labels[i],AutoSize=true},0,i);Theme.StyleInput(inputs[i]);inputs[i].Dock=DockStyle.Fill;form.Controls.Add(inputs[i],1,i);}
   rarity.SelectedItem=q==null?"Common":q.Rarity;rarity.SelectedIndexChanged+=(s,e)=>{if(rarity.SelectedItem!=null)xp.Value=Progression.QuestXP((string)rarity.SelectedItem);};
   category.SelectedItem=q==null?"Life":q.Category;repeat.SelectedItem=q==null?"None":q.Repeat;
   if(q!=null) {title.Text=q.Title;xp.Value=q.XP;steps.Text=String.Join(Environment.NewLine,q.Steps.Select(s=>s.Title));DateTime d;if(DateTime.TryParse(q.Due,out d)){due.Value=d;due.Checked=true;time.Enabled=true;}if(DateTime.TryParseExact(q.DueTime,"HH:mm",System.Globalization.CultureInfo.InvariantCulture,System.Globalization.DateTimeStyles.None,out d)){time.Value=d;time.Checked=true;}}
   var buttons=new FlowLayoutPanel {Dock=DockStyle.Fill,AutoSize=true};var save=new ThemedButton {Text="Save quest",AutoSize=true};var cancel=new ThemedButton {Text="Cancel",DialogResult=DialogResult.Cancel,AutoSize=true};Theme.StyleButton(save,true);Theme.StyleButton(cancel);buttons.Controls.Add(save);buttons.Controls.Add(cancel);form.Controls.Add(buttons,1,8);form.RowStyles.Add(new RowStyle(SizeType.Absolute,44));AcceptButton=save;CancelButton=cancel;
   save.Click+=(s,e)=>{
    var lines=steps.Lines.Select(x=>x.Trim()).Where(x=>x.Length>0).ToList();
    if(String.IsNullOrWhiteSpace(title.Text)||lines.Count>100||lines.Any(x=>x.Length>500)){MessageBox.Show(this,"Add a quest title and up to 100 steps of 500 characters each.");return;}
    Result=new Quest {Id=original==null?Guid.NewGuid().ToString():original.Id,Title=title.Text.Trim(),Category=(string)category.SelectedItem,Rarity=(string)rarity.SelectedItem,Repeat=(string)repeat.SelectedItem,Due=due.Checked?due.Value.ToString("yyyy-MM-dd"):"",DueTime=due.Checked&&time.Checked?time.Value.ToString("HH:mm"):"",XP=(int)xp.Value,Steps=lines.Select((x,i)=>new Step {Title=x,Done=original!=null&&i<original.Steps.Count&&original.Steps[i].Title==x&&original.Steps[i].Done}).ToList()};DialogResult=DialogResult.OK;
   };
  }
 }
}
