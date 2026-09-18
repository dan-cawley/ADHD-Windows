using System;
using System.IO;
using System.IO.Compression;
using System.Diagnostics;
using System.Reflection;
using System.Drawing;
using System.Windows.Forms;
using Microsoft.Win32;

[assembly: AssemblyTitle("ADHD Warrior Setup")]
[assembly: AssemblyDescription("Per-user installer for ADHD Warrior")]
[assembly: AssemblyCompany("ADHD Warrior")]
[assembly: AssemblyProduct("ADHD Warrior Setup")]
[assembly: AssemblyVersion("0.21.2.0")]
[assembly: AssemblyFileVersion("0.21.2.0")]

namespace AdhdWarriorSetup {
 static class Program {
  const string Version="0.21.2";
  [STAThread] static int Main(string[] args){
   Application.EnableVisualStyles();Application.SetCompatibleTextRenderingDefault(false);
   bool uninstall=Path.GetFileNameWithoutExtension(Application.ExecutablePath).StartsWith("Uninstall",StringComparison.OrdinalIgnoreCase)||Array.IndexOf(args,"--uninstall")>=0;
   bool silent=Array.IndexOf(args,"--silent")>=0;string testTarget=null;foreach(string arg in args)if(arg.StartsWith("--test-target=",StringComparison.OrdinalIgnoreCase))testTarget=arg.Substring(14);
   try{if(uninstall)Uninstall(silent,testTarget);else Install(silent,testTarget);return 0;}catch(Exception ex){if(!silent)MessageBox.Show(ex.Message,"ADHD Warrior Setup",MessageBoxButtons.OK,MessageBoxIcon.Error);return 1;}
  }
  static string DefaultTarget(){return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"Programs","ADHD Warrior");}
  static void Install(bool silent,string testTarget){
   string target=testTarget??DefaultTarget();if(testTarget==null&&Process.GetProcessesByName("ADHD Warrior").Length>0)throw new InvalidOperationException("Close ADHD Warrior before installing this update.");
   if(!silent&&MessageBox.Show("Install ADHD Warrior "+Version+" for this Windows account?\n\nYour existing progress in Local AppData will be kept.","ADHD Warrior Setup",MessageBoxButtons.OKCancel,MessageBoxIcon.Information)!=DialogResult.OK)return;
   Directory.CreateDirectory(target);using(Stream stream=Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))using(var archive=new ZipArchive(stream,ZipArchiveMode.Read)){foreach(var entry in archive.Entries){string destination=Path.GetFullPath(Path.Combine(target,entry.FullName));if(!destination.StartsWith(Path.GetFullPath(target)+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))throw new InvalidDataException("Invalid installer payload.");if(String.IsNullOrEmpty(entry.Name)){Directory.CreateDirectory(destination);continue;}Directory.CreateDirectory(Path.GetDirectoryName(destination));using(var input=entry.Open())using(var output=new FileStream(destination,FileMode.Create,FileAccess.Write,FileShare.None))input.CopyTo(output);}}
   File.Copy(Application.ExecutablePath,Path.Combine(target,"Uninstall ADHD Warrior.exe"),true);
   if(testTarget==null){string exe=Path.Combine(target,"ADHD Warrior.exe");CreateShortcut(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs),"ADHD Warrior.lnk"),exe);CreateShortcut(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),"ADHD Warrior.lnk"),exe);using(var key=Registry.CurrentUser.CreateSubKey(@"Software\Microsoft\Windows\CurrentVersion\Uninstall\ADHD Warrior")){key.SetValue("DisplayName","ADHD Warrior");key.SetValue("DisplayVersion",Version);key.SetValue("Publisher","ADHD Warrior");key.SetValue("InstallLocation",target);key.SetValue("DisplayIcon",exe);key.SetValue("UninstallString","\""+Path.Combine(target,"Uninstall ADHD Warrior.exe")+"\" --uninstall");key.SetValue("NoModify",1,RegistryValueKind.DWord);key.SetValue("NoRepair",1,RegistryValueKind.DWord);}using(var run=Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run",true)){if(run!=null&&run.GetValue("ADHD Warrior")!=null)run.SetValue("ADHD Warrior","\""+exe+"\" --background");}}
   if(!silent)MessageBox.Show("ADHD Warrior "+Version+" is installed. Your progress was left in place.","Installation complete",MessageBoxButtons.OK,MessageBoxIcon.Information);
  }
  static void Uninstall(bool silent,string testTarget){
   string target=testTarget??DefaultTarget();if(!silent&&MessageBox.Show("Remove ADHD Warrior from this computer?\n\nYour progress and backups will be kept.","Uninstall ADHD Warrior",MessageBoxButtons.OKCancel,MessageBoxIcon.Question)!=DialogResult.OK)return;
   if(testTarget==null){DeleteShortcut(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs),"ADHD Warrior.lnk"));DeleteShortcut(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory),"ADHD Warrior.lnk"));Registry.CurrentUser.DeleteSubKeyTree(@"Software\Microsoft\Windows\CurrentVersion\Uninstall\ADHD Warrior",false);using(var run=Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Run",true))if(run!=null)run.DeleteValue("ADHD Warrior",false);}
   string cleanup=Path.Combine(Path.GetTempPath(),"adhd-warrior-cleanup-"+Guid.NewGuid().ToString("N")+".cmd");File.WriteAllText(cleanup,"@echo off\r\nping 127.0.0.1 -n 3 > nul\r\nrmdir /s /q \""+target+"\"\r\ndel /q \"%~f0\"\r\n");Process.Start(new ProcessStartInfo(cleanup){UseShellExecute=true,WindowStyle=ProcessWindowStyle.Hidden});
  }
  static void CreateShortcut(string path,string target){object shell=Activator.CreateInstance(Type.GetTypeFromProgID("WScript.Shell"));object link=shell.GetType().InvokeMember("CreateShortcut",BindingFlags.InvokeMethod,null,shell,new object[]{path});link.GetType().InvokeMember("TargetPath",BindingFlags.SetProperty,null,link,new object[]{target});link.GetType().InvokeMember("WorkingDirectory",BindingFlags.SetProperty,null,link,new object[]{Path.GetDirectoryName(target)});link.GetType().InvokeMember("Description",BindingFlags.SetProperty,null,link,new object[]{"ADHD Warrior"});link.GetType().InvokeMember("Save",BindingFlags.InvokeMethod,null,link,null);}
  static void DeleteShortcut(string path){if(File.Exists(path))File.Delete(path);}
 }
}
