<#
.Synopsis
	Generates Hakchi2 CE Game List.
	
.Description
	Powershell script that generates an HTML file listing game information from your Hakchi2 CE folder
	Assuming Hakchi version https://github.com/TeamShinkansen/Hakchi2-CE/
	
.Notes
	Author        : Josh Drummond
	Version       : 1.0 - 12/22/2021 - Initial release
	Source        : https://github.com/joshdrummond/Hakchi2CEGameListExporter/
	
.Example
	.\Export-Hakchi2CEGameList.ps1
	-----------
	Description
	Generates and outputs ClassicMiniGameList.html in the current directory.  This script should run from the root of your Hakchi2 CE installation.

    Requires Execution Policy:
        Get-ExecutionPolicy -list
        Set-ExecutionPolicy Unrestricted CurrentUser
#>

# Read Hakchi environment
$HakchiConfig = Get-Content -Raw -Path .\config\config.json | ConvertFrom-Json
$ConsoleType = $HakchiConfig.consoleType
$ConsoleNames = @('NES','Famicom','SNES_EUR','SNES_USA','SuperFamicom','ShonenJump','MD_JPN','MD_USA','MD_EUR','MD_ASIA')
$ConsoleTypeName = 'Unknown'
if (($ConsoleType -ge 0) -and ($ConsoleType -le 9))
{
    $ConsoleTypeName = $ConsoleNames[$ConsoleType]
}

# Parse Files to Game List
$GameList = @{}
Foreach ($Game in $HakchiConfig.gamesCollectionSettings.$ConsoleTypeName.SelectedGames)
{
    if (Test-Path -Path .\games\$Game\$Game.desktop)
    {
        $GameInfo = @{}
        $data = Get-Content -Raw -Path .\games\$Game\metadata.json | ConvertFrom-Json
        $GameInfo.add('Filename', $data.OriginalFilename)
        if ($data.System)
        {
            $GameInfo.add('System', $data.System)
        }
        else
        {
            $GameInfo.add('System', $data.Core)
        }
        $data = Get-Content -Path .\games\$Game\$Game.desktop
        $GameInfo.add('Name', $data[4].Substring($data[4].IndexOf("=")+1))
        $GameList.add($Game, $GameInfo)
    }
}
Foreach ($Game in $HakchiConfig.gamesCollectionSettings.$ConsoleTypeName.OriginalGames)
{
    if (Test-Path -Path .\games_originals\$Game\$Game.desktop)
    {
        $GameInfo = @{}
        $data = Get-Content -Path .\games_originals\$Game\$Game.desktop
        $GameInfo.add('Name', $data[4].Substring($data[4].IndexOf("=")+1))
        $GameInfo.add('Filename', 'Original')
        $GameInfo.add('System', $ConsoleTypeName)
        $GameList.add($Game, $GameInfo)
    }
}

#Generate HTML File
$HTML = @"
<html>
<head>
<title>Classic Mini Game List</title>
<style>
*{font-family:verdana,arial,helvetica,sans-serif;font-size:12px;}
table{margin:30px auto;border-spacing:0;width:90%;border:1px solid #f2f2f2;}
th{font-weight:bold;background-color:#666;color:#fff;}
th a{color:#fff;}
th a:hover{text-decoration:none;}
th:hover{background-color:#333;}
th,td{text-align:left;padding:5px;}
tr:nth-child(even){background-color:#f2f2f2;}
tr:hover{background-color:#d7e9fc;}
a{text-decoration:none;}
a:hover{text-decoration:underline;}
pre{width:80%;margin:30px auto;}
@media print{pre{width:100%;}table{margin:0 auto;border-spacing:0;width:100%;border:0;}th span{display:none;}th,td{border-bottom:1px dotted #ddd;}}
</style>
<script>
function TableSort(t){if(this.tbl=document.getElementById(t),this.lastSortedTh=null,this.tbl&&"TABLE"==this.tbl.nodeName){for(var e=this.tbl.tHead.rows[0].cells,a=0;e[a];a++)e[a].className.match(/asc|dsc/)&&(this.lastSortedTh=e[a]);this.makeSortable()}}
function bubbleSort(t,e){var a,s;1===e?(a=0,s=t.length):-1===e&&(a=t.length-1,s=-1);for(var r=!0;r;){r=!1;for(var l=a;l!=s;l+=e)if(t[l+e]&&t[l].value>t[l+e].value){var o=t[l],c=t[l+e],n=o;t[l]=c,t[l+e]=n,r=!0}}return t}
TableSort.prototype.makeSortable=function(){for(var t=this.tbl.tHead.rows[0].cells,e=0;t[e];e++){t[e].cIdx=e;var a=document.createElement("a");a.href="#",a.title="Sort",a.style.display="block",a.innerHTML=t[e].innerHTML,a.onclick=function(t){return function(){return t.sortCol(this),!1}}(this),t[e].innerHTML="",t[e].appendChild(a)}},TableSort.prototype.sortCol=function(t){for(var e=this.tbl.rows,a=[],s=[],r=0,l=0,o=t.parentNode,c=o.cIdx,n=1;e[n];n++){var i=e[n].cells[c],h=i.textContent?i.textContent:i.innerText,b=h.replace(/(\$|\,|\s)/g,"");parseFloat(b)==b?s[l++]={value:Number(b),row:e[n]}:a[r++]={value:h,row:e[n]}}var d,u,m;o.className.match("asc")?(u=bubbleSort(a,-1),m=bubbleSort(s,-1),o.className=o.className.replace(/asc/,"dsc")):(u=bubbleSort(s,1),m=bubbleSort(a,1),o.className.match("dsc")?o.className=o.className.replace(/dsc/,"asc"):o.className+="asc"),this.lastSortedTh&&o!=this.lastSortedTh&&(this.lastSortedTh.className=this.lastSortedTh.className.replace(/dsc|asc/g,"")),this.lastSortedTh=o,d=u.concat(m);var S=this.tbl.tBodies[0];for(n=0;d[n];n++)S.appendChild(d[n].row)},
window.onload=function(){new TableSort("gamelist");var rows=document.getElementById("gamelist").rows.length;document.getElementById("total").innerHTML=rows;};
</script>
</head>
<body>
<h1>Classic Mini Game List</h1>
<table id="gamelist">
<thead>
<tr><th>Title&nbsp;<span>&#x25BC;&#x25B2;</span></th><th>System&nbsp;<span>&#x25BC;&#x25B2;</span></th><th>Filename&nbsp;<span>&#x25BC;&#x25B2;</span></th></tr>
</thead>
<tbody>
"@
Foreach ($Game in ($GameList.Keys | Sort))
{
    $HTML += "<tr><td>"+$GameList.$Game.Name+"</td><td>"+$GameList.$Game.System+"</td><td>"+$GameList.$Game.Filename+"</td></tr>`n"
}
$HTML += "</tbody></table><b>Total number of games: <span id='total'></span></b></body></html>"

$HTML | Out-File -Encoding utf8 '.\ClassicMiniGameList.html'
