sudo touch "/etc/wodos/tools/osversion.txt"
echo "1" > "/etc/wodos/tools/osversion.txt"


sudo wget -O /etc/wodos/tools/updater.sh https://github.com/x-FK-x/1002xTOOLS/releases/download/wodos-updater/updater.sh
sudo chmod +x /etc/wodos/tools/updater.sh


# === Rückkehrmenü ===
while true; do
    ACTION=$(whiptail --title "Updater finished" --menu "What do you want to do now?" 10 50 2 \
        "1" "Return to main menu" \
        "2" "Exit 1002xTOOLS" 3>&1 1>&2 2>&3)

    case "$ACTION" in
        "1")
            bash "$SCRIPT_DIR/debui.sh"
            ;;
        "2")
            exit 0
            ;;
        *)
            whiptail --msgbox "Invalid option. Please choose again." 8 40
            ;;
    esac
done
