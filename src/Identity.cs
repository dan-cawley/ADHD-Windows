using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Windows.Forms;

namespace AdhdWarrior {
 public class AvatarDefinition {
  public string Id,Title,Asset;
  public AvatarDefinition(string id,string title,string asset){Id=id;Title=title;Asset=asset;}
  public override string ToString(){return Title;}
 }
 public static class Identity {
  public static readonly AvatarDefinition[] Avatars={
   new AvatarDefinition("standard_clothes","Standard","storybook_adah_standard"),new AvatarDefinition("standard","Archanist","storybook_adah_arcanist"),new AvatarDefinition("garden_gnome","Garden Gnome","storybook_adah_garden_gnome"),new AvatarDefinition("wood_elf","Wood Elf","storybook_adah_wood_elf"),new AvatarDefinition("micah","Micah","storybook_adah_micah"),new AvatarDefinition("stacy","Stacy","storybook_adah_stacy"),new AvatarDefinition("library","Spellbinder","storybook_adah_library"),new AvatarDefinition("emberforge","Sunforge","storybook_adah_emberforge"),new AvatarDefinition("nightveil","Moonveil","storybook_adah_nightveil")};
  public static AvatarDefinition Avatar(SaveData data){return Avatars.FirstOrDefault(x=>x.Id==data.AvatarSet)??Avatars[0];}
  public static bool Unlocked(SaveData data,AvatarDefinition avatar){if(avatar.Id=="standard_clothes")return true;var items=GearCatalog.All.Where(g=>g.Sheet==avatar.Id).ToList();return items.Count>0&&items.All(g=>data.Journey.Gear.Contains(g.Id));}
  public static string Name(SaveData data){return String.IsNullOrWhiteSpace(data.DisplayName)?"Boggins":data.DisplayName.Trim();}
  public static string SetProgress(SaveData data,AvatarDefinition avatar){var items=GearCatalog.All.Where(g=>g.Sheet==avatar.Id).ToList();return avatar.Id=="standard_clothes"?"Always available":items.Count(g=>data.Journey.Gear.Contains(g.Id))+" / "+items.Count+" matching pieces";}
  public static string FromIosAsset(string asset){string key=(asset??"").ToLowerInvariant();var match=Avatars.FirstOrDefault(x=>key.Contains(x.Asset.Replace("storybook_","").ToLowerInvariant())||key.Contains(x.Asset.ToLowerInvariant()));return match==null?"standard_clothes":match.Id;}
  public static void Validate(SaveData data){if(data.DisplayName==null||data.DisplayName.Length>80||String.IsNullOrWhiteSpace(data.DisplayName)||!Avatars.Any(x=>x.Id==data.AvatarSet)||!Unlocked(data,Avatar(data)))throw new InvalidDataException("The backup contains invalid character identity data.");}
 }
 public partial class MainWindow {
  void EditIdentity(){using(var editor=new IdentityEditor(data))if(editor.ShowDialog(this)==DialogResult.OK)Change(()=>{data.DisplayName=editor.PlayerName;data.AvatarSet=editor.AvatarId;},"Character identity saved.");}
  void RenameFamiliar(Familiar pet){using(var dialog=new NameEditor("Name familiar",Journey.PetName(pet)))if(dialog.ShowDialog(this)==DialogResult.OK)Change(()=>pet.Name=dialog.Result,"Familiar name saved.");}
 }
 public class IdentityEditor : Form {
  public string PlayerName,AvatarId;TextBox name=new TextBox();ComboBox avatar=new ComboBox();
  public IdentityEditor(SaveData data){Text="Customize character";Size=new Size(530,300);StartPosition=FormStartPosition.CenterParent;Font=new Font("Segoe UI",10);BackColor=Theme.Canvas;ForeColor=Theme.Text;var form=new TableLayoutPanel {Dock=DockStyle.Fill,ColumnCount=2,RowCount=4,Padding=new Padding(24)};form.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute,130));form.ColumnStyles.Add(new ColumnStyle(SizeType.Percent,100));Controls.Add(form);form.Controls.Add(new Label {Text="Display name",AutoSize=true},0,0);name.Text=Identity.Name(data);name.MaxLength=80;name.Dock=DockStyle.Fill;Theme.StyleInput(name);form.Controls.Add(name,1,0);form.Controls.Add(new Label {Text="Avatar theme",AutoSize=true},0,1);avatar.DropDownStyle=ComboBoxStyle.DropDownList;avatar.Dock=DockStyle.Fill;Theme.StyleInput(avatar);foreach(var option in Identity.Avatars.Where(x=>Identity.Unlocked(data,x)))avatar.Items.Add(option);avatar.SelectedItem=avatar.Items.Cast<AvatarDefinition>().FirstOrDefault(x=>x.Id==data.AvatarSet)??avatar.Items[0];form.Controls.Add(avatar,1,1);form.Controls.Add(new Label {Text="Complete every equipment piece in a set to unlock its avatar theme.",AutoSize=true,MaximumSize=new Size(340,0),ForeColor=Theme.Muted},1,2);var buttons=new FlowLayoutPanel {AutoSize=true};var save=new ThemedButton {Text="Save identity",AutoSize=true};var cancel=new ThemedButton {Text="Cancel",AutoSize=true,DialogResult=DialogResult.Cancel};Theme.StyleButton(save,true);Theme.StyleButton(cancel);buttons.Controls.Add(save);buttons.Controls.Add(cancel);form.Controls.Add(buttons,1,3);AcceptButton=save;CancelButton=cancel;save.Click+=(s,e)=>{if(String.IsNullOrWhiteSpace(name.Text)){MessageBox.Show(this,"Add a display name.");return;}PlayerName=name.Text.Trim();AvatarId=((AvatarDefinition)avatar.SelectedItem).Id;DialogResult=DialogResult.OK;};}
 }
 public class NameEditor : Form {
  public string Result;TextBox name=new TextBox();
  public NameEditor(string title,string current){Text=title;Size=new Size(480,210);StartPosition=FormStartPosition.CenterParent;Font=new Font("Segoe UI",10);BackColor=Theme.Canvas;ForeColor=Theme.Text;var form=new FlowLayoutPanel {Dock=DockStyle.Fill,FlowDirection=FlowDirection.TopDown,WrapContents=false,Padding=new Padding(24)};Controls.Add(form);form.Controls.Add(new Label {Text="Name",AutoSize=true});name.Text=current;name.Width=400;name.MaxLength=80;Theme.StyleInput(name);form.Controls.Add(name);var row=new FlowLayoutPanel {AutoSize=true,Margin=new Padding(0,16,0,0)};var save=new ThemedButton {Text="Save name",AutoSize=true};var cancel=new ThemedButton {Text="Cancel",AutoSize=true,DialogResult=DialogResult.Cancel};Theme.StyleButton(save,true);Theme.StyleButton(cancel);row.Controls.Add(save);row.Controls.Add(cancel);form.Controls.Add(row);AcceptButton=save;CancelButton=cancel;save.Click+=(s,e)=>{if(String.IsNullOrWhiteSpace(name.Text)){MessageBox.Show(this,"Add a familiar name.");return;}Result=name.Text.Trim();DialogResult=DialogResult.OK;};}
 }
}
