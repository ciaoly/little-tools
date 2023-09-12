Param(
    [Parameter(Mandatory=$true)]
    [string] $Ciph = "",
    [string] $GuideWord = "flag"
)

begin {
    if (($Ciph.Length -le 0) -or ($GuideWord.Length -le 1)){
        return;
    }
    function Test-ArithmeticProgression($arr) {
        if ($arr.Count -le 1) {
            return $False;
        }
        # Arrays.sort($arr);//先排序
        $delta = $arr[1] - $arr[0];
        foreach ($i in 2..($arr.Count - 1)) {
            if ($arr[$i] - $arr[$i - 1] -ne $delta) {
                return $False;
            }
        }
        return $True;
    }
}

process {

    $bytes = [int[]][char[]]$Ciph
    $a = @()
    $firstIndex = 0;
    $flag = "";

    foreach($i in 0..($bytes.Count - $GuideWord.Length)) {
        foreach($j in 0..($GuideWord.Length - 1)) {
            $a += $bytes[$i + $j] - [int][char]$GuideWord[$j];
        }
        if (Test-ArithmeticProgression $a) {
            $firstIndex = $i;
            break;
        } else {
#            echo "$($a -join ' ')"
            $a = @();
        }
    }

    foreach($i in $firstIndex..($bytes.Count - 1)) {
        $f = $bytes[$i] - $a[0] - $i * ($a[1] - $a[0]);
        if (($f -gt 0) -and ($f -lt 127)) {
            $flag += [char]$f;
        }
        if ($f -eq [int][char]"}") {
            break;
        }
    }

    echo "`n$($flag -join '')"
}