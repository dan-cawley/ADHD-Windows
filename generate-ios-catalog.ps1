param([string]$Source = 'C:\Users\Dan\Documents\adhd\adhd\adhd\SharedGameModels.swift')
$ErrorActionPreference='Stop'
$swift=Get-Content -LiteralPath $Source -Raw
$slots=@('HEAD','CHEST','HANDS','LEGS','FEET','WEAPON','OFFHAND','ACCESSORY','RING')
$rarities=@('UNCOMMON','RARE','UNCOMMON','UNCOMMON','RARE','EPIC','RARE','UNCOMMON','EPIC')
$sets=@{}
foreach($m in [regex]::Matches($swift,'buildSet\(\s*setID: "([^"]+)",\s*setName: "([^"]+)",\s*names: \[([^\]]+)\]')) {
 $id=$m.Groups[1].Value; $names=[regex]::Matches($m.Groups[3].Value,'"([^"]+)"'); $rows=@()
 for($i=0;$i -lt $names.Count;$i++) {$rows+='new GearDefinition("{0}_{1}","{2}","{3}","{4}","{0}",{5}),' -f $id,($i+1),$names[$i].Groups[1].Value,$rarities[$i],$slots[$i],$i}
 if($rows.Count -ne 9){throw 'Expected nine equipment pieces per set'}
 $sets[$id]=$rows
}
foreach($m in [regex]::Matches($swift,'LootItem\(id: "([^"]+)", name: "([^"]+)", rarity: rarityForTile\((\d)\).*?slot: \.(\w+), eggBaseLevel: nil, spriteTileIndex: (\d), spriteSheetSet: "([^"]+)"')) {
 $id=$m.Groups[6].Value
 $sets[$id]+=@('new GearDefinition("{0}","{1}","{2}","{3}","{4}",{5}),' -f $m.Groups[1].Value,$m.Groups[2].Value,$rarities[[int]$m.Groups[3].Value-1],$m.Groups[4].Value.ToUpperInvariant(),$id,([int]$m.Groups[5].Value-1))
}
$lines=@('// Generated from iOS SharedGameModels.swift. Sprite tiles are converted from one-based to zero-based.','namespace AdhdWarrior { public static class GearCatalog { public static readonly GearDefinition[] All = {')
foreach($id in @('library','standard','standard_clothes','garden_gnome','wood_elf','micah','stacy','emberforge','nightveil')) {if($sets[$id].Count -ne 9){throw "Invalid set $id"};$lines+=$sets[$id]}
$lines+='};}}'
[IO.File]::WriteAllText((Join-Path $PSScriptRoot 'src\GearCatalog.cs'), ($lines -join "`n") + "`n", (New-Object Text.UTF8Encoding($false)))
