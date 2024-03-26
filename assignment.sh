#!/usr/bin/env bash

# Write down your name and studentnumber of the author(s)
# Rens Mulder (1048912)

# Global variables
# TODO Define (only) the variables which require global scope

# Defining variables from config
CONFIG_FILE="dev.conf"
INSTALL_DIR=$(cat $CONFIG_FILE | grep INSTALL_DIR | cut -d '=' -f2)
MINECRAFT_URL=$(cat $CONFIG_FILE | grep MINECRAFT_URL | cut -d '=' -f2)
BUILDTOOLS_URL=$(cat $CONFIG_FILE | grep BUILDTOOLS_URL | cut -d '=' -f2)
SPIGOTSERVER_PORT=$(cat $CONFIG_FILE | grep SPIGOTSERVER_PORT | cut -d '=' -f2)


# INSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function install_with_apt() {
    # Do NOT remove next line!    
    echo "function install_with_apt"

    package=$1
    if [[ -z "$package" ]]; then
        handle_error "No package specified"
    fi
    # TODO 
        # add apt command to update apt sources list
    if ! sudo apt update; then
        handle_error "Could not update apt sources list"
    fi
        # add apt command to install the package
    if ! sudo apt install -y "$package"; then
        handle_error "Could not install $package"
    fi
        # add apt command to autoremove packages 
    if ! sudo apt autoremove -y; then
        handle_error "Could not autoremove packages"
    fi
    
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function install_package() {
    # Do NOT remove next line!
    echo "function install_package"

    # read the arguments from $@
    # Make sure NOT to use empty argument values
    if [[ -z "$1" ]]; then
        handle_error "No package specified"
    fi
    package=$1
    # TODO make sure the following dependencies have been installed
        # BuildTools (https://hub.spigotmc.org/jenkins/job/BuildTools/)
    
    # gdebi (https://manpages.debian.org/buster/gdebi-core/gdebi.1.en.html)
    if ! gdebi --version > /dev/null || ! wget --version > /dev/null || ! make --version > /dev/null; then
        handle_error "Missing dependencies, make sure to run the setup first"
    fi

    # TODO Install required packages with APT     
        # add apt command to update apt sources list
        # add apt command to install the package        
    
    # TODO General
        # the URLS needed to download installation files must be read automatically from dev.conf 
        # the logic for downloading from a URL and installing the application with the installationfile with the proper installation tool
        # specific actions that need to be taken for a specific application during this process should be handled in a separate if-else or switch statement
        # every intermediate steps need to be handeld carefully. error handeling should be dealt with using handle_error() and/or rolleback()
        # if a file is downloaded but canNOT be installed, a rollback is needed to be able to start from scratch
        # create a specific installation folder for the current package
        # make sure to provide the user with sufficient permissions to this folder
        # make sure to handle every intermediate mistake and rollback if something goes wrong like permission erros and unreachble URL etc.

    # TODO application specific logic
    # based on the name of the application additional steps might be needed

        # TODO SPIGOTSERVER 
        # Copy spigotstart.sh to ${HOME}/apps/spigotserver and provide the user with execute permission
        # spigotserver will be stored into ${HOME}/apps/spigotserver
    if [[ "$package" == "minecraft" ]]; then  
        # TODO MINECRAFT 
        # Download minecraft.deb and install it with gdebi\

        if [ -d "$INSTALL_DIR/minecraft" ]; then
            handle_error "Minecraft installation directory already exists."
        fi
         if dpkg -s minecraft-launcher >/dev/null 2>&1; then
            handle_error "minecraft-launcher is already installed"
        fi

        # If minecraft has not been installed yet, create the installation directory
        if ! mkdir "$INSTALL_DIR/minecraft"; then
            handle_error "Could not create Minecraft installation directory."
        fi
        echo "Minecraft installation directory created."

        # From here on, we might have to rollback if something goes wrong
        if ! wget -O "$INSTALL_DIR/minecraft/minecraft.deb" "$MINECRAFT_URL"; then
            handle_error "Could not download Minecraft installation file" "rollback_minecraft"
        fi
        if ! sudo gdebi -n "$INSTALL_DIR/minecraft/minecraft.deb"; then
            handle_error "Could not install Minecraft" "rollback_minecraft"
        fi
        echo "Minecraft installed successfully."

    fi
    # TODO if something goes wrong then call function handle_error

}


# CONFIGURATION

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function configure_spigotserver() {
    # Do NOT remove next line!
    echo "function configure_spigotserver"

    # TODO Configure Firewall
        # make sure ufw has been installed    

    # TODO allow SSH port with ufw allow OpenSSH
        # use ufw to allow the port that is specified in dev.conf for the Spigot server to accept connections
        # make sure ufw has been enabled

    # TODO configure spigotserver to run creative gamemode instead of survival 
        # this can be done by running the sed command on the (automatically generated) file server.properties 
        # (https://minecraft.fandom.com/wiki/Server.properties)
        # with the argument 's/\(gamemode=\)survival/\1creative/'

    # TODO restart the spigot service

    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function create_spigotservice() {
    # Do NOT remove next line!
    echo "function create_spigotservice"
    
    # TODO copy spigot.service to /etc/systemd/system/spigot.service

    # TODO reload the service daemon (systemctl daemon-reload)
    # TODO enable the service using systemctl

    # TODO if something goes wrong then call function handle_error

}

# ERROR HANDLING

# TODO complete the implementation of this function
function handle_error() {
    # Do NOT remove next line!
    echo "function handle_error"

    # read the arguments from $@
    # Make sure NOT to use empty argument values
    
    # Check if follow up action is passed as argument
    if [[ -n "$2" ]]; then
        $2
    fi

    # print a specific error message
    if [[ -z "$1" ]]; then
        echo "An error occured"
    else
        echo "$1"
    fi
    # exit this function with an integer value!=0
    exit 1
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_minecraft() {
    # Do NOT remove next line!
    echo "function rollback_minecraft"

    # if something goes wrong then call function handle_error
    # check if minecraft is installed
    if dpkg -s minecraft-launcher >/dev/null 2>&1; then
        minecraft-launcher --clean
        sudo apt remove -y minecraft-launcher
    else
        echo "minecraft-launcher is not installed, disregarding minecraft uninstallation rollback step"
    fi
    

    if [ -d "$INSTALL_DIR/minecraft" ]; then
        rm -rf "$INSTALL_DIR/minecraft"
    fi

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_spigotserver {
    # Do NOT remove next line!
    echo "function rollback_spigotserver"

    # TODO if something goes wrong then call function handle_error

}


# UNINSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_minecraft {
    # Do NOT remove next line!
    echo "function uninstall_minecraft"  

    # TODO remove the directory containing minecraft 
    if [ -d "$INSTALL_DIR/minecraft" ]; then
        rm -rf "$INSTALL_DIR/minecraft"
    else
        # Not handling this as an error, as the package might still be installed
        echo "Minecraft installation directory does not exist"
    fi

    # check if minecraft is installed
    if dpkg -s minecraft-launcher >/dev/null 2>&1; then
        # minecraft-launcher --clean
        sudo apt remove -y minecraft-launcher
    else
        handle_error "minecraft-launcher is not installed"
    fi
    echo "Minecraft uninstalled successfully"
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotserver {
    # Do NOT remove next line!
    echo "uninstall_spigotserver"  
    
    # TODO remove the directory containing spigotserver 

    # TODO create a service by calling the function create_spigotservice

    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotservice {
    # Do NOT remove next line!
    echo "uninstall_spigotservice"

    # TODO disable the spigotservice with systemctl disable
    # TODO delete /etc/systemd/system/spigot.service

    # TODO if something goes wrong then call function handle_error
    
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function remove() {
    # Do NOT remove next line!
    echo "function remove"

    # TODO Remove all packages and dependencies

    # TODO if something goes wrong then call function handle_error

}


# TEST

# TODO complete the implementation of this function
function test_minecraft() {
    # Do NOT remove next line!
    echo "function test_minecraft"
    if ! rm -rf $HOME/.minecraft/launcher_log*; then
        handle_error "Could not remove old minecraft logs"
    fi
    # TODO Start minecraft 
    handle_error "Could not start minecraft"
    minecraft_pid=$!
    # TODO Check if minecraft is working correctly
        # e.g. by checking the logfile
    echo "Waiting 30 seconds for minecraft to start"
    sleep 30
    if [ "$(find "$HOME/.minecraft" -type f -exec grep -l "launcher_log" {} +)" ]; then
        echo "Minecraft is working correctly"
    else
        handle_error "Minecraft is not working correctly" "kill -9 $minecraft_pid"
    fi
    # TODO Stop minecraft after testing
        # use the kill signal only if minecraft canNOT be stopped normally
    # Check if the process is still running, p 
    if ps -p $minecraft_pid > /dev/null; then
        # If it's still running, send SIGTERM to gracefully stop it
        kill $minecraft_pid &
        echo "Attempting to stop minecraft gracefully"
    fi
    # Wait for the process to stop
    echo "Waiting 10 seconds for minecraft to stop"
    sleep 10
    # If the process is still running, send SIGKILL to forcefully stop it
    if ps -p $minecraft_pid > /dev/null; then
        kill -9 $minecraft_pid
        echo "Forcibly stopping minecraft"
    fi
}

function test_spigotserver() {
    # Do NOT remove next line!
    echo "function test_spigotserver"    

    # TODO Start the spigotserver

    # TODO Check if spigotserver is working correctly
        # e.g. by checking if the API responds
        # if you need curl or aNOTher tool, you have to install it first

    # TODO Stop the spigotserver after testing
        # use the kill signal only if the spigotserver canNOT be stopped normally

}

function setup() {
    # Do NOT remove next line!
    echo "function setup"    

    # TODO Install required packages with APT     
    if ! install_with_apt "gdebi" || ! install_with_apt "make" || ! install_with_apt "wget" || ! install_with_apt "curl" || ! install_with_apt "default-jre" || ! install_with_apt "ufw"; then
        handle_error "Could not install required packages"
    fi

    # Create the installation directory
    if [ -d "$INSTALL_DIR" ]; then
        handle_error "Installation directory already exists."
    fi
    if ! mkdir "$INSTALL_DIR"; then
        handle_error "Could not create installation directory."
    fi
    echo "Installation directory created."
    echo "Script has been set up!"
}

function main() {
    # Do NOT remove next line!
    echo "function main"

    # TODO read the arguments from $@
        # make sure NOT to use empty argument values
    if [[ -z "$1" ]]; then
        handle_error "No argument specified"
    fi

    case "$1" in
        setup)
            setup
            ;;
        minecraft)
            if [[ -z "$2" ]]; then
                handle_error "No argument specified"
            fi
            case "$2" in
                --install)
                    install_package "minecraft"
                    ;;
                --test)
                    test_minecraft
                    ;;
                --uninstall)
                    uninstall_minecraft
                    ;;
                *)
                    handle_error "Invalid argument"
                    ;;
            esac
            ;;
        *)
            handle_error "Invalid argument. Valid arguments are: setup, minecraft, spigot"
            ;;
    esac

    # TODO use a switch statement to execute

        # setup that creates the installation directory and installs all required dependencies           

        # remove that removes installation directory and uninstalls all required dependencies (even if they were already installed)

        # minecraft with an argument that specifies the one of the following actions
            # installation of minecraft client
            # test
            # uninstall of minecraft client

        # spigot with an argument that specifies the one of the following actions
            # installation of both spigot server and service
            # test
            # uninstall of both spigot server and service

}

main "$@"
