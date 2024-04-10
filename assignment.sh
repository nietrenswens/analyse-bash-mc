#!/usr/bin/env bash

# Write down your name and studentnumber of the author(s)
# Rens Mulder (1048912)

# Global variables
# TODO Define (only) the variables which require global scope
# Dependencies with their respective 'installation check' command
declare -A dependencies=(["gdebi"]="gdebi --version" ["wget"]="wget --version" ["make"]="make --version" ["curl"]="gdebi --version" ["openjdk-17-jre"]="dpkg -s openjdk-17-jre" ["ufw"]="dpkg -s ufw" ["screen"]="dpkg -s screen") 
    # if ! gdebi --version > /dev/null || ! wget --version > /dev/null || ! make --version > /dev/null || ! curl --version > /dev/null || ! dpkg -s openjdk-17-jre >/dev/null 2>&1 || ! dpkg -s ufw >/dev/null 2>&1 || ! dpkg -s screen >/dev/null 2>&1; then

# Defining variables from config
CONFIG_FILE="dev.conf"
INSTALL_DIR=$(grep INSTALL_DIR "$CONFIG_FILE" | cut -d '=' -f2)
HOME_DIR="$HOME"
INSTALL_DIR="${INSTALL_DIR//'$HOME'/$HOME_DIR}"
MINECRAFT_URL=$(grep MINECRAFT_URL "$CONFIG_FILE" | cut -d '=' -f2)
BUILDTOOLS_URL=$(grep BUILDTOOLS_URL "$CONFIG_FILE" | cut -d '=' -f2)
SPIGOTSERVER_PORT=$(grep SPIGOTSERVER_PORT "$CONFIG_FILE" | cut -d '=' -f2)


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
    to_install=$1
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
    if [[ "$to_install" == "minecraft" ]]; then  
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
        if ! mkdir -p "$INSTALL_DIR/minecraft"; then
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
    if [[ "$to_install" == "spigotserver" ]]; then
        echo "Starting spigot installation"
        if [ -d "$INSTALL_DIR/spigotserver" ]; then
            handle_error "Spigotserver installation directory already exists."
        fi
        if ! mkdir -p "$INSTALL_DIR/spigotserver"; then
            handle_error "Could not create Spigotserver installation directory."
        fi

        # From here, we might need to rollback
        echo "Downloading buildtools..."
        if ! wget -O "$INSTALL_DIR/spigotserver/BuildTools.jar" "$BUILDTOOLS_URL"; then
            handle_error "Unable to download buildtools, canceling installation..." "rollback_spigotserver"
        fi
        echo "Compiling server binary..."
        current_dir=$(pwd)
        cd "$INSTALL_DIR/spigotserver" || handle_error "Unable to compile spigotserver" "cd $current_dir && rollback_spigotserver"
        if ! java -jar "$INSTALL_DIR/spigotserver/BuildTools.jar" --rev latest --output-dir "$INSTALL_DIR/spigotserver" --final-name spigot.jar; then
            handle_error "Unable to compile spigotserver" "cd $current_dir && rollback_spigotserver"
        fi
        echo "Cleaning up buildtools..."
        cleanup_buildtools
        echo "$current_dir"
        cd "$current_dir" || handle_error "Error while moving back to work directory" "rollback_spigotserver"
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
        cd "$INSTALL_DIR/spigotserver" || handle_error "Error while moving to server directory" "rollback_spigotserver"

        ./spigotstart.sh

        cd "$current_dir" || handle_error "Error while moving back to work directory" "rollback_spigotserver"
        
        echo "Accepting EULA"
        if ! echo "eula=true" > "$INSTALL_DIR/spigotserver/eula.txt"; then
            handle_error "Unable to accept eula." "rollback_spigotserver"
        fi
        echo "Creating service..."
        create_spigotservice
        echo "Service created successfully."
        echo "Moving on to configuring the server..."
        configure_spigotserver
        echo "Spigot server installation completed successfully."
    fi
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
    if ! sed -i "s/\(server-port=\)25565/\1$SPIGOTSERVER_PORT/" "$INSTALL_DIR/spigotserver/server.properties"; then
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
    if ! sudo systemctl start spigot; then
        handle_error "Could not start the service" "rollback_spigotserver"
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
        if ! sudo systemctl daemon-reload; then
            echo "Unable to reload system daemon"
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
    setup_check 
    if [ ! -d "$INSTALL_DIR/spigotserver" ]; then
        handle_error "Spigot has not been installed"
    fi
    uninstall_spigotservice
    echo "Uninstalling spigotserver..."
    if [ -d "$INSTALL_DIR/spigotserver" ]; then
        if ! rm -rf "$INSTALL_DIR/spigotserver"; then
            handle_error "Unable to remove $INSTALL_DIR/spigotserver, please remove it manually."
        fi
    fi
    echo "Spigot server has been uninstalled"
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
        echo "Removing spigot service..."
        if ! sudo systemctl stop spigot; then
            handle_error "Unable to disable and remove spigot service and server, please disable it manually. And remove the server manually."
        fi
        if ! sudo systemctl disable spigot; then
            handle_error "Unable to disable and remove spigot service and server, please disable it manually. And remove the server manually."
        fi
        if ! sudo rm -rf "/etc/systemd/system/spigot.service"; then
            handle_error "Unable to disable and remove spigot service and server, please disable it manually. And remove the server manually."
        fi
        if ! sudo systemctl daemon-reload; then
            handle_error "Unable to disable and remove spigot service and server, please disable it manually. And remove the server manually."
        fi
    fi
    
}

# TODO complete the implementation of this function
# Make sure to use sudo only if needed
function remove() {
    # Do NOT remove next line!
    echo "function remove"
    # TODO Remove all packages and dependencies
    echo "Removing dependencies"
    for package in "${!dependencies[@]}"; do
        # if package is not installed
        if ${dependencies[$package]} > /dev/null 2>&1; then
            if ! sudo apt remove -y "$package"; then
            handle_error "Could not uninstall $package. Please uninstall it manually"
            fi
        fi
    done

    # Check if minecraft is installed, and uninstall it
    echo "Removing minecraft"
    if [ -d "$INSTALL_DIR/minecraft" ]; then
        uninstall_minecraft
    fi

    # Check if spigot is installed, and uninstall it
    echo "Removing spigot"
    if [ -d "$INSTALL_DIR/spigotserver" ]; then
        uninstall_spigotserver
    fi
    if [ -d "$INSTALL_DIR" ]; then
        if ! rm -rf "$INSTALL_DIR"; then
            handle_error "Unable to remove installation directory ($INSTALL_DIR). Please remove it manually."
        fi
    fi
    echo "Everything has been removed"
}

function setup_check() {
    if [[ ! -d "$INSTALL_DIR" ]]; then
        handle_error "File structure is missing. Please run the setup first."
    fi
    for package in "${!dependencies[@]}"; do
        # if package is not installed
        if ! ${dependencies[$package]} > /dev/null 2>&1; then
            handle_error "$package has not been installed. Please run setup first or install manually"
        fi
    done
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
}

function test_spigotserver() {
    # Do NOT remove next line!
    echo "function test_spigotserver"    
    setup_check
    if [[ ! -d "$INSTALL_DIR/spigotserver" ]]; then
        handle_error "Spigot has not been installed. Nothing to test"
    fi

    # TODO Start the spigotserver
    if [[ ! -f "$INSTALL_DIR/spigotserver/spigotstart.sh" ]]; then
        handle_error "Could not find spigotstart. Canceling test"
    fi

    # Stopping the spigot server service, to stop overlapping ports
    echo "Checking if spigot service is running"
    spigot_service_status=$(systemctl status spigot)
    if [[ $spigot_service_status == *"(running)"* ]]; then
        echo "Stopping spigot service"
        if ! sudo systemctl stop spigot; then
            handle_error "Could not stop spigot-service. Canceling test"
        fi
        sleep 5
    fi

    cd "$INSTALL_DIR/spigotserver" || handle_error "Could not access spigotserver directory"
    java -jar spigot.jar -nogui > /dev/null &
    spigot_pid=$!
    echo "Starting minecraft server and waiting 15 seconds"
    sleep 15
    # TODO Check if spigotserver is working correctly
        # e.g. by checking if the API responds
        # if you need curl or aNOTher tool, you have to install it first
    curl -s "localhost:$SPIGOTSERVER_PORT"
    curl_result="$?"
    if [[ ! "$curl_result" == "52" ]]; then
        if ps -ef | grep $spigot_pid | grep -v grep > /dev/null; then
            kill -9 "$spigot_pid"
        fi
        handle_error "Spigot does not seem to be working correctly" 
    fi
    echo "Stopping spigot gradually"
    # TODO Stop the spigotserver after testing
        # use the kill signal only if the spigotserver canNOT be stopped normally
    if ps -ef | grep $spigot_pid | grep -v grep > /dev/null; then
        # If it's still running, send SIGTERM to gracefully stop it
        kill $spigot_pid &
        echo "Attempting to stop spigot gracefully"
    else
        handle_error "Spigot was not running and thus not working correctly"
    fi

    echo "Waiting 10 seconds for spigot to stop"
    sleep 10
    # If the process is still running, send SIGKILL to forcefully stop it
    if ps -ef | grep $spigot_pid | grep -v grep > /dev/null; then
        kill -9 $spigot_pid
        handle_error "Forcibly stopping Spigot... Spigot is not working correctly"
    fi

    echo "Spigot stopped successfully"
    if [[ $spigot_service_status == *"(running)"* ]]; then
        echo "Starting spigot service"
        if ! sudo systemctl stop spigot; then
            handle_error "Could not stop spigot-service. Canceling test"
        fi
        sleep 5
    fi
    echo "Test completed successfully"
    echo "Spigot is working correctly"
}

function setup() {
    # Do NOT remove next line!
    echo "function setup"    

    # TODO Install required packages with APT     
    for package in "${!dependencies[@]}"; do
        install_with_apt "$package"
    done

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
                --test)
                    test_spigotserver
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