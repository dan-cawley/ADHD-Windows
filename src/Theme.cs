using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Windows.Forms;

namespace AdhdWarrior {
 public static class Theme {
  public static readonly Color Canvas=Color.FromArgb(19,25,38), Sidebar=Color.FromArgb(14,20,31), Surface=Color.FromArgb(29,39,55), Raised=Color.FromArgb(37,50,68), Line=Color.FromArgb(65,81,99);
  public static readonly Color Text=Color.FromArgb(242,239,226), Muted=Color.FromArgb(179,195,208), Gold=Color.FromArgb(237,193,105), Emerald=Color.FromArgb(96,211,167), Violet=Color.FromArgb(189,168,239), Blue=Color.FromArgb(135,192,237), Coral=Color.FromArgb(245,154,132);
  public static Color Category(string category){switch(category){case "School":return Violet;case "Work":return Blue;case "Home":return Gold;case "Fun":return Coral;default:return Emerald;}}
  public static Color Rarity(string rarity){switch(rarity){case "UNCOMMON":return Emerald;case "RARE":return Blue;case "EPIC":return Violet;case "UNIQUE":return Gold;default:return Muted;}}
  public static void StyleButton(Button b,bool primary=false){
   b.FlatStyle=FlatStyle.Flat;b.UseVisualStyleBackColor=false;b.BackColor=primary?Color.FromArgb(36,111,86):Raised;b.ForeColor=Text;
   b.FlatAppearance.BorderColor=primary?Color.FromArgb(82,171,133):Line;b.FlatAppearance.MouseOverBackColor=primary?Color.FromArgb(43,132,100):Color.FromArgb(50,68,88);b.FlatAppearance.MouseDownBackColor=Color.FromArgb(55,83,94);b.Cursor=Cursors.Hand;
  }
  public static void StyleInput(Control c){c.BackColor=Raised;c.ForeColor=Text;if(c is TextBox)((TextBox)c).BorderStyle=BorderStyle.FixedSingle;}
  public static void Frame(Control c,Color accent){c.Paint+=(s,e)=>{using(var border=new Pen(Line))e.Graphics.DrawRectangle(border,0,0,c.Width-1,c.Height-1);using(var bar=new SolidBrush(accent))e.Graphics.FillRectangle(bar,0,0,4,c.Height);};}
 }
 public class ThemedButton : Button {
  protected override void OnPaint(PaintEventArgs e){
   if(Enabled){base.OnPaint(e);return;}
   using(var fill=new SolidBrush(Theme.Surface))e.Graphics.FillRectangle(fill,ClientRectangle);
   using(var border=new Pen(Theme.Line))e.Graphics.DrawRectangle(border,0,0,Width-1,Height-1);
   TextRenderer.DrawText(e.Graphics,Text,Font,ClientRectangle,Theme.Muted,TextFormatFlags.HorizontalCenter|TextFormatFlags.VerticalCenter|TextFormatFlags.EndEllipsis);
  }
 }
 public class JourneyMeter : Control {
  public int Value,Maximum=100;public Color Accent=Theme.Emerald;
  public JourneyMeter(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer,true);AccessibleRole=AccessibleRole.ProgressBar;Height=12;TabStop=false;}
  protected override void OnPaint(PaintEventArgs e){base.OnPaint(e);int h=Math.Max(6,Height/3),y=(Height-h)/2;using(var track=new SolidBrush(Theme.Canvas))e.Graphics.FillRectangle(track,0,y,Width,h);int w=(int)(Width*Math.Min(1,Math.Max(0,(double)Value/Math.Max(1,Maximum))));if(w>0)using(var fill=new LinearGradientBrush(new Rectangle(0,y,Math.Max(1,Width),h),Accent,ControlPaint.Light(Accent),0f))e.Graphics.FillRectangle(fill,0,y,w,h);}
 }
 public class JournalBanner : Panel {
  public JournalBanner(){DoubleBuffered=true;BackColor=Theme.Surface;}
  protected override void OnPaintBackground(PaintEventArgs e){if(BackgroundImage!=null)ForestLayout.DrawCover(e.Graphics,BackgroundImage,ClientRectangle);using(var gradient=new LinearGradientBrush(ClientRectangle,Color.FromArgb(220,15,31,37),Color.FromArgb(30,22,28,47),0f))e.Graphics.FillRectangle(gradient,ClientRectangle);using(var border=new Pen(Theme.Line))e.Graphics.DrawRectangle(border,0,0,Width-1,Height-1);}
 }
 public class ForestLayout : TableLayoutPanel {
  public ForestLayout(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.ResizeRedraw|ControlStyles.SupportsTransparentBackColor,true);UpdateStyles();}
  public static void DrawCover(Graphics g,Image art,Rectangle bounds){if(bounds.Width<=0||bounds.Height<=0)return;float scale=Math.Max((float)bounds.Width/art.Width,(float)bounds.Height/art.Height);float w=art.Width*scale,h=art.Height*scale;g.DrawImage(art,bounds.X+(bounds.Width-w)/2,bounds.Y+(bounds.Height-h)/2,w,h);}
  protected override void OnPaintBackground(PaintEventArgs e){using(var fill=new SolidBrush(Theme.Canvas))e.Graphics.FillRectangle(fill,ClientRectangle);if(BackgroundImage!=null)DrawCover(e.Graphics,BackgroundImage,ClientRectangle);using(var shade=new SolidBrush(Color.FromArgb(170,12,20,32)))e.Graphics.FillRectangle(shade,ClientRectangle);}
 }
 public class BufferedFlowLayoutPanel : FlowLayoutPanel {
  public BufferedFlowLayoutPanel(){SetStyle(ControlStyles.UserPaint|ControlStyles.AllPaintingInWmPaint|ControlStyles.OptimizedDoubleBuffer|ControlStyles.ResizeRedraw|ControlStyles.SupportsTransparentBackColor,true);UpdateStyles();}
 }
 public class PokerCardPanel : TableLayoutPanel {
  public Color Accent=Theme.Gold;
  public PokerCardPanel(){DoubleBuffered=true;BackColor=Theme.Surface;Padding=new Padding(12);Margin=new Padding(0,0,16,16);Size=new Size(286,400);}
  protected override void OnResize(EventArgs e){base.OnResize(e);if(Width<2||Height<2)return;using(var path=new GraphicsPath()){int radius=18;path.AddArc(0,0,radius,radius,180,90);path.AddArc(Width-radius-1,0,radius,radius,270,90);path.AddArc(Width-radius-1,Height-radius-1,radius,radius,0,90);path.AddArc(0,Height-radius-1,radius,radius,90,90);path.CloseFigure();Region=new Region(path);}}
  protected override void OnPaint(PaintEventArgs e){base.OnPaint(e);e.Graphics.SmoothingMode=SmoothingMode.AntiAlias;using(var path=new GraphicsPath()){int radius=18;path.AddArc(1,1,radius,radius,180,90);path.AddArc(Width-radius-2,1,radius,radius,270,90);path.AddArc(Width-radius-2,Height-radius-2,radius,radius,0,90);path.AddArc(1,Height-radius-2,radius,radius,90,90);path.CloseFigure();using(var border=new Pen(Accent,2))e.Graphics.DrawPath(border,path);}}
 }
 public partial class MainWindow {
  protected override CreateParams CreateParams {get {var cp=base.CreateParams;cp.ExStyle|=0x02000000;return cp;}}
  System.Collections.Generic.Dictionary<string,Button> navigation=new System.Collections.Generic.Dictionary<string,Button>();
  Label[] metricValues=new Label[4];
  Control BuildMetrics(){
   var row=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=4,RowCount=1,Margin=Padding.Empty};
   string[] names={"WARRIOR LEVEL","TOTAL XP","COIN POUCH","DAY STREAK"};Color[] colors={Theme.Violet,Theme.Blue,Theme.Gold,Theme.Emerald};
   for(int i=0;i<4;i++){
    row.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,25));var tile=new Panel {Dock=DockStyle.Fill,BackColor=Theme.Surface,Padding=new Padding(12,7,8,4),Margin=new Padding(0,0,i==3?0:10,12)};Theme.Frame(tile,colors[i]);
    var name=new Label {Text=names[i],Dock=DockStyle.Top,Height=21,Font=new Font("Segoe UI",8,FontStyle.Bold),ForeColor=Theme.Muted};
    metricValues[i]=new Label {Dock=DockStyle.Fill,Font=new Font("Segoe UI",18,FontStyle.Bold),ForeColor=colors[i],AccessibleName=names[i]};tile.Controls.Add(metricValues[i]);tile.Controls.Add(name);row.Controls.Add(tile,i,0);
   }return row;
  }
  void RefreshTheme(){
   metricValues[0].Text=Progression.Level(data.XP).ToString();metricValues[1].Text=data.XP.ToString("N0");metricValues[2].Text=data.Coins.ToString("N0");metricValues[3].Text=Game.Streak(data,DateTime.Today).ToString();
   string[] labels={"Warrior level","Total XP","Coins","Day streak"};for(int i=0;i<4;i++)metricValues[i].AccessibleName=labels[i]+": "+metricValues[i].Text;
   foreach(var pair in navigation){bool active=pair.Key==view;pair.Value.BackColor=active?Color.FromArgb(38,72,72):Theme.Sidebar;pair.Value.ForeColor=active?Theme.Gold:Theme.Muted;pair.Value.AccessibleDescription=active?"Current page":"Open "+pair.Key;pair.Value.Invalidate();}
  }
  void ShowWelcome(){
   var banner=new JournalBanner {Height=165,Margin=new Padding(0,0,0,16),Padding=new Padding(22,18,18,14),BackgroundImage=Artwork("forest-twilight")};
   var words=new Panel {Dock=DockStyle.Fill,BackColor=Color.Transparent};
   var eyebrow=new Label {Text="YOUR DAILY ADVENTURE",Dock=DockStyle.Top,Height=24,Font=new Font("Segoe UI",8,FontStyle.Bold),ForeColor=Theme.Gold,BackColor=Color.Transparent};
   var title=new Label {Text="Every small step is a victory.",Dock=DockStyle.Top,Height=42,Font=new Font("Georgia",20),ForeColor=Theme.Text,BackColor=Color.Transparent,AutoEllipsis=true};
   var subtitle=new Label {Text="Choose one quest. Your companion grows with you.",Dock=DockStyle.Fill,ForeColor=Theme.Muted,BackColor=Color.Transparent};
   words.Controls.Add(subtitle);words.Controls.Add(title);words.Controls.Add(eyebrow);banner.Controls.Add(words);cards.Controls.Add(banner);
  }
 }
}
