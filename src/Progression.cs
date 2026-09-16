using System;
using System.Linq;
namespace AdhdWarrior {
 public static class Progression {
  // Authoritative thresholds and quest defaults from the iOS app.
  public static readonly int[] Thresholds={0,300,900,2700,6500,14000,23000,34000,48000,64000,85000,100000,120000,140000,165000,195000,225000,265000,305000,355000};
  public static readonly string[] Rarities={"Common","Uncommon","Rare","Epic","Unique"};
  public static int Level(int xp){return Math.Max(1,Thresholds.Count(t=>xp>=t));}
  public static int Remaining(int xp){int level=Level(xp);return level==20?0:Thresholds[level]-xp;}
  public static int Current(int xp){return Level(xp)==20?1:xp-Thresholds[Level(xp)-1];}
  public static int Span(int xp){int level=Level(xp);return level==20?1:Thresholds[level]-Thresholds[level-1];}
  public static string NextLabel(int xp){return Level(xp)==20?"Maximum level reached. Your adventure continues.":Remaining(xp).ToString("N0")+" XP to level "+(Level(xp)+1)+".";}
  public static int QuestXP(string rarity){int index=Array.IndexOf(Rarities,rarity);if(index<0)throw new ArgumentException("Unknown rarity.");return new[]{50,75,100,150,225}[index];}
 }
}
