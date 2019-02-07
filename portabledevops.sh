#!/usr/bin/bash 
# portabledevops.sh
# customized setting for msys2/cygwin64/mobaxterm/wsl
# By Robert Wang
# Feb 7th, 2019

# debug
#set -x 
#set -o functrace

#
# Section - env setup
#

export DEFPORTFOLDER=portabledevops
export DEFHOMEDRIVEL=c
export DEFVAGRANTWSLHOME=/mnt/c/vagrant

export PORTSYS=`uname|cut -d'_' -f1`

if [ $PORTSYS = 'MSYS' ] || [ $PORTSYS = 'MINGW32' ] || [ $PORTSYS = 'MINGW64' ]; then
    if [ ! -d /home/$USERNAME ]; then
        mkdir -p /home/$USERNAME
    fi
    HOME=/home/$USERNAME
    export USERPROFILE=$HOME
    export HOMEPATH=$HOME
elif [ $PORTSYS = 'Linux' ] && [ `uname -a|awk '{print $4}'|cut -d'-' -f2` = Microsoft ];then
    export USERNAME=$USER
    export USERPROFILE=$HOME
    export HOMEPATH=$HOME
fi

cd $HOME

# portable mobaxterm, change persistent folder for root to <mobaxterm>/root , copy this portabledevops.sh to <mobaxterm>/root/etc/profile.d/ 

if [  `env|grep MOBANOACL` ]; then
    export PORTFOLDER=`echo $SYMLINKS|rev|cut -d'/' -f5-|rev|cut -d: -f2-`
    export HOMEDRIVEL=`echo $SYMLINKS|cut -d: -f1`
elif [ `env|grep BABUN_HOME` ];then
    export PORTFOLDER=`echo $BABUN_HOME|rev|cut -d/ -f2-|rev|cut -d: -f2-`
    export HOMEDRIVEL=`echo $BABUN_HOME|cut -d: -f1`
elif [ $PORTSYS = 'Linux' ] && [ `uname -a|awk '{print $4}'|cut -d'-' -f2` = Microsoft ];then
    export PORTFOLDER=$DEFPORTFOLDER
    export HOMEDRIVEL=$DEFHOMEDRIVEL
else
    export PORTFOLDER=`cygpath -ml \`pwd\`|rev|cut -d'/' -f4-|rev|cut -d: -f2-`
    export HOMEDRIVEL=`cygpath -m \`pwd\` |cut -d: -f1`
fi 

export HOMEDRIVE=$HOMEDRIVEL:

function startwslssh(){
    echo check wsl sshd status
    service ssh status
    if [ "$?" != "0" ]; then
        sudo service ssh start
    fi
}

if [ $PORTSYS = 'CYGWIN' ]; then
    export PORTABLEPATH=/cygdrive/$HOMEDRIVEL$PORTFOLDER
elif [ $PORTSYS = 'Linux' ] && [ `uname -a|awk '{print $4}'|cut -d'-' -f2` = Microsoft ];then
    export PORTABLEPATH=/mnt/$HOMEDRIVEL/$PORTFOLDER
    export VAGRANT_WSL_WINDOWS_ACCESS_USER_HOME_PATH=$DEFVAGRANTWSLHOME
    export VAGRANT_WSL_ENABLE_WINDOWS_ACCESS="1"
    export PATH=/mnt/c/Windows/System32:/mnt/c/Windows/System32/WindowsPowerShell/v1.0:$PATH
    startwslssh
else
    export PORTABLEPATH=/$HOMEDRIVEL$PORTFOLDER
fi

#
# Section - portable application setup 
#
# portable production tool
if [ -d $PORTABLEPATH/7z ]; then
    alias 7zp=$PORTABLEPATH/7z/7-ZipPortable.exe
    export PATH=$PORTABLEPATH/7z/App/7-Zip64:$PATH
fi
if [ -d $PORTABLEPATH/imgburn ]; then
    alias img=$PORTABLEPATH/imgburn/ImgBurn.exe
fi
if [ -d $PORTABLEPATH/filezilla ]; then
    alias fzp=$PORTABLEPATH/filezilla/FileZillaPortable.exe
fi
if [ -d $PORTABLEPATH/qdir ]; then
    alias qdir=$PORTABLEPATH/qdir/Q-Dir_64.exe
fi
if [ -d $PORTABLEPATH/scite ]; then
    alias scite=$PORTABLEPATH/scite/SciTE.exe
fi
if [ -d $PORTABLEPATH/sublimetext3 ]; then
    alias st3=$PORTABLEPATH/sublimetext3/sublime_text.exe
    # only for cmder, start sublime text3 in split window
    if [ `env|grep CMDER_ROOT` ];then
        alias st="$PORTABLEPATH/sublimetext3/sublime_text.exe $* -new_console:s50H"
    fi
fi
if [ -d $PORTABLEPATH/markdownpad2 ]; then
    alias mp=$PORTABLEPATH/markdownpad2/MarkdownPad2.exe
fi
if [ -d $PORTABLEPATH/greenshot ]; then
    alias gshot=$PORTABLEPATH/greenshot/Greenshot.exe
fi
if [ -d $PORTABLEPATH/kitty ]; then
    alias kitty=$PORTABLEPATH/kitty/kitty_portable.exe
fi
if [ -d $PORTABLEPATH/putty ]; then
    alias putty=$PORTABLEPATH/putty/putty.exe
fi
if [ -d $PORTABLEPATH/freecommander ]; then
    alias fc=$PORTABLEPATH/freecommander/FreeCommanderPortable.exe
fi
if [ -d $PORTABLEPATH/brackets ]; then
    alias bk=$PORTABLEPATH/brackets/BracketsPortable.exe
fi

if [ -d $PORTABLEPATH/git ]; then
    export PATH=$PATH:$PORTABLEPATH/git/mingw64/bin
fi

# portable calibre tool
if [ -d $PORTABLEPATH/calibre ]; then
    export PATH=$PORTABLEPATH/calibre/Calibre:$PATH
    alias calibrep=$PORTABLEPATH/calibre/calibre-portable.exe
fi

# setup VirtualBox path 
if [ $PORTSYS = 'CYGWIN' ];then 
    export VBOX_MSI_INSTALL_PATH=/cygdrive/c/Program_Files/Oracle/VirtualBox/
elif [ $PORTSYS = 'Linux' ] && [ `uname -a|awk '{print $4}'|cut -d'-' -f2` = Microsoft ];then
    export VBOX_MSI_INSTALL_PATH=/mnt/c/Program_Files/Oracle/VirtualBox/
    alias VBoxManage=VBoxManage.exe
else
    export VBOX_MSI_INSTALL_PATH=/c/Program_Files/Oracle/VirtualBox/
fi 

export PATH=$VBOX_MSI_INSTALL_PATH:$PATH

# portable docker toolbox
if [ -d $PORTABLEPATH/dockertoolbox ]; then
    export PATH=$PORTABLEPATH/dockertoolbox:$PATH
    alias dm=$PORTABLEPATH/dockertoolbox/docker-machine.exe
    alias dc=$PORTABLEPATH/dockertoolbox/docker-compose.exe

    # function to setup env for docker vm host
    denv(){
    if [ $PORTSYS = 'Linux' ] && [ `uname -a|awk '{print $4}'|cut -d'-' -f2` = Microsoft ]; then
            eval $(dm env "$@" --shell bash |sed -e 's|\\|/|g' -e 's|C:/|/mnt/c/|g')
    else
            eval $(dm env "$@" --shell bash) 
    fi
    }

    export -f denv

    # directly ssh to docker vm when docker-machine env not working well
    dmssh(){
        sshport=`VBoxManage showvminfo "$1"|grep 127.0.0.1|grep ssh |awk -F',' '{print $4}'|awk -F'=' '{print $2}'`
        sshkeywinpath=`dm inspect "$1"|grep SSHKeyPath|awk '{print $2}'|awk -F, '{print $1}'|awk -F\" '{print $2}'`
        if [ $PORTSYS = 'Linux' ] && [ `uname -a|awk '{print $4}'|cut -d'-' -f2` = Microsoft ]; then
            sshkey=`echo $sshkeywinpath|sed -e 's|\\\\|/|g' -e 's|C:/|/mnt/c/|g'|sed 's|//|/|g'`
        else
            sshkeycygpath=`cygpath -ml $sshkeywinpath`
            sshkeydrive=`echo $sshkeycygpath|awk -F:  '{print $1}'`
            sshkeypath=`echo $sshkeycygpath|awk -F:  '{print $2}'`
            if [ $PORTSYS = 'CYGWIN' ]; then
                sshkey='/cygdrive/'$sshkeydrive$sshkeypath
            else
                sshkey='/'$sshkeydrive$sshkeypath
            fi
        fi 
        shift
        ssh -o PasswordAuthentication=no -o StrictHostKeyChecking=no docker@127.0.0.1 -o IdentitiesOnly=yes -i $sshkey -p $sshport "$@"
    }
    export -f dmssh

    # alias for Go native ssh when local ssh client not working
    alias nassh='dm --native-ssh ssh'

    # remedy for local docker test without TLS verification when firewall existing
    dockerfw(){
        check2375=`VBoxManage showvminfo "$1"|grep 127.0.0.1|grep 2375|cut -d, -f4|cut -d= -f2`
        if [ $check2375 == '2375' ]; then 
            # if 127.0.0.1 2375 forward exist, skip
            echo 
        else 
            VBoxManage controlvm "$1" natpf1 docker-fw,tcp,127.0.0.1,2375,,2376 
        fi 

        certwinpath=`dm inspect "$1"|grep StorePath|tail -1|awk '{print $2}'|awk -F, '{print $1}'|awk -F\" '{print $2}'`
        certcygpath=`cygpath -ml $certwinpath`
        certdrive=`echo $certcygpath|awk -F:  '{print $1}'`
        certpath=`echo $certcygpath|awk -F:  '{print $2}'`
        if [ $PORTSYS = 'CYGWIN' ]; then
           dockercert='/cygdrive/'$certdrive$certpath
        else
           dockercert='/'$certdrive$certpath
        fi

        export DOCKER_MACHINE_NAME="$1" 
        export DOCKER_HOST="tcp://127.0.0.1:2375" 
        export DOCKER_CERT_PATH=$dockercert
        alias docker='docker --tls'  
    }
    export -f dockerfw

    # remedy for minikube test without TLS verification when firewall existing
    minikubefw(){
        check8443=`VBoxManage showvminfo minikube|grep 127.0.0.1|grep 8443|cut -d, -f4|cut -d= -f2`
        if [ $check8443 == '8443' ]; then 
            # if 127.0.0.1 8443 forward exist, skip
            echo 
        else 
            VBoxManage controlvm minikube natpf1 k8s-apiserver,tcp,127.0.0.1,8443,,8443
        fi 

        check2374=`VBoxManage showvminfo minikube|grep 127.0.0.1|grep 2374|cut -d, -f4|cut -d= -f2`
        if [ $check2374 == '2374' ]; then 
            # if 127.0.0.1 2374 forward exist, skip
            echo 
        else 
            VBoxManage controlvm minikube natpf1 k8s-docker,tcp,127.0.0.1,2374,,2376
        fi

        check30000=`VBoxManage showvminfo minikube|grep 127.0.0.1|grep 30000|cut -d, -f4|cut -d= -f2`
        if [ $check30000 == '30000' ]; then 
            # if 127.0.0.1 30000 forward exist, skip
            echo 
        else 
            VBoxManage controlvm minikube natpf1 k8s-dashboard,tcp,127.0.0.1,30000,,30000
        fi 

        kubectl config set-cluster minikube-vpn --server=https://127.0.0.1:8443 --insecure-skip-tls-verify
        kubectl config set-context minikube-vpn --cluster=minikube-vpn --user=minikube
        kubectl config use-context minikube-vpn  

        eval $(minikube docker-env) 
        unset DOCKER_TLS_VERIFY
        export DOCKER_HOST="tcp://127.0.0.1:2374"
        alias docker='docker --tls'
    }
    export -f minikubefw

fi

# portable vagrant
if [ -d $PORTABLEPATH/vagrant ]; then
    export PATH=$PORTABLEPATH/vagrant/bin:$PATH
fi

# portable netsnmp
if [ -d $PORTABLEPATH/netsnmp ]; then
    export PATH=$PORTABLEPATH/netsnmp/usr/bin:$PATH
fi

# portable Golang
if [ -d $PORTABLEPATH/go ]; then
    export GOROOT=$PORTABLEPATH/go
    #if [ ! -d $HOME/testgo ]; then
    #    mkdir -p $HOME/testgo
    #fi 
    #export GOPATH=$HOME/testgo
    export GOPATH=/j/oldhorse/test/go
    export GOBIN=$GOPATH/bin
    export PATH=$GOBIN:$GOROOT/bin:$PATH
fi

# portable Lua
if [ -d $PORTABLEPATH/Lua ]; then
    export LUA_DEV=$PORTABLEPATH/Lua/5.1
    #export LUA_PATH=$PORTABLEPATH/Lua/5.1/lua/?.luac
    export PATH=$LUA_DEV:$LUA_DEV/clibs:$PATH
    alias lua=$LUA_DEV/lua.exe
fi

# portable R
if [ -d $PORTABLEPATH/R ]; then
    export PATH=$PORTABLEPATH/R/R-3.3.1/bin/x64:$PATH
fi

# portable ruby
if [ -d $PORTABLEPATH/ruby23 ]; then
    export PATH=$PORTABLEPATH/ruby23/bin:$PATH
fi

# portable mingw64 on msys2
if [ -d $PORTABLEPATH/msys64/mingw64 ];then
    export PATH=$PORTABLEPATH/msys64/mingw64/bin:$PATH
fi

# portable cmder and cmdermini
if [ -d $PORTABLEPATH/cmdermini ]; then
    alias cmdermini=$PORTABLEPATH/cmdermini/cmder.exe
fi

# portable console2
if [ -d $PORTABLEPATH/console2 ]; then
    alias console2=$PORTABLEPATH/console2/Console.exe
fi 

# portable consolez
if [ -d $PORTABLEPATH/consolez ]; then
    alias consolez=$PORTABLEPATH/consolez/Console.exe
fi 

# portable gitbook editor
if [ -d $PORTABLEPATH/gitbookeditor ]; then
    export PATH=$PORTABLEPATH/gitbookeditor/app-6.2.1:$PATH
    alias gitbooked='cd $PORTABLEPATH/gitbookeditor/app-6.2.1;echo $HOME;$PORTABLEPATH/gitbookeditor/Update.exe --processStart Editor.exe'
fi

# portable nginx 
if [ -d $PORTABLEPATH/nginx ]; then
    export PATH=$PORTABLEPATH/nginx:$PATH
    alias nginxstart='cd $PORTABLEPATH/nginx; ./nginx'
    alias nginxstop='cd $PORTABLEPATH/nginx; ./nginx -s stop'
    alias nmpstart='source $PORTABLEPATH/nginx/nmp_start.sh'
    alias nmpstop='source $PORTABLEPATH/nginx/nmp_stop.sh'
fi

# portable php
if [ -d $PORTABLEPATH/php ]; then
    export PATH=$PORTABLEPATH/php:$PATH
    alias phpcgi='cd $PORTABLEPATH/php; ./php-cgi -b 127.0.0.1:9000 -c ./php.ini'
fi

# portable mysql
if [ -d $PORTABLEPATH/mysql ]; then
    export PATH=$PORTABLEPATH/mysql/bin:$PATH
    alias mysqldstart='cd $PORTABLEPATH/mysql/bin; ./mysqld --console'
    alias mysqldstop='mysqladmin shutdown -u root -p'
fi

# portable redis
if [ -d $PORTABLEPATH/redis ]; then
    export PATH=$PORTABLEPATH/redis:$PATH
fi

# portable wkhtmltopdf
if [ -d $PORTABLEPATH/wkhtmltopdf ]; then
    export PATH=$PORTABLEPATH/wkhtmltopdf:$PORTABLEPATH/wkhtmltopdf/bin:$PATH
fi

# portable pdflatex
if [ -d $PORTABLEPATH/miktex ]; then
    export PATH=$PORTABLEPATH/miktex/miktex/bin:$PATH
fi

# portable pandoc
if [ -d $PORTABLEPATH/pandoc ]; then
    export PATH=$PORTABLEPATH/pandoc:$PATH
fi

#  gcloud sdk
if [ -d $PORTABLEPATH/gcsdk ]; then
    export PATH=$PORTABLEPATH/gcsdk/google-cloud-sdk/bin:$PATH
    export CLOUDSDK_PYTHON=$PORTABLEPATH/gcsdk/google-cloud-sdk/platform/bundledpython/python
fi

# ssh-agent
eval $(ssh-agent -s)
 
if [ ! -e /home/$USERNAME/.ssh/id_rsa ]; then
    echo "ssh key not exist: /home/$USERNAME/.ssh/id_rsa"
    echo "please generate it using ssh-keygen"
else
    ssh-add /home/$USERNAME/.ssh/id_rsa
fi 

# common alias
alias ll='ls -ltra'

if [ $PORTSYS = 'Linux' ] && [ `uname -a|awk '{print $4}'|cut -d'-' -f2` = Microsoft ];then
    echo
else
    alias pwdw='cygpath -ml `pwd`'
fi

# welcome 
echo
echo "Welcome to portabledevops"
echo "Platform: "$PORTSYS
echo "Home: "$HOME
echo "Portable path: "$PORTFOLDER
echo "Driver: "$HOMEDRIVEL
echo "Shortcut: alias|grep "$PORTFOLDER
date
echo
