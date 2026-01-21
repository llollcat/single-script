#!/bin/bash

#source: https://github.com/rebootuser/LinEnum
#modified script version

version="version 0.4-mod"
ERRORFILE=script.errors


system_info()
{
    echo -e "\e[00;33m### SYSTEM ##############################################\e[00m"
    
    #basic kernel info
    unameinfo=`uname -a 2>/dev/null`
    if [ "$unameinfo" ]; then
        echo -e "\e[00;31m[-] Kernel information:\e[00m\n$unameinfo"
        echo -e "\n"
    fi
    
    procver=`cat /proc/version 2>/dev/null`
    if [ "$procver" ]; then
        echo -e "\e[00;31m[-] Kernel information (continued):\e[00m\n$procver"
        echo -e "\n"
    fi
    
    #search all *-release files for version info
    release=`cat /etc/*-release 2>/dev/null`
    if [ "$release" ]; then
        echo -e "\e[00;31m[-] Specific release information:\e[00m\n$release"
        echo -e "\n"
    fi
    
    #target hostname info
    hostnamed=`hostname 2>/dev/null`
    if [ "$hostnamed" ]; then
        echo -e "\e[00;31m[-] Hostname:\e[00m\n$hostnamed"
        echo -e "\n"
        sleep 2
    fi
}

user_info()
{
    echo -e "\e[00;33m### USER/GROUP ##########################################\e[00m"
    
    #current user details
    currusr=`id 2>/dev/null`
    if [ "$currusr" ]; then
        echo -e "\e[00;31m[-] Current user/group info:\e[00m\n$currusr"
        echo -e "\n"
    fi
    
    #last logged on user information
    lastlogedonusrs=`lastlog 2>/dev/null |grep -v "Never" 2>/dev/null`
    if [ "$lastlogedonusrs" ]; then
        echo -e "\e[00;31m[-] Users that have previously logged onto the system:\e[00m\n$lastlogedonusrs"
        echo -e "\n"
    fi
    
    #who else is logged on
    loggedonusrs=`w 2>/dev/null`
    if [ "$loggedonusrs" ]; then
        echo -e "\e[00;31m[-] Who else is logged on:\e[00m\n$loggedonusrs"
        echo -e "\n"
    fi
    
    #lists all id's and respective group(s)
    grpinfo=`for i in $(cut -d":" -f1 /etc/passwd 2>/dev/null);do id $i;done 2>/dev/null`
    if [ "$grpinfo" ]; then
        echo -e "\e[00;31m[-] Group memberships:\e[00m\n$grpinfo"
        echo -e "\n"
    fi
    
    #added by phackt - look for adm group (thanks patrick)
    adm_users=$(echo -e "$grpinfo" | grep "(adm)")
    if [[ ! -z $adm_users ]];
    then
        echo -e "\e[00;31m[-] It looks like we have some admin users:\e[00m\n$adm_users"
        echo -e "\n"
    fi
    
    #checks to see if any hashes are stored in /etc/passwd (depreciated  *nix storage method)
    hashesinpasswd=`grep -v '^[^:]*:[x]' /etc/passwd 2>/dev/null`
    if [ "$hashesinpasswd" ]; then
        echo -e "\e[00;33m[+] It looks like we have password hashes in /etc/passwd!\e[00m\n$hashesinpasswd"
        echo -e "\n"
    fi
    
    #contents of /etc/passwd
    readpasswd=`cat /etc/passwd 2>/dev/null`
    if [ "$readpasswd" ]; then
        echo -e "\e[00;31m[-] Contents of /etc/passwd:\e[00m\n$readpasswd"
        echo -e "\n"
    fi
    
    #checks to see if the shadow file can be read
    readshadow=`cat /etc/shadow 2>/dev/null`
    if [ "$readshadow" ]; then
        echo -e "\e[00;33m[+] We can read the shadow file!\e[00m\n$readshadow"
        echo -e "\n"
    fi
    
    #checks to see if /etc/master.passwd can be read - BSD 'shadow' variant
    readmasterpasswd=`cat /etc/master.passwd 2>/dev/null`
    if [ "$readmasterpasswd" ]; then
        echo -e "\e[00;33m[+] We can read the master.passwd file!\e[00m\n$readmasterpasswd"
        echo -e "\n"
    fi
    
    
    #all root accounts (uid 0)
    superman=`grep -v -E "^#" /etc/passwd 2>/dev/null| awk -F: '$3 == 0 { print $1}' 2>/dev/null`
    if [ "$superman" ]; then
        echo -e "\e[00;31m[-] Super user account(s):\e[00m\n$superman"
        echo -e "\n"
    fi
    
    #pull out vital sudoers info
    sudoers=`grep -v -e '^$' /etc/sudoers 2>/dev/null |grep -v "#" 2>/dev/null`
    if [ "$sudoers" ]; then
        echo -e "\e[00;31m[-] Sudoers configuration (condensed):\e[00m$sudoers"
        echo -e "\n"
    fi
    
    #can we sudo without supplying a password
    sudoperms=`echo '' | sudo -S -l -k 2>/dev/null`
    if [ "$sudoperms" ]; then
        echo -e "\e[00;33m[+] We can sudo without supplying a password!\e[00m\n$sudoperms"
        echo -e "\n"
    fi
    
    #check sudo perms - authenticated
    if [ "$sudopass" ]; then
        if [ "$sudoperms" ]; then
            :
        else
            sudoauth=`echo $userpassword | sudo -S -l -k 2>/dev/null`
            if [ "$sudoauth" ]; then
                echo -e "\e[00;33m[+] We can sudo when supplying a password!\e[00m\n$sudoauth"
                echo -e "\n"
            fi
        fi
    fi
    
    ##known 'good' breakout binaries (cleaned to parse /etc/sudoers for comma separated values) - authenticated
    if [ "$sudopass" ]; then
        if [ "$sudoperms" ]; then
            :
        else
            sudopermscheck=`echo $userpassword | sudo -S -l -k 2>/dev/null | xargs -n 1 2>/dev/null|sed 's/,*$//g' 2>/dev/null | grep -w $binarylist 2>/dev/null`
            if [ "$sudopermscheck" ]; then
                echo -e "\e[00;33m[-] Possible sudo pwnage!\e[00m\n$sudopermscheck"
                echo -e "\n"
            fi
        fi
    fi
    
    #known 'good' breakout binaries (cleaned to parse /etc/sudoers for comma separated values)
    sudopwnage=`echo '' | sudo -S -l -k 2>/dev/null | xargs -n 1 2>/dev/null | sed 's/,*$//g' 2>/dev/null | grep -w $binarylist 2>/dev/null`
    if [ "$sudopwnage" ]; then
        echo -e "\e[00;33m[+] Possible sudo pwnage!\e[00m\n$sudopwnage"
        echo -e "\n"
    fi
    
    #who has sudoed in the past
    whohasbeensudo=`find /home -name .sudo_as_admin_successful 2>/dev/null`
    if [ "$whohasbeensudo" ]; then
        echo -e "\e[00;31m[-] Accounts that have recently used sudo:\e[00m\n$whohasbeensudo"
        echo -e "\n"
    fi
    
    #checks to see if roots home directory is accessible
    rthmdir=`ls -ahl /root/ 2>/dev/null`
    if [ "$rthmdir" ]; then
        echo -e "\e[00;33m[+] We can read root's home directory!\e[00m\n$rthmdir"
        echo -e "\n"
    fi
    
    #displays /home directory permissions - check if any are lax
    homedirperms=`ls -ahl /home/ 2>/dev/null`
    if [ "$homedirperms" ]; then
        echo -e "\e[00;31m[-] Are permissions on /home directories lax:\e[00m\n$homedirperms"
        echo -e "\n"
    fi
    
    #looks for files we can write to that don't belong to us
    if [ "$thorough" = "1" ]; then
        grfilesall=`find / -writable ! -user \`whoami\` -type f ! -path "/proc/*" ! -path "/sys/*" -exec ls -al {} \; 2>/dev/null`
        if [ "$grfilesall" ]; then
            echo -e "\e[00;31m[-] Files not owned by user but writable by group:\e[00m\n$grfilesall"
            echo -e "\n"
        fi
    fi
    
    #looks for files that belong to us
    if [ "$thorough" = "1" ]; then
        ourfilesall=`find / -user \`whoami\` -type f ! -path "/proc/*" ! -path "/sys/*" -exec ls -al {} \; 2>/dev/null`
        if [ "$ourfilesall" ]; then
            echo -e "\e[00;31m[-] Files owned by our user:\e[00m\n$ourfilesall"
            echo -e "\n"
        fi
    fi
    
    #looks for hidden files
    if [ "$thorough" = "1" ]; then
        hiddenfiles=`find / -name ".*" -type f ! -path "/proc/*" ! -path "/sys/*" -exec ls -al {} \; 2>/dev/null`
        if [ "$hiddenfiles" ]; then
            echo -e "\e[00;31m[-] Hidden files:\e[00m\n$hiddenfiles"
            echo -e "\n"
        fi
    fi
    
    #looks for world-reabable files within /home - depending on number of /home dirs & files, this can take some time so is only 'activated' with thorough scanning switch
    if [ "$thorough" = "1" ]; then
        wrfileshm=`find /home/ -perm -4 -type f -exec ls -al {} \; 2>/dev/null`
        if [ "$wrfileshm" ]; then
            echo -e "\e[00;31m[-] World-readable files within /home:\e[00m\n$wrfileshm"
            echo -e "\n"
        fi
    fi
    
    #lists current user's home directory contents
    if [ "$thorough" = "1" ]; then
        homedircontents=`ls -ahl ~ 2>/dev/null`
        if [ "$homedircontents" ] ; then
            echo -e "\e[00;31m[-] Home directory contents:\e[00m\n$homedircontents"
            echo -e "\n"
        fi
    fi
    
    #checks for if various ssh files are accessible - this can take some time so is only 'activated' with thorough scanning switch
    if [ "$thorough" = "1" ]; then
        sshfiles=`find / \( -name "id_dsa*" -o -name "id_rsa*" -o -name "known_hosts" -o -name "authorized_hosts" -o -name "authorized_keys" \) -exec ls -la {} 2>/dev/null \;`
        if [ "$sshfiles" ]; then
            echo -e "\e[00;31m[-] SSH keys/host information found in the following locations:\e[00m\n$sshfiles"
            echo -e "\n"
        fi
    fi
    
    
    #is root permitted to login via ssh
    sshrootlogin=`grep "PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | grep -v "#" | awk '{print  $2}'`
    if [ "$sshrootlogin" = "yes" ]; then
        echo -e "\e[00;31m[-] Root is allowed to login via SSH:\e[00m" ; grep "PermitRootLogin " /etc/ssh/sshd_config 2>/dev/null | grep -v "#"
        echo -e "\n"
    fi
}

environmental_info()
{
    echo -e "\e[00;33m### ENVIRONMENTAL #######################################\e[00m"
    
    #env information
    envinfo=`env 2>/dev/null | grep -v 'LS_COLORS' 2>/dev/null`
    if [ "$envinfo" ]; then
        echo -e "\e[00;31m[-] Environment information:\e[00m\n$envinfo"
        echo -e "\n"
    fi
    
    #check if selinux is enabled
    sestatus=`sestatus 2>/dev/null`
    if [ "$sestatus" ]; then
        echo -e "\e[00;31m[-] SELinux seems to be present:\e[00m\n$sestatus"
        echo -e "\n"
    fi
    
    #phackt
    
    #current path configuration
    pathinfo=`echo $PATH 2>/dev/null`
    if [ "$pathinfo" ]; then
        pathswriteable=`ls -ld $(echo $PATH | tr ":" " ")`
        echo -e "\e[00;31m[-] Path information:\e[00m\n$pathinfo"
        echo -e "$pathswriteable"
        echo -e "\n"
    fi
    
    #lists available shells
    shellinfo=`cat /etc/shells 2>/dev/null`
    if [ "$shellinfo" ]; then
        echo -e "\e[00;31m[-] Available shells:\e[00m\n$shellinfo"
        echo -e "\n"
    fi
    
    #current umask value with both octal and symbolic output
    umaskvalue=`umask -S 2>/dev/null & umask 2>/dev/null`
    if [ "$umaskvalue" ]; then
        echo -e "\e[00;31m[-] Current umask value:\e[00m\n$umaskvalue"
        echo -e "\n"
    fi
    
    #umask value as in /etc/login.defs
    umaskdef=`grep -i "^UMASK" /etc/login.defs 2>/dev/null`
    if [ "$umaskdef" ]; then
        echo -e "\e[00;31m[-] umask value as specified in /etc/login.defs:\e[00m\n$umaskdef"
        echo -e "\n"
    fi
    
    #password policy information as stored in /etc/login.defs
    logindefs=`grep "^PASS_MAX_DAYS\|^PASS_MIN_DAYS\|^PASS_WARN_AGE\|^ENCRYPT_METHOD" /etc/login.defs 2>/dev/null`
    if [ "$logindefs" ]; then
        echo -e "\e[00;31m[-] Password and storage information:\e[00m\n$logindefs"
        echo -e "\n"
    fi
    
}

job_info()
{
    echo -e "\e[00;33m### JOBS/TASKS ##########################################\e[00m"
    
    #are there any cron jobs configured
    cronjobs=`ls -la /etc/cron* 2>/dev/null`
    if [ "$cronjobs" ]; then
        echo -e "\e[00;31m[-] Cron jobs:\e[00m\n$cronjobs"
        echo -e "\n"
    fi
    
    #can we manipulate these jobs in any way
    cronjobwwperms=`find /etc/cron* -perm -0002 -type f -exec ls -la {} \; -exec cat {} 2>/dev/null \;`
    if [ "$cronjobwwperms" ]; then
        echo -e "\e[00;33m[+] World-writable cron jobs and file contents:\e[00m\n$cronjobwwperms"
        echo -e "\n"
    fi
    
    #contab contents
    crontabvalue=`cat /etc/crontab 2>/dev/null`
    if [ "$crontabvalue" ]; then
        echo -e "\e[00;31m[-] Crontab contents:\e[00m\n$crontabvalue"
        echo -e "\n"
    fi
    
    crontabvar=`ls -la /var/spool/cron/crontabs 2>/dev/null`
    if [ "$crontabvar" ]; then
        echo -e "\e[00;31m[-] Anything interesting in /var/spool/cron/crontabs:\e[00m\n$crontabvar"
        echo -e "\n"
    fi
    
    anacronjobs=`ls -la /etc/anacrontab 2>/dev/null; cat /etc/anacrontab 2>/dev/null`
    if [ "$anacronjobs" ]; then
        echo -e "\e[00;31m[-] Anacron jobs and associated file permissions:\e[00m\n$anacronjobs"
        echo -e "\n"
    fi
    
    anacrontab=`ls -la /var/spool/anacron 2>/dev/null`
    if [ "$anacrontab" ]; then
        echo -e "\e[00;31m[-] When were jobs last executed (/var/spool/anacron contents):\e[00m\n$anacrontab"
        echo -e "\n"
    fi
    
    #pull out account names from /etc/passwd and see if any users have associated cronjobs (priv command)
    cronother=`cut -d ":" -f 1 /etc/passwd | xargs -n1 crontab -l -u 2>/dev/null`
    if [ "$cronother" ]; then
        echo -e "\e[00;31m[-] Jobs held by all users:\e[00m\n$cronother"
        echo -e "\n"
    fi
    
    # list systemd timers
    if [ "$thorough" = "1" ]; then
        # include inactive timers in thorough mode
        systemdtimers="$(systemctl list-timers --all 2>/dev/null)"
        info=""
    else
        systemdtimers="$(systemctl list-timers 2>/dev/null |head -n -1 2>/dev/null)"
        # replace the info in the output with a hint towards thorough mode
        info="\e[2mEnable thorough tests to see inactive timers\e[00m"
    fi
    if [ "$systemdtimers" ]; then
        echo -e "\e[00;31m[-] Systemd timers:\e[00m\n$systemdtimers\n$info"
        echo -e "\n"
    fi
    
}

networking_info()
{
    echo -e "\e[00;33m### NETWORKING  ##########################################\e[00m"
    
    #nic information
    nicinfo=`/sbin/ifconfig -a 2>/dev/null`
    if [ "$nicinfo" ]; then
        echo -e "\e[00;31m[-] Network and IP info:\e[00m\n$nicinfo"
        echo -e "\n"
    fi
    
    #nic information (using ip)
    nicinfoip=`/sbin/ip a 2>/dev/null`
    if [ ! "$nicinfo" ] && [ "$nicinfoip" ]; then
        echo -e "\e[00;31m[-] Network and IP info:\e[00m\n$nicinfoip"
        echo -e "\n"
    fi
    
    arpinfo=`arp -a 2>/dev/null`
    if [ "$arpinfo" ]; then
        echo -e "\e[00;31m[-] ARP history:\e[00m\n$arpinfo"
        echo -e "\n"
    fi
    
    arpinfoip=`ip n 2>/dev/null`
    if [ ! "$arpinfo" ] && [ "$arpinfoip" ]; then
        echo -e "\e[00;31m[-] ARP history:\e[00m\n$arpinfoip"
        echo -e "\n"
    fi
    
    #dns settings
    nsinfo=`grep "nameserver" /etc/resolv.conf 2>/dev/null`
    if [ "$nsinfo" ]; then
        echo -e "\e[00;31m[-] Nameserver(s):\e[00m\n$nsinfo"
        echo -e "\n"
    fi
    
    nsinfosysd=`systemd-resolve --status 2>/dev/null`
    if [ "$nsinfosysd" ]; then
        echo -e "\e[00;31m[-] Nameserver(s):\e[00m\n$nsinfosysd"
        echo -e "\n"
    fi
    
    #default route configuration
    defroute=`route 2>/dev/null | grep default`
    if [ "$defroute" ]; then
        echo -e "\e[00;31m[-] Default route:\e[00m\n$defroute"
        echo -e "\n"
    fi
    
    #default route configuration
    defrouteip=`ip r 2>/dev/null | grep default`
    if [ ! "$defroute" ] && [ "$defrouteip" ]; then
        echo -e "\e[00;31m[-] Default route:\e[00m\n$defrouteip"
        echo -e "\n"
    fi
    
    #listening TCP
    tcpservs=`netstat -ntpl 2>/dev/null`
    if [ "$tcpservs" ]; then
        echo -e "\e[00;31m[-] Listening TCP:\e[00m\n$tcpservs"
        echo -e "\n"
    fi
    
    tcpservsip=`ss -t -l -n 2>/dev/null`
    if [ ! "$tcpservs" ] && [ "$tcpservsip" ]; then
        echo -e "\e[00;31m[-] Listening TCP:\e[00m\n$tcpservsip"
        echo -e "\n"
    fi
    
    #listening UDP
    udpservs=`netstat -nupl 2>/dev/null`
    if [ "$udpservs" ]; then
        echo -e "\e[00;31m[-] Listening UDP:\e[00m\n$udpservs"
        echo -e "\n"
    fi
    
    udpservsip=`ss -u -l -n 2>/dev/null`
    if [ ! "$udpservs" ] && [ "$udpservsip" ]; then
        echo -e "\e[00;31m[-] Listening UDP:\e[00m\n$udpservsip"
        echo -e "\n"
    fi
    
    rpc=`cat /etc/rpc`
    if [ ! "$rpc" ] && [ "$rpc" ]; then
        echo -e "\e[00;31m[-] Remote Procedure Call:\e[00m\n$rpc"
        echo -e "\n"
    fi
    
}

services_info()
{
    echo -e "\e[00;33m### SERVICES #############################################\e[00m"
    
    #running processes
    psaux=`ps aux 2>/dev/null`
    if [ "$psaux" ]; then
        echo -e "\e[00;31m[-] Running processes:\e[00m\n$psaux"
        echo -e "\n"
    fi
    
    #lookup process binary path and permissisons
    procperm=`ps aux 2>/dev/null | awk '{print $11}'|xargs -r ls -la 2>/dev/null |awk '!x[$0]++' 2>/dev/null`
    if [ "$procperm" ]; then
        echo -e "\e[00;31m[-] Process binaries and associated permissions (from above list):\e[00m\n$procperm"
        echo -e "\n"
    fi
    
    #anything 'useful' in inetd.conf
    inetdread=`cat /etc/inetd.conf 2>/dev/null`
    if [ "$inetdread" ]; then
        echo -e "\e[00;31m[-] Contents of /etc/inetd.conf:\e[00m\n$inetdread"
        echo -e "\n"
    fi
    
    #very 'rough' command to extract associated binaries from inetd.conf & show permisisons of each
    inetdbinperms=`awk '{print $7}' /etc/inetd.conf 2>/dev/null |xargs -r ls -la 2>/dev/null`
    if [ "$inetdbinperms" ]; then
        echo -e "\e[00;31m[-] The related inetd binary permissions:\e[00m\n$inetdbinperms"
        echo -e "\n"
    fi
    
    xinetdread=`cat /etc/xinetd.conf 2>/dev/null`
    if [ "$xinetdread" ]; then
        echo -e "\e[00;31m[-] Contents of /etc/xinetd.conf:\e[00m\n$xinetdread"
        echo -e "\n"
    fi
    
    xinetdincd=`grep "/etc/xinetd.d" /etc/xinetd.conf 2>/dev/null`
    if [ "$xinetdincd" ]; then
        echo -e "\e[00;31m[-] /etc/xinetd.d is included in /etc/xinetd.conf - associated binary permissions are listed below:\e[00m"; ls -la /etc/xinetd.d 2>/dev/null
        echo -e "\n"
    fi
    
    #very 'rough' command to extract associated binaries from xinetd.conf & show permisisons of each
    xinetdbinperms=`awk '{print $7}' /etc/xinetd.conf 2>/dev/null |xargs -r ls -la 2>/dev/null`
    if [ "$xinetdbinperms" ]; then
        echo -e "\e[00;31m[-] The related xinetd binary permissions:\e[00m\n$xinetdbinperms"
        echo -e "\n"
    fi
    
    initdread=`ls -la /etc/init.d 2>/dev/null`
    if [ "$initdread" ]; then
        echo -e "\e[00;31m[-] /etc/init.d/ binary permissions:\e[00m\n$initdread"
        echo -e "\n"
    fi
    
    #init.d files NOT belonging to root!
    initdperms=`find /etc/init.d/ \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
    if [ "$initdperms" ]; then
        echo -e "\e[00;31m[-] /etc/init.d/ files not belonging to root:\e[00m\n$initdperms"
        echo -e "\n"
    fi
    
    rcdread=`ls -la /etc/rc.d/init.d 2>/dev/null`
    if [ "$rcdread" ]; then
        echo -e "\e[00;31m[-] /etc/rc.d/init.d binary permissions:\e[00m\n$rcdread"
        echo -e "\n"
    fi
    
    #init.d files NOT belonging to root!
    rcdperms=`find /etc/rc.d/init.d \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
    if [ "$rcdperms" ]; then
        echo -e "\e[00;31m[-] /etc/rc.d/init.d files not belonging to root:\e[00m\n$rcdperms"
        echo -e "\n"
    fi
    
    usrrcdread=`ls -la /usr/local/etc/rc.d 2>/dev/null`
    if [ "$usrrcdread" ]; then
        echo -e "\e[00;31m[-] /usr/local/etc/rc.d binary permissions:\e[00m\n$usrrcdread"
        echo -e "\n"
    fi
    
    #rc.d files NOT belonging to root!
    usrrcdperms=`find /usr/local/etc/rc.d \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
    if [ "$usrrcdperms" ]; then
        echo -e "\e[00;31m[-] /usr/local/etc/rc.d files not belonging to root:\e[00m\n$usrrcdperms"
        echo -e "\n"
    fi
    
    initread=`ls -la /etc/init/ 2>/dev/null`
    if [ "$initread" ]; then
        echo -e "\e[00;31m[-] /etc/init/ config file permissions:\e[00m\n$initread"
        echo -e "\n"
    fi
    
    # upstart scripts not belonging to root
    initperms=`find /etc/init \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
    if [ "$initperms" ]; then
        echo -e "\e[00;31m[-] /etc/init/ config files not belonging to root:\e[00m\n$initperms"
        echo -e "\n"
    fi
    
    systemdread=`ls -lthR /lib/systemd/ 2>/dev/null`
    if [ "$systemdread" ]; then
        echo -e "\e[00;31m[-] /lib/systemd/* config file permissions:\e[00m\n$systemdread"
        echo -e "\n"
    fi
    
    # systemd files not belonging to root
    systemdperms=`find /lib/systemd/ \! -uid 0 -type f 2>/dev/null |xargs -r ls -la 2>/dev/null`
    if [ "$systemdperms" ]; then
        echo -e "\e[00;33m[+] /lib/systemd/* config files not belonging to root:\e[00m\n$systemdperms"
        echo -e "\n"
    fi
}

software_configs()
{
    echo -e "\e[00;33m### SOFTWARE #############################################\e[00m"
    
    #sudo version - check to see if there are any known vulnerabilities with this
    sudover=`sudo -V 2>/dev/null| grep "Sudo version" 2>/dev/null`
    if [ "$sudover" ]; then
        echo -e "\e[00;31m[-] Sudo version:\e[00m\n$sudover"
        echo -e "\n"
    fi
    
    #mysql details - if installed
    mysqlver=`mysql --version 2>/dev/null`
    if [ "$mysqlver" ]; then
        echo -e "\e[00;31m[-] MYSQL version:\e[00m\n$mysqlver"
        echo -e "\n"
    fi
    
    #checks to see if root/root will get us a connection
    mysqlconnect=`mysqladmin -uroot -proot version 2>/dev/null`
    if [ "$mysqlconnect" ]; then
        echo -e "\e[00;33m[+] We can connect to the local MYSQL service with default root/root credentials!\e[00m\n$mysqlconnect"
        echo -e "\n"
    fi
    
    #mysql version details
    mysqlconnectnopass=`mysqladmin -uroot version 2>/dev/null`
    if [ "$mysqlconnectnopass" ]; then
        echo -e "\e[00;33m[+] We can connect to the local MYSQL service as 'root' and without a password!\e[00m\n$mysqlconnectnopass"
        echo -e "\n"
    fi
    
    #postgres details - if installed
    postgver=`psql -V 2>/dev/null`
    if [ "$postgver" ]; then
        echo -e "\e[00;31m[-] Postgres version:\e[00m\n$postgver"
        echo -e "\n"
    fi
    
    #checks to see if any postgres password exists and connects to DB 'template0' - following commands are a variant on this
    postcon1=`psql -U postgres -w template0 -c 'select version()' 2>/dev/null | grep version`
    if [ "$postcon1" ]; then
        echo -e "\e[00;33m[+] We can connect to Postgres DB 'template0' as user 'postgres' with no password!:\e[00m\n$postcon1"
        echo -e "\n"
    fi
    
    postcon11=`psql -U postgres -w template1 -c 'select version()' 2>/dev/null | grep version`
    if [ "$postcon11" ]; then
        echo -e "\e[00;33m[+] We can connect to Postgres DB 'template1' as user 'postgres' with no password!:\e[00m\n$postcon11"
        echo -e "\n"
    fi
    
    postcon2=`psql -U pgsql -w template0 -c 'select version()' 2>/dev/null | grep version`
    if [ "$postcon2" ]; then
        echo -e "\e[00;33m[+] We can connect to Postgres DB 'template0' as user 'psql' with no password!:\e[00m\n$postcon2"
        echo -e "\n"
    fi
    
    postcon22=`psql -U pgsql -w template1 -c 'select version()' 2>/dev/null | grep version`
    if [ "$postcon22" ]; then
        echo -e "\e[00;33m[+] We can connect to Postgres DB 'template1' as user 'psql' with no password!:\e[00m\n$postcon22"
        echo -e "\n"
    fi
    
    #apache details - if installed
    apachever=`apache2 -v 2>/dev/null; httpd -v 2>/dev/null`
    if [ "$apachever" ]; then
        echo -e "\e[00;31m[-] Apache version:\e[00m\n$apachever"
        echo -e "\n"
    fi
    
    #what account is apache running under
    apacheusr=`grep -i 'user\|group' /etc/apache2/envvars 2>/dev/null |awk '{sub(/.*\export /,"")}1' 2>/dev/null`
    if [ "$apacheusr" ]; then
        echo -e "\e[00;31m[-] Apache user configuration:\e[00m\n$apacheusr"
        echo -e "\n"
    fi
    
    #installed apache modules
    apachemodules=`apache2ctl -M 2>/dev/null; httpd -M 2>/dev/null`
    if [ "$apachemodules" ]; then
        echo -e "\e[00;31m[-] Installed Apache modules:\e[00m\n$apachemodules"
        echo -e "\n"
    fi
    
    #htpasswd check
    htpasswd=`find / -name .htpasswd -print -exec cat {} \; 2>/dev/null`
    if [ "$htpasswd" ]; then
        echo -e "\e[00;33m[-] htpasswd found - could contain passwords:\e[00m\n$htpasswd"
        echo -e "\n"
    fi
    
    #anything in the default http home dirs (a thorough only check as output can be large)
    if [ "$thorough" = "1" ]; then
        apachehomedirs=`ls -alhR /var/www/ 2>/dev/null; ls -alhR /srv/www/htdocs/ 2>/dev/null; ls -alhR /usr/local/www/apache2/data/ 2>/dev/null; ls -alhR /opt/lampp/htdocs/ 2>/dev/null`
        if [ "$apachehomedirs" ]; then
            echo -e "\e[00;31m[-] www home dir contents:\e[00m\n$apachehomedirs"
            echo -e "\n"
        fi
    fi
    
}

interesting_files()
{
    echo -e "\e[00;33m### INTERESTING FILES ####################################\e[00m"
    
    #checks to see if various files are installed
    echo -e "\e[00;31m[-] Useful file locations:\e[00m" ; which nc 2>/dev/null ; which netcat 2>/dev/null ; which wget 2>/dev/null ; which nmap 2>/dev/null ; which gcc 2>/dev/null; which curl 2>/dev/null
    echo -e "\n"
    
    #limited search for installed compilers
    compiler=`dpkg --list 2>/dev/null| grep compiler |grep -v decompiler 2>/dev/null && yum list installed 'gcc*' 2>/dev/null| grep gcc 2>/dev/null`
    if [ "$compiler" ]; then
        echo -e "\e[00;31m[-] Installed compilers:\e[00m\n$compiler"
        echo -e "\n"
    fi
    
    #manual check - lists out sensitive files, can we read/modify etc.
    echo -e "\e[00;31m[-] Can we read/write sensitive files:\e[00m" ; ls -la /etc/passwd 2>/dev/null ; ls -la /etc/group 2>/dev/null ; ls -la /etc/profile 2>/dev/null; ls -la /etc/shadow 2>/dev/null ; ls -la /etc/master.passwd 2>/dev/null
    echo -e "\n"
    
    #search for suid files
    findsuid=`find / -perm -4000 -type f -exec ls -la {} 2>/dev/null \;`
    if [ "$findsuid" ]; then
        echo -e "\e[00;31m[-] SUID files:\e[00m\n$findsuid"
        echo -e "\n"
    fi
    
    
    #list of 'interesting' suid files - feel free to make additions
    intsuid=`find / -perm -4000 -type f -exec ls -la {} \; 2>/dev/null | grep -w $binarylist 2>/dev/null`
    if [ "$intsuid" ]; then
        echo -e "\e[00;33m[+] Possibly interesting SUID files:\e[00m\n$intsuid"
        echo -e "\n"
    fi
    
    #lists word-writable suid files
    wwsuid=`find / -perm -4002 -type f -exec ls -la {} 2>/dev/null \;`
    if [ "$wwsuid" ]; then
        echo -e "\e[00;33m[+] World-writable SUID files:\e[00m\n$wwsuid"
        echo -e "\n"
    fi
    
    #lists world-writable suid files owned by root
    wwsuidrt=`find / -uid 0 -perm -4002 -type f -exec ls -la {} 2>/dev/null \;`
    if [ "$wwsuidrt" ]; then
        echo -e "\e[00;33m[+] World-writable SUID files owned by root:\e[00m\n$wwsuidrt"
        echo -e "\n"
    fi
    
    #search for sgid files
    findsgid=`find / -perm -2000 -type f -exec ls -la {} 2>/dev/null \;`
    if [ "$findsgid" ]; then
        echo -e "\e[00;31m[-] SGID files:\e[00m\n$findsgid"
        echo -e "\n"
    fi
    
    
    #list of 'interesting' sgid files
    intsgid=`find / -perm -2000 -type f  -exec ls -la {} \; 2>/dev/null | grep -w $binarylist 2>/dev/null`
    if [ "$intsgid" ]; then
        echo -e "\e[00;33m[+] Possibly interesting SGID files:\e[00m\n$intsgid"
        echo -e "\n"
    fi
    
    #lists world-writable sgid files
    wwsgid=`find / -perm -2002 -type f -exec ls -la {} 2>/dev/null \;`
    if [ "$wwsgid" ]; then
        echo -e "\e[00;33m[+] World-writable SGID files:\e[00m\n$wwsgid"
        echo -e "\n"
    fi
    
    #lists world-writable sgid files owned by root
    wwsgidrt=`find / -uid 0 -perm -2002 -type f -exec ls -la {} 2>/dev/null \;`
    if [ "$wwsgidrt" ]; then
        echo -e "\e[00;33m[+] World-writable SGID files owned by root:\e[00m\n$wwsgidrt"
        echo -e "\n"
    fi
    
    #list all files with POSIX capabilities set along with there capabilities
    fileswithcaps=`getcap -r / 2>/dev/null || /sbin/getcap -r / 2>/dev/null`
    if [ "$fileswithcaps" ]; then
        echo -e "\e[00;31m[+] Files with POSIX capabilities set:\e[00m\n$fileswithcaps"
        echo -e "\n"
    fi
    
    #searches /etc/security/capability.conf for users associated capapilies
    userswithcaps=`grep -v '^#\|none\|^$' /etc/security/capability.conf 2>/dev/null`
    if [ "$userswithcaps" ]; then
        echo -e "\e[00;33m[+] Users with specific POSIX capabilities:\e[00m\n$userswithcaps"
        echo -e "\n"
    fi
    
    if [ "$userswithcaps" ] ; then
        #matches the capabilities found associated with users with the current user
        matchedcaps=`echo -e "$userswithcaps" | grep \`whoami\` | awk '{print $1}' 2>/dev/null`
        if [ "$matchedcaps" ]; then
            echo -e "\e[00;33m[+] Capabilities associated with the current user:\e[00m\n$matchedcaps"
            echo -e "\n"
            #matches the files with capapbilities with capabilities associated with the current user
            matchedfiles=`echo -e "$matchedcaps" | while read -r cap ; do echo -e "$fileswithcaps" | grep "$cap" ; done 2>/dev/null`
            if [ "$matchedfiles" ]; then
                echo -e "\e[00;33m[+] Files with the same capabilities associated with the current user (You may want to try abusing those capabilties):\e[00m\n$matchedfiles"
                echo -e "\n"
                #lists the permissions of the files having the same capabilies associated with the current user
                matchedfilesperms=`echo -e "$matchedfiles" | awk '{print $1}' | while read -r f; do ls -la $f ;done 2>/dev/null`
                echo -e "\e[00;33m[+] Permissions of files with the same capabilities associated with the current user:\e[00m\n$matchedfilesperms"
                echo -e "\n"
                if [ "$matchedfilesperms" ]; then
                    #checks if any of the files with same capabilities associated with the current user is writable
                    writablematchedfiles=`echo -e "$matchedfiles" | awk '{print $1}' | while read -r f; do find $f -writable -exec ls -la {} + ;done 2>/dev/null`
                    if [ "$writablematchedfiles" ]; then
                        echo -e "\e[00;33m[+] User/Group writable files with the same capabilities associated with the current user:\e[00m\n$writablematchedfiles"
                        echo -e "\n"
                    fi
                fi
            fi
        fi
    fi
    
    #look for private keys - thanks djhohnstein
    if [ "$thorough" = "1" ]; then
        privatekeyfiles=`grep -rl "PRIVATE KEY-----" /home 2>/dev/null`
        if [ "$privatekeyfiles" ]; then
            echo -e "\e[00;33m[+] Private SSH keys found!:\e[00m\n$privatekeyfiles"
            echo -e "\n"
        fi
    fi
    
    #look for AWS keys - thanks djhohnstein
    if [ "$thorough" = "1" ]; then
        awskeyfiles=`grep -rli "aws_secret_access_key" /home 2>/dev/null`
        if [ "$awskeyfiles" ]; then
            echo -e "\e[00;33m[+] AWS secret keys found!:\e[00m\n$awskeyfiles"
            echo -e "\n"
        fi
    fi
    
    #look for git credential files - thanks djhohnstein
    if [ "$thorough" = "1" ]; then
        gitcredfiles=`find / -name ".git-credentials" 2>/dev/null`
        if [ "$gitcredfiles" ]; then
            echo -e "\e[00;33m[+] Git credentials saved on the machine!:\e[00m\n$gitcredfiles"
            echo -e "\n"
        fi
    fi
    
    #list all world-writable files excluding /proc and /sys
    if [ "$thorough" = "1" ]; then
        wwfiles=`find / ! -path "*/proc/*" ! -path "/sys/*" -perm -2 -type f -exec ls -la {} 2>/dev/null \;`
        if [ "$wwfiles" ]; then
            echo -e "\e[00;31m[-] World-writable files (excluding /proc and /sys):\e[00m\n$wwfiles"
            echo -e "\n"
        fi
    fi
    
    #are any .plan files accessible in /home (could contain useful information)
    usrplan=`find /home -iname *.plan -exec ls -la {} \; -exec cat {} 2>/dev/null \;`
    if [ "$usrplan" ]; then
        echo -e "\e[00;31m[-] Plan file permissions and contents:\e[00m\n$usrplan"
        echo -e "\n"
    fi
    
    bsdusrplan=`find /usr/home -iname *.plan -exec ls -la {} \; -exec cat {} 2>/dev/null \;`
    if [ "$bsdusrplan" ]; then
        echo -e "\e[00;31m[-] Plan file permissions and contents:\e[00m\n$bsdusrplan"
        echo -e "\n"
    fi
    
    #are there any .rhosts files accessible - these may allow us to login as another user etc.
    rhostsusr=`find /home -iname *.rhosts -exec ls -la {} 2>/dev/null \; -exec cat {} 2>/dev/null \;`
    if [ "$rhostsusr" ]; then
        echo -e "\e[00;33m[+] rhost config file(s) and file contents:\e[00m\n$rhostsusr"
        echo -e "\n"
    fi
    
    
    bsdrhostsusr=`find /usr/home -iname *.rhosts -exec ls -la {} 2>/dev/null \; -exec cat {} 2>/dev/null \;`
    if [ "$bsdrhostsusr" ]; then
        echo -e "\e[00;33m[+] rhost config file(s) and file contents:\e[00m\n$bsdrhostsusr"
        echo -e "\n"
    fi
    
    rhostssys=`find /etc -iname hosts.equiv -exec ls -la {} 2>/dev/null \; -exec cat {} 2>/dev/null \;`
    if [ "$rhostssys" ]; then
        echo -e "\e[00;33m[+] Hosts.equiv file and contents: \e[00m\n$rhostssys"
        echo -e "\n"
    fi
    
    #list nfs shares/permisisons etc.
    nfsexports=`ls -la /etc/exports 2>/dev/null; cat /etc/exports 2>/dev/null`
    if [ "$nfsexports" ]; then
        echo -e "\e[00;31m[-] NFS config details: \e[00m\n$nfsexports"
        echo -e "\n"
    fi
    
    if [ "$thorough" = "1" ]; then
        #phackt
        #displaying /etc/fstab
        fstab=`cat /etc/fstab 2>/dev/null`
        if [ "$fstab" ]; then
            echo -e "\e[00;31m[-] NFS displaying partitions and filesystems - you need to check if exotic filesystems\e[00m"
            echo -e "$fstab"
            echo -e "\n"
        fi
    fi
    
    #looking for credentials in /etc/fstab
    fstab=`grep username /etc/fstab 2>/dev/null |awk '{sub(/.*\username=/,"");sub(/\,.*/,"")}1' 2>/dev/null| xargs -r echo username: 2>/dev/null; grep password /etc/fstab 2>/dev/null |awk '{sub(/.*\password=/,"");sub(/\,.*/,"")}1' 2>/dev/null| xargs -r echo password: 2>/dev/null; grep domain /etc/fstab 2>/dev/null |awk '{sub(/.*\domain=/,"");sub(/\,.*/,"")}1' 2>/dev/null| xargs -r echo domain: 2>/dev/null`
    if [ "$fstab" ]; then
        echo -e "\e[00;33m[+] Looks like there are credentials in /etc/fstab!\e[00m\n$fstab"
        echo -e "\n"
    fi
    
    fstabcred=`grep cred /etc/fstab 2>/dev/null |awk '{sub(/.*\credentials=/,"");sub(/\,.*/,"")}1' 2>/dev/null | xargs -I{} sh -c 'ls -la {}; cat {}' 2>/dev/null`
    if [ "$fstabcred" ]; then
        echo -e "\e[00;33m[+] /etc/fstab contains a credentials file!\e[00m\n$fstabcred"
        echo -e "\n"
    fi
    
    #use supplied keyword and cat *.conf files for potential matches - output will show line number within relevant file path where a match has been located
    if [ "$keyword" = "" ]; then
        echo -e "[-] Can't search *.conf files as no keyword was entered\n"
    else
        confkey=`find / -maxdepth 4 -name *.conf -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
        if [ "$confkey" ]; then
            echo -e "\e[00;31m[-] Find keyword ($keyword) in .conf files (recursive 4 levels - output format filepath:identified line number where keyword appears):\e[00m\n$confkey"
            echo -e "\n"
        else
            echo -e "\e[00;31m[-] Find keyword ($keyword) in .conf files (recursive 4 levels):\e[00m"
            echo -e "'$keyword' not found in any .conf files"
            echo -e "\n"
        fi
    fi
    
    #use supplied keyword and cat *.php files for potential matches - output will show line number within relevant file path where a match has been located
    if [ "$keyword" = "" ]; then
        echo -e "[-] Can't search *.php files as no keyword was entered\n"
    else
        phpkey=`find / -maxdepth 10 -name *.php -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
        if [ "$phpkey" ]; then
            echo -e "\e[00;31m[-] Find keyword ($keyword) in .php files (recursive 10 levels - output format filepath:identified line number where keyword appears):\e[00m\n$phpkey"
            echo -e "\n"
        else
            echo -e "\e[00;31m[-] Find keyword ($keyword) in .php files (recursive 10 levels):\e[00m"
            echo -e "'$keyword' not found in any .php files"
            echo -e "\n"
        fi
    fi
    
    #use supplied keyword and cat *.log files for potential matches - output will show line number within relevant file path where a match has been located
    if [ "$keyword" = "" ];then
        echo -e "[-] Can't search *.log files as no keyword was entered\n"
    else
        logkey=`find / -maxdepth 4 -name *.log -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
        if [ "$logkey" ]; then
            echo -e "\e[00;31m[-] Find keyword ($keyword) in .log files (recursive 4 levels - output format filepath:identified line number where keyword appears):\e[00m\n$logkey"
            echo -e "\n"
        else
            echo -e "\e[00;31m[-] Find keyword ($keyword) in .log files (recursive 4 levels):\e[00m"
            echo -e "'$keyword' not found in any .log files"
            echo -e "\n"
        fi
    fi
    
    #use supplied keyword and cat *.ini files for potential matches - output will show line number within relevant file path where a match has been located
    if [ "$keyword" = "" ];then
        echo -e "[-] Can't search *.ini files as no keyword was entered\n"
    else
        inikey=`find / -maxdepth 4 -name *.ini -type f -exec grep -Hn $keyword {} \; 2>/dev/null`
        if [ "$inikey" ]; then
            echo -e "\e[00;31m[-] Find keyword ($keyword) in .ini files (recursive 4 levels - output format filepath:identified line number where keyword appears):\e[00m\n$inikey"
            echo -e "\n"
        else
            echo -e "\e[00;31m[-] Find keyword ($keyword) in .ini files (recursive 4 levels):\e[00m"
            echo -e "'$keyword' not found in any .ini files"
            echo -e "\n"
        fi
    fi
    
    #quick extract of .conf files from /etc - only 1 level
    allconf=`find /etc/ -maxdepth 1 -name *.conf -type f -exec ls -la {} \; 2>/dev/null`
    if [ "$allconf" ]; then
        echo -e "\e[00;31m[-] All *.conf files in /etc (recursive 1 level):\e[00m\n$allconf"
        echo -e "\n"
    fi
    
    
    #extract any user history files that are accessible
    usrhist=`ls -la ~/.*_history 2>/dev/null`
    if [ "$usrhist" ]; then
        echo -e "\e[00;31m[-] Current user's history files:\e[00m\n$usrhist"
        echo -e "\n"
    fi
    
    
    #can we read roots *_history files - could be passwords stored etc.
    roothist=`ls -la /root/.*_history 2>/dev/null`
    if [ "$roothist" ]; then
        echo -e "\e[00;33m[+] Root's history files are accessible!\e[00m\n$roothist"
        echo -e "\n"
    fi
    
    #all accessible .bash_history files in /home
    checkbashhist=`find /home -name .bash_history -print -exec cat {} 2>/dev/null \;`
    if [ "$checkbashhist" ]; then
        echo -e "\e[00;31m[-] Location and contents (if accessible) of .bash_history file(s):\e[00m\n$checkbashhist"
        echo -e "\n"
    fi
    
    #any .bak files that may be of interest
    bakfiles=`find / -name *.bak -type f 2</dev/null`
    if [ "$bakfiles" ]; then
        echo -e "\e[00;31m[-] Location and Permissions (if accessible) of .bak file(s):\e[00m"
        for bak in `echo $bakfiles`; do ls -la $bak;done
        echo -e "\n"
    fi
    
    #is there any mail accessible
    readmail=`ls -la /var/mail 2>/dev/null`
    if [ "$readmail" ]; then
        echo -e "\e[00;31m[-] Any interesting mail in /var/mail:\e[00m\n$readmail"
        echo -e "\n"
    fi
    
    #can we read roots mail
    readmailroot=`head /var/mail/root 2>/dev/null`
    if [ "$readmailroot" ]; then
        echo -e "\e[00;33m[+] We can read /var/mail/root! (snippet below)\e[00m\n$readmailroot"
        echo -e "\n"
    fi
    
    #newest file
    [ "$dotfiles" = "no" ] && ignore_hidden="-name '.*' -o"
    [ "$recurse"  = "no" ] && dont_recurse="-maxdepth 1"
    if [ $# -gt 0 ]; then
        path_format="%p"
    else
        path_format="%P"
        set -- "./"
    fi
    
    
    echo -e "\e[00;31m[-] Newest file\e[00m"
    ignore_metadata="\( -type d -a \( -name '.git' -o -name '.svn' -o -name 'CVS' \) \) -prune -o"
    print_format="\( -type f -printf '%T@\t$path_format\n' \)"
    eval find '"$@"' $dont_recurse $ignore_metadata $ignore_hidden $print_format |
    sort -k1,1${reverse}n |
    tail $num |
    cut -f2- |
    if [ ! -p /proc/self/fd/1 ]; then
        tr '\n' '\0' |
        xargs -r0 ls -lUd --color=auto --
    else
        cat
    fi
    
}

docker_checks()
{
    
    #check to see if we're in a docker container
    dockercontainer=` grep -i docker /proc/self/cgroup  2>/dev/null; find / -name "*dockerenv*" -exec ls -la {} \; 2>/dev/null`
    if [ "$dockercontainer" ]; then
        echo -e "\e[00;33m[+] Looks like we're in a Docker container:\e[00m\n$dockercontainer"
        echo -e "\n"
    fi
    
    #check to see if we're a docker host
    dockerhost=`sudo docker --version 2>/dev/null; sudo docker ps -a 2>/dev/null`
    if [ "$dockerhost" ]; then
        echo -e "\e[00;33m[+] Looks like we're hosting Docker:\e[00m\n$dockerhost"
        echo -e "\n"
    fi
    
    #are we a member of the docker group
    dockergrp=`id | grep -i docker 2>/dev/null`
    if [ "$dockergrp" ]; then
        echo -e "\e[00;33m[+] We're a member of the (docker) group - could possibly misuse these rights!\e[00m\n$dockergrp"
        echo -e "\n"
    fi
    
    #are there any docker files present
    dockerfiles=`find / -name Dockerfile -exec ls -l {} 2>/dev/null \;`
    if [ "$dockerfiles" ]; then
        echo -e "\e[00;31m[-] Anything juicy in the Dockerfile:\e[00m\n$dockerfiles"
        echo -e "\n"
    fi
    
    #are there any docker files present
    dockeryml=`find / -name docker-compose.yml -exec ls -l {} 2>/dev/null \;`
    if [ "$dockeryml" ]; then
        echo -e "\e[00;31m[-] Anything juicy in docker-compose.yml:\e[00m\n$dockeryml"
        echo -e "\n"
    fi
    
    docker=` grep -i docker /proc/self/cgroup  2>/dev/null; sudo find / -name "docker*" -exec ls -la {} \; 2>/dev/null`
    if [ "$docker" ]; then
        echo -e "\e[00;33m[+] Looks like we're in a Docker :\e[00m\n$docker"
        echo -e "\n"
    fi
    dockerprocess=$(systemctl list-unit-files | grep docker 2>/dev/null)
    if [ "$dockerprocess" ]; then
        echo -e "\e[00;33m[+] Looks like Docker process :\e[00m\n$dockerprocess"
        echo -e "\n"
    fi
    dockerprocess1=$(ps -aux | grep docker 2>/dev/null)
    if [ "$dockerprocess1" ]; then
        echo -e "\e[00;33m[+] Looks like Docker process :\e[00m\n$dockerprocess1"
        echo -e "\n"
    fi
}

lxc_container_checks()
{
    
    
    #specific checks - are we in an lxd/lxc container
    lxccontainer=`grep -qa container=lxc /proc/1/environ 2>/dev/null`
    if [ "$lxccontainer" ]; then
        echo -e "\e[00;33m[+] Looks like we're in a lxc container:\e[00m\n$lxccontainer"
        echo -e "\n"
    fi
    
    #specific checks - are we a member of the lxd group
    lxdgroup=`id | grep -i lxd 2>/dev/null`
    if [ "$lxdgroup" ]; then
        echo -e "\e[00;33m[+] We're a member of the (lxd) group - could possibly misuse these rights!\e[00m\n$lxdgroup"
        echo -e "\n"
    fi
}

package_list()
{
    echo -e "\e[00;33m### PACKAGE #############################################\e[00m"
    
    yumrepos=`ls -1 /etc/yum.repos.d ; 2>/dev/null`
    if [ "$yumrepos" ]; then
        echo -e "\e[00;33m[+] List all Yum repos(YUM):\e[00m\n$yumrepos"
        echo -e "\n"
    fi
    
    yumavalable=`yum list avalable ; 2>/dev/null`
    if [ "$yumavalable" ]; then
        echo -e "\e[00;33m[+] List all active package repos(YUM):\e[00m\n$yumavalable"
        echo -e "\n"
    fi
    
    yuminstal=`yum list avalable ; 2>/dev/null`
    if [ "$yuminstal" ]; then
        echo -e "\e[00;33m[+] List of installed packages with repository (YUM):\e[00m\n$yuminstal"
        echo -e "\n"
    fi
    
    
    rpmlist=`rpm -qa ; 2>/dev/null`
    if [ "$rpmlist" ]; then
        echo -e "\e[00;33m[+] List all installed packages (RPM):\e[00m\n$rpmlist"
        echo -e "\n"
    fi
    
    rpmlist=`rpm -qa ; 2>/dev/null`
    if [ "$rpmlist" ]; then
        echo -e "\e[00;33m[+] List all installed packages (RPM):\e[00m\n$rpmlist"
        echo -e "\n"
    fi
    
    aptlist=`apt list --installed ; 2>/dev/null`
    if [ "$aptlist" ]; then
        echo -e "\e[00;33m[+] List APT installed packages (Ubuntu/Debian):\e[00m\n$aptlist"
        echo -e "\n"
    fi
    
    aptmanual=`apt-mark showmanual ; 2>/dev/null`
    if [ "$aptmanual" ]; then
        echo -e "\e[00;33m[+] List APT installed manual packages (Ubuntu/Debian):\e[00m\n$aptmanual"
        echo -e "\n"
    fi
    
}


function call_each2()
{
    old_opts=$(set +o)
    set +u
    
    system_info
    user_info
    environmental_info
    job_info
    networking_info
    services_info
    software_configs
    interesting_files
    docker_checks
    lxc_container_checks
    package_list
    eval "$old_opts"
}


generate_md5sum_baseline()
{
    old_opts=$(set +o)
    set +u
    
    echo -e "\e[00;33m### GENERATING MD5SUM BASELINE #############################\e[00m"
    
    CURRENT_DIR="$(pwd)"
    
    sudo find /boot /dev /etc /home /u01 /opt /srv /tmp /usr /var \
    -type f \
    ! -path "$SCRIPT_DIR/*" \
    ! -path "$SCRIPT_DIR" 2>/dev/null | \
    sudo xargs -d '\n' -P "$(nproc)" -I {} md5sum {} 2>/dev/null | \
    sort -k2
    eval "$old_opts"
}
