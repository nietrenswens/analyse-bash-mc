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

    # Check if required directory structure and dependencies are there.
    setup_check

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

    #  application specific logic
    # based on the name of the application additional steps might be needed
    if [[ "$package" == "minecraft" ]]; then  
        # TODO MINECRAFT 
        # Download minecraft.deb and install it with gdebi\
        echo "Starting minecraft installation"
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
        exit 0
    fi
    if [[ "$package" == "spigotserver" ]]; then
        echo "Starting spigot installation"
        if [ -d "$INSTALL_DIR/spigotserver" ]; then
            handle_error "Spigotserver installation directory already exists."
        fi
        if ! mkdir "$INSTALL_DIR/spigotserver"; then
            handle_error "Could not create Spigotserver installation directory."
        fi

        # From here, we might need to rollback
        echo "Downloading buildtools..."
        if ! wget -O "$INSTALL_DIR/spigotserver/BuildTools.jar" $BUILDTOOLS_URL; then
            handle_error "Unable to download buildtools, canceling installation..." "rollback_spigotserver"
        fi
        echo "Compiling server binary..."
        if ! java -jar "$INSTALL_DIR/spigotserver/BuildTools.jar" --rev latest --output-dir "$INSTALL_DIR/spigotserver" --final-name spigot.jar; then
            handle_error "Unable to compile spigotserver" "rollback_spigotserver"
        fi
        echo "Cleaning up buildtools..."
        cleanup_buildtools
        echo "Binary compiled successfully. Copying start script..." 
        if ! cp spigotstart.sh "$INSTALL_DIR/spigotserver"; then
            handle_error "Unable to copy start script" "rollback_spigotserver"
        fi
        echo "Start script copied successfully. Setting permissions..."
        if ! chmod +x "$INSTALL_DIR/spigotserver/spigotstart.sh"; then
            handle_error "Unable to set permissions on start script" "rollback_spigotserver"
        fi
        echo "Permissions set successfully. Spigotserver installed successfully."

        echo "Starting server to generate server.properties..."
        current_dir=$(pwd)
        cd "$INSTALL_DIR/spigotserver"

        ./spigotstart.sh

        cd "$current_dir"
        
        
        echo "Creating service..."
        create_spigotservice
        echo "Service created successfully."
        echo "Moving on to configuring the server..."
        configure_spigotserver
        echo "Spigot server installation completed successfully."
        exit 0

        # TODO SPIGOTSERVER 
            # Copy spigotstart.sh to ${HOME}/apps/spigotserver and provide the user with execute permission
            # spigotserver will be stored into ${HOME}/apps/spigotserver
        exit 0
    fi
    # TODO if something goes wrong then call function handle_error

}

function cleanup_buildtools() {
    if [ -d "BuildData" ]; then
        if ! rm -rf "BuildData"; then
            handle_error "Unable to clean up buildtools"
        fi
    fi
    if [ -d "BuildTools" ]; then
        if ! rm -rf "BuildTools"; then
            handle_error "Unable to clean up buildtools"
        fi
    fi
    if [ -d "CraftBukkit" ]; then
        if ! rm -rf "CraftBukkit"; then
            handle_error "Unable to clean up buildtools"
        fi
    fi
    if [ -d "Bukkit" ]; then
        if ! rm -rf "Bukkit"; then
            handle_error "Unable to clean up buildtools"
        fi
    fi
    if [ -d "Spigot" ]; then
        if ! rm -rf "Spigot"; then
            handle_error "Unable to clean up buildtools"
        fi
    fi
    if [ -d "work" ]; then
        if ! rm -rf "work"; then
            handle_error "Unable to clean up buildtools"
        fi
    fi
    if [ -f "BuildTools.log.txt" ]; then
        if ! rm -rf "BuildTools.log.txt"; then
            handle_error "Unable to clean up buildtools"
        fi
    fi
    if [ -d "apache-maven-3.9.6" ]; then
        if ! rm -rf "apache-maven-3.9.6"; then
            handle_error "Unable to clean up buildtools"
        fi
    fi
}


# CONFIGURATION

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function configure_spigotserver() {
    # Do NOT remove next line!
    echo "function configure_spigotserver"

    # TODO Configure Firewall
        # make sure ufw has been installed    
    if ! sudo ufw --version > /dev/null; then
        handle_error "ufw is not installed" rollback_spigotserver
    fi
    # TODO allow SSH port with ufw allow OpenSSH
        # use ufw to allow the port that is specified in dev.conf for the Spigot server to accept connections
        # make sure ufw has been enabled
    if ! sudo ufw allow 22/tcp; then
        handle_error "Could not allow OpenSSH" rollback_spigotserver
    fi
    if ! sudo ufw allow "$SPIGOTSERVER_PORT"; then
        handle_error "Could not allow port $SPIGOTSERVER_PORT" rollback_spigotserver
    fi
    if ! sudo ufw enable; then
        handle_error "Could not enable ufw" rollback_spigotserver
    fi

    # TODO configure spigotserver to run creative gamemode instead of survival 
        # this can be done by running the sed command on the (automatically generated) file server.properties 
        # (https://minecraft.fandom.com/wiki/Server.properties)
        # with the argument 's/\(gamemode=\)survival/\1creative/'
    if ! sed -i 's/\(gamemode=\)survival/\1creative/' "$INSTALL_DIR/spigotserver/server.properties"; then
        handle_error "Could not change gamemode to creative" rollback_spigotserver
    fi
    # TODO restart the spigot service
    if ! sudo systemctl restart spigot; then
        handle_error "Could not restart spigot service" rollback_spigotserver
    fi
    echo "Spigotserver configured successfully"
    # TODO if something goes wrong then call function handle_error

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function create_spigotservice() {
    # Do NOT remove next line!
    echo "function create_spigotservice"
    
    # TODO copy spigot.service to /etc/systemd/system/spigot.service
    if ! sudo cp spigot.service /etc/systemd/system/spigot.service; then
        handle_error "Could not copy spigot.service to /etc/systemd/system" "rollback_spigotserver"
    fi

    # TODO reload the service daemon (systemctl daemon-reload)
    if ! sudo systemctl daemon-reload; then
        handle_error "Could not reload the service daemon" "rollback_spigotserver"
    fi
    # TODO enable the service using systemctl
    if ! sudo systemctl enable spigot; then
        handle_error "Could not enable the service" "rollback_spigotserver"
    fi
    # TODO if something goes wrong then call function handle_error

}

# ERROR HANDLING

# TODO complete the implementation of this function
function handle_error() {
    # Do NOT remove next line!
    echo "function handle_error"

    # read the arguments from $@
    # Make sure NOT to use empty argument values
    # print a specific error message
    if [[ -z "$1" ]]; then
        echo "An error occured"
    else
        echo "$1"
    fi
    # Check if follow up action is passed as argument
    if [[ -n "$2" ]]; then
        $2
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
    echo "Checking if minecraft has already been installed".
    if dpkg -s minecraft-launcher >/dev/null 2>&1; then
        echo "Minecraft is installed. Attempting to remove it."
        # The clean command does not seem to work. Leaving it out for now
        # minecraft-launcher --clean
        if ! sudo apt remove -y minecraft-launcher; then
            handle_error "Unable to remove minecraft-launcher... Use the following command to remove minecraft manually: sudo apt remove -y minecraft-launcher."
        fi
    else
        echo "minecraft-launcher is not installed, disregarding minecraft uninstallation rollback step."
    fi
    

    if [ -d "$INSTALL_DIR/minecraft" ]; then
        if ! rm -rf "$INSTALL_DIR/minecraft"; then
            handle_error "Unable to remove $INSTALL_DIR/minecraft, please remove it manually."
        fi
    fi

}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function rollback_spigotserver {
    # Do NOT remove next line!
    echo "function rollback_spigotserver"

    echo "Rolling back..."
    cleanup_buildtools
    echo "Removing spigotserver..."
    if [ -d "$INSTALL_DIR/spigotserver" ]; then
        if ! rm -rf "$INSTALL_DIR/spigotserver"; then
            echo "Unable to remove $INSTALL_DIR/spigotserver, please remove it manually."
        fi
    fi
    if [ -f "/etc/systemd/system/spigot.service" ]; then
        echo "Removing spigot service..."
        if ! sudo systemctl disable spigot; then
            echo "Unable to disable spigot service, please disable it manually."
        fi
        if ! sudo rm -rf "/etc/systemd/system/spigot.service"; then
            echo "Unable to remove /etc/systemd/system/spigot.service, please remove it manually."
        fi
    fi
    echo "Rollbacking ufw..."
    if ! sudo ufw disable; then
        echo "Unable to disable ufw, please disable it manually."
    fi
    if ! sudo ufw delete allow "$SPIGOTSERVER_PORT"; then
        echo "Unable to remove port $SPIGOTSERVER_PORT from ufw, please remove it manually."
    fi
    if ! sudo ufw delete allow 22/tcp; then
        echo "Unable to remove port 22 from ufw, please remove it manually."
    fi

    echo "Rollback completed successfully"
    # TODO if something goes wrong then call function handle_error

}


# UNINSTALL

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_minecraft {
    # Do NOT remove next line!
    echo "function uninstall_minecraft" 

    # Check if the required directory structure and dependencies are there. 
    setup_check

    # Actual uninstalling
    echo "Uninstalling minecraft..."
    echo "Checking if minecraft directory exists..."
    # TODO remove the directory containing minecraft 
    if [ -d "$INSTALL_DIR/minecraft" ]; then
        echo "Directory exists... Attempting to remove it..."
        if ! rm -rf "$INSTALL_DIR/minecraft"; then
            handle_error "Could not remove $INSTALL_DIR/minecraft."
        fi
    else
        # Not handling this as an error, as the package might still be installed
        echo "Minecraft installation directory does not exist. Still attempting to uninstall the package."
    fi

    # check if minecraft is installed
    if dpkg -s minecraft-launcher >/dev/null 2>&1 && sudo apt remove -y minecraft-launcher; then
        # minecraft-launcher --clean
        echo "The minecraft-launcher package has been removed."
    else
        handle_error "minecraft-launcher is not installed. Aborting uninstallation."
    fi
    echo "Minecraft uninstalled successfully"
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function uninstall_spigotserver {
    # Do NOT remove next line!
    echo "uninstall_spigotserver"  
    
    uninstall_spigotservice
    echo "Uninstalling spigotserver..."
    if [ -d "$INSTALL_DIR/spigotserver" ]; then
        if ! rm -rf "$INSTALL_DIR/spigotserver"; then
            handle "Unable to remove $INSTALL_DIR/spigotserver, please remove it manually."
        fi
    fi

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
    echo "Uninstalling spigot service..."
    if [ -f "/etc/systemd/system/spigot.service" ]; then
        if ! sudo systemctl disable spigot; then
            echo "Unable to disable spigot service, please disable it manually."
        fi
        if ! sudo rm -rf "/etc/systemd/system/spigot.service"; then
            echo "Unable to remove /etc/systemd/system/spigot.service, please remove it manually."
        fi
    fi
    
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function remove() {
    # Do NOT remove next line!
    echo "function remove"

    # TODO Remove all packages and dependencies

    # Check if minecraft is installed, and uninstall it

    # Check if spigot is installed, and uninstall it

    # TODO if something goes wrong then call function handle_error

}

function setup_check() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        handle_error "File structure is missing. Please run the setup first."
    fi
    if ! gdebi --version > /dev/null || ! wget --version > /dev/null || ! make --version > /dev/null || ! curl --version > /dev/null || ! dpkg -s openjdk-17-jre >/dev/null 2>&1 || ! dpkg -s ufw >/dev/null 2>&1; then
        handle_error "Some dependencies are missing.  Please run the setup first."
    fi
}

# TEST

# TODO complete the implementation of this function
function test_minecraft() {
    # Do NOT remove next line!
    echo "function test_minecraft"

    # Check if setup is ran
    setup_check

    if ! dpkg -s minecraft-launcher > /dev/null 2>&1 || [[ ! -d "$INSTALL_DIR/minecraft" ]]; then
        handle_error "Minecraft has not been installed. There is nothing to test"
    fi

    if ! rm -rf "$HOME/.minecraft/launcher_log*"; then
        handle_error "Could not remove old minecraft logs"
    fi
    # TODO Start minecraft 
    minecraft-launcher &
    minecraft_pid=$!
    # TODO Check if minecraft is working correctly
        # e.g. by checking the logfile
    echo "Waiting 30 seconds for minecraft to start"
    sleep 30
    

    # TODO Stop minecraft after testing
        # use the kill signal only if minecraft canNOT be stopped normally
    # Check if the process is still running, p 
    if ps -ef | grep $minecraft_pid | grep -v grep > /dev/null; then
        # If it's still running, send SIGTERM to gracefully stop it
        echo "Minecraft seems to be working correctly, stopping it..."
        kill $minecraft_pid &
        echo "Attempting to stop minecraft gracefully"
    else
        handle_error "Minecraft is not running and thus not working correctly"
    fi
    # Wait for the process to stop
    echo "Waiting 10 seconds for minecraft to stop"
    sleep 10
    # If the process is still running, send SIGKILL to forcefully stop it
    if ps -ef | grep $minecraft_pid | grep -v grep > /dev/null; then
        kill -9 $minecraft_pid
        handle_error "Forcibly stopping minecraft... Minecraft is not working correctly"
    fi
    echo "Minecraft stopped successfully"
    echo "Test completed successfully"
    echo "Minecraft is working correctly"
    exit 0
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
    if ! install_with_apt "gdebi" || ! install_with_apt "make" || ! install_with_apt "wget" || ! install_with_apt "curl" || ! install_with_apt "openjdk-17-jre" || ! install_with_apt "ufw"; then
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
        remove)
            remove
            ;;
        minecraft)
            if [[ -z "$2" ]]; then
                handle_error "No argument specified"
            fi
            case "$2" in
                --install)
                    install_package "minecraft"
                    exit 0
                    ;;
                --test)
                    test_minecraft
                    exit 0
                    ;;
                --uninstall)
                    uninstall_minecraft
                    exit 0
                    ;;
                *)
                    handle_error "Invalid argument"
                    ;;
            esac
            ;;
        spigotserver)
            if [[ -z "$2" ]]; then
                handle_error "No argument specified"
            fi
            case "$2" in
                --install)
                    install_package "spigotserver"
                    exit 0
                    ;;
                --uninstall)
                    uninstall_spigotserver
                    exit 0
                    ;;
                *)
                    handle_error "Invalid argument"
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
