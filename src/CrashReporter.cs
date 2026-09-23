using System;
using System.IO;
using System.Linq;
using System.Drawing;
using System.Diagnostics;
using System.Windows.Forms;

namespace AdhdWarrior {
 public static class CrashReporter {
  public static string Write(Exception error){string folder=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"AdhdWarrior","logs");Directory.CreateDirectory(folder);string path=Path.Combine(folder,"crash-"+DateTime.Now.ToString("yyyyMMdd-HHmmssfff")+".txt");File.WriteAllText(path,"ADHD Warrior Windows 0.24.2\r\n"+DateTime.Now.ToString("O")+"\r\nWindows "+Environment.OSVersion+"\r\n.NET "+Environment.Version+"\r\n\r\n"+error);foreach(var old in Directory.GetFiles(folder,"crash-*.txt").OrderByDescending(File.GetCreationTimeUtc).Skip(10))try{File.Delete(old);}catch{}return path;}
  public static void Show(Exception error){string path="";try{path=Write(error);}catch{}using(var form=new Form {Text="ADHD Warrior recovery",Size=new Size(620,310),StartPosition=FormStartPosition.CenterScreen,Font=new Font("Segoe UI",10),BackColor=Theme.Canvas,ForeColor=Theme.Text}){var text=new Label {Dock=DockStyle.Fill,Padding=new Padding(24),Text="ADHD Warrior could not continue. Your save was not overwritten.\n\n"+error.Message+(path==""?"":"\n\nA crash report was saved to:\n"+path),AutoEllipsis=true};var buttons=new FlowLayoutPanel {Dock=DockStyle.Bottom,Height=60,FlowDirection=FlowDirection.RightToLeft,Padding=new Padding(12)};var close=new Button {Text="Close",AutoSize=true,DialogResult=DialogResult.OK};buttons.Controls.Add(close);if(path!=""){var open=new Button {Text="Open recovery folder",AutoSize=true};open.Click+=(s,e)=>{try{Process.Start(Path.GetDirectoryName(path));}catch{}};buttons.Controls.Add(open);}form.Controls.Add(text);form.Controls.Add(buttons);form.AcceptButton=close;form.ShowDialog();}}
 }
}
