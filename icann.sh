#!/bin/bash

Dig_Nameserver() {
    total=$(cat "$dbfile" | wc -l)
    echo "Total records: $total"
    if [ "$total" -gt 0 ]; then
        echo "List of Domains:"
        cat "$dbfile" | cut -d "|" -f1 | nl

        read -p "Enter the number of the domain you want to dig nameservers for: " selection
        if [ "$selection" -gt 0 ] && [ "$selection" -le "$total" ]; then
            Clear_Screen
            selected_domain=$(sed -n "${selection}p" "$dbfile" | cut -d "|" -f1)
            Name_Servers=$(sed -n "${selection}p" "$dbfile" | cut -d "|" -f11)
            echo "Digging nameservers for selected domain: $(tput setaf 6)$selected_domain$(tput sgr 0)"
            dig +short $Name_Servers
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    fi
}

FindSubdomains() {
    db_file="data"
    if [ ! -f "$db_file" ]; then
        echo "Domain database file not found: $db_file"
        return
    fi

    echo "Available domains:"
    line_number=1
    while IFS='|' read -r domain _; do
        echo "$line_number - $domain"
        ((line_number++))
    done < "$db_file"

    echo "Enter the number corresponding to the domain you want to search subdomains for:"
    read -r choice

    num_domains=$(wc -l < "$db_file")
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "$num_domains" ]; then
        echo "Invalid choice. Please enter a number between 1 and $num_domains."
        return
    fi

    domain=$(sed -n "${choice}p" "$db_file" | cut -d "|" -f 1)

    echo "Finding subdomains for $domain using subfinder..."

    if ! command -v subfinder &> /dev/null; then
        echo "subfinder could not be found. Please install it first."
        return
    fi

    echo "Running subfinder..."
    subfinder -d "$domain" -silent > subdomains.txt
    echo "Subdomains found for $domain:"
    cat subdomains.txt
}

addRecord() {
	echo "$(tput setaf 3)====================================$(tput sgr 0)"
	echo "GETTING $(tput setaf 6)DOMAIN INFORMATION$(tput sgr 0)"	
	echo "$(tput setaf 3)====================================$(tput sgr 0)"
	read -p "Enter the Domain name: " Domain_Name
	Registrant_Name=$(whois $Domain_Name | grep -Ei 'Registrant Name|Registrant Organization' | awk -F':' '{print $2}' | sed -e 's/^[[:space:]]*//')
	Registry_Domain_ID=$(whois $Domain_Name | grep -i "Registry Domain ID" | cut -d ':' -f2 | head -n1)
	Registrar_whois_server=$(whois $Domain_Name | grep -i "Registrar WHOIS Server" | cut -d ':' -f2)
	Registrar_Url=$(whois $Domain_Name | grep -Ei "Registrar URL" | awk -F': ' '{print $2}' | sed -e 's/^[[:space:]]*//')
	Updated_Date=$(whois $Domain_Name | grep -i "Updated Date" | awk -F': ' '{print $2}')
	Creation_Date=$(whois $Domain_Name | grep -i "Creation Date" | awk -F': ' '{print $2}')
	Registrar_Expir_Date=$(whois $Domain_Name | grep -i "Registrar Registration Expiration Date" | awk -F': ' '{print $2}')
	Registrar_Name=$(whois $Domain_Name | grep -i "Registrar:" | awk -F': ' '{print $2}')
	Domain_Emails=$(whois $Domain_Name | grep -Ei "email" | cut -d ':' -f2)
	Name_Servers=$(whois $Domain_Name | tr -d ' ' | awk -F: '{ if ($1 == "NameServer" && length($2)>0) print $2 ;else if ($0 == "NameServers:") found=1; else if (found == 1 && length($0)>0) print $0; else found=0 }'
)
	record="$Domain_Name|$Registrant_Name|$Registry_Domain_ID|$Registrar_whois_server|$Registrar_Url|$Updated_Date|$Creation_Date|$Registrar_Expir_Date|$Registrar_Name|$Domain_Emails|$Name_Servers"
	echo $record >> $dbfile
	echo "Information added successfully."
}

viewAllRecords() {
    total=$(cat "$dbfile" | wc -l)
    echo "Total records: $total"
    if [ "$total" -gt 0 ]; then
        echo "List of Domains:"
        cat "$dbfile" | cut -d "|" -f1 | nl

        read -p "Enter the number of the domain you want to view records for: " selection
        if [ "$selection" -gt 0 ] && [ "$selection" -le "$total" ]; then
            Clear_Screen
            echo "Records for selected domain:"
            selected_domain=$(sed -n "${selection}p" "$dbfile")

            echo "$(tput setaf 6)Name:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f1)"
            echo "$(tput setaf 6)Registrant Name:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f2)"
            echo "$(tput setaf 6)Registry Domain ID:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f3)"
            echo "$(tput setaf 6)Registrar Whois Server:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f4)"
            echo "$(tput setaf 6)Registrar URL:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f5)"
            echo "$(tput setaf 6)Updated Date:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f6)"
            echo "$(tput setaf 6)Creation Date:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f7)"
            echo "$(tput setaf 6)Registrar Registration Expiration Date:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f8)"
            echo "$(tput setaf 6)Registrar Name:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f9)"
            echo "$(tput setaf 6)E-Mails:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f10)"
            echo "$(tput setaf 6)Name Servers:$(tput sgr 0)" "$(echo "$selected_domain" | cut -d "|" -f11)"
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    fi
}

DeleteRecord() {
    total=$(cat "$dbfile" | wc -l)
    echo "Total records: $total"
    if [ "$total" -gt 0 ]; then
        echo "List of Domains:"
        cat "$dbfile" | cut -d "|" -f1 | nl

        read -p "Enter the number of the domain you want to delete: " selection
        if [ "$selection" -gt 0 ] && [ "$selection" -le "$total" ]; then
            domain_to_delete=$(sed -n "${selection}p" "$dbfile" | cut -d "|" -f1)
            if grep -q "^$domain_to_delete|" "$dbfile"; then
                temp_file=$(mktemp)
                grep -v "^$domain_to_delete|" "$dbfile" > "$temp_file"
                if mv "$temp_file" "$dbfile"; then
                    echo "Record for domain $domain_to_delete deleted successfully."
                else
                    echo "Error moving temporary file to $dbfile."
                    rm -f "$temp_file"
                fi
            else
                echo "Domain not found."
            fi
        else
            echo "Invalid selection. Please enter a valid number."
        fi
    else
        echo "No records found in the database."
    fi
}

Main() {
    dbfile="data"

    Clear_Screen() {
        clear
    }

    Pause() {
        read -r -p "Press any key to continue..." key
    }

    while true; do
        Clear_Screen
        echo "$(tput setaf 6)88888888888888888888888888888888888888888888888888888$(tput sgr 0)___$(tput setaf 6)8888888888888888888$(tput sgr 0)"
        echo "$(tput setaf 6)888888888888888888888888888888888888888888888$(tput sgr 0)___..--'  .\`.$(tput setaf 6)88888888888888888$(tput sgr 0)"
        echo "$(tput setaf 6)888888888888888888888888888888888888$(tput sgr 0)___...--'     -  .\` \`. \`.$(tput setaf 6)88888888888888$(tput sgr 0)"
        echo "$(tput setaf 6)888888888888888888888888888$(tput sgr 0)___...--' _      -  _   .\` -   \`. \`.$(tput setaf 6)888888888888$(tput sgr 0)"
        echo "$(tput setaf 6)888888888888888888$(tput sgr 0)___...--'  -       _   -       .\`   \`. - _ \`. \`.$(tput setaf 6)888888888$(tput sgr 0)"
        echo "$(tput setaf 6)88888888888$(tput sgr 0)__..--'_______________ -         _  .\`  _    \`.   - \`. \`.$(tput setaf 6)8888888$(tput sgr 0)"
        echo "$(tput setaf 6)88888888$(tput sgr 0).\`    _ /\    -        .\`      _     .\`____________\`. _ -\`. \`.$(tput setaf 6)88888$(tput sgr 0)"
        echo "$(tput setaf 6)888888$(tput sgr 0).\` -   _ /  \_     -   .\`  _         .\` |Domain Depot| \`.  - \`. \`.$(tput setaf 6)888$(tput sgr 0)"
        echo "$(tput setaf 6)8888$(tput sgr 0).\`-    _  /   /\   -   .\`        _   .\`   |____________|  \`. _   \`. \`.$(tput setaf 6)8$(tput sgr 0)"
        echo "$(tput setaf 6)88$(tput sgr 0).\`________ /__ /_ \____.\`____________.\`     $(tput setaf 3)___$(tput sgr 0)       $(tput setaf 3)___$(tput sgr 0)  -  \`._____ \`|$(tput setaf 6)8$(tput sgr 0)"
        echo "$(tput setaf 6)8888$(tput setaf 3)|$(tput sgr 0)   -  $(tput setaf 3)__$(tput sgr 0)  -$(tput setaf 3)|$(tput sgr 0)    $(tput setaf 3)|$(tput sgr 0) - $(tput setaf 3)|$(tput sgr 0)  $(tput setaf 3)____$(tput sgr 0)  $(tput setaf 3)|$(tput sgr 0)   $(tput setaf 3)|$(tput sgr 0) $(tput setaf 3)|$(tput sgr 0) _  $(tput setaf 3)|$(tput sgr 0)   $(tput setaf 3)|$(tput sgr 0)  _  $(tput setaf 3)|$(tput sgr 0)   $(tput setaf 3)|$(tput sgr 0)  _ $(tput setaf 3)|$(tput sgr 0)$(tput setaf 6)8888888888$(tput sgr 0)"
        echo "$(tput setaf 6)8888$(tput setaf 3)|$(tput sgr 0) _   $(tput setaf 3)|$(tput sgr 0)  $(tput setaf 3)|$(tput sgr 0)  | -  |   | |.--.| |___| |    |___|     |___|    $(tput setaf 3)|$(tput sgr 0)$(tput setaf 6)8888888888$(tput sgr 0)"
        echo "$(tput setaf 6)8888$(tput setaf 3)|$(tput sgr 0)     $(tput setaf 3)|$(tput sgr 0)--$(tput setaf 3)|$(tput sgr 0)  |    | _ | |'--'| |---| |   _|---|     |---|_   $(tput setaf 3)|$(tput sgr 0)$(tput setaf 6)8888888888$(tput sgr 0)"
        echo "$(tput setaf 6)8888$(tput sgr 0)$(tput setaf 3)|$(tput sgr 0)   - |__| _|  - |   | |.--.| |   | |    |   |_  _ |   |    $(tput setaf 3)|$(tput sgr 0)$(tput setaf 6)8888888888$(tput sgr 0)"
        echo " ---\`\`--._      $(tput setaf 3)|$(tput sgr 0)    |   |=|'--'|=|___|=|====|___|=====|___|====$(tput setaf 3)|$(tput sgr 0)$(tput setaf 6)8888888888$(tput sgr 0)"
        echo " -- . ''  \`\`--._| _  |  -|_|.--.$(tput setaf 3)|_______|_______________________|$(tput sgr 0)**********"
        echo "\`\`--._          '--- |_  |:|'--'$(tput setaf 3)|$(tput sgr 0)$(tput setaf 1):::::::$(tput sgr 0)$(tput setaf 3)|$(tput sgr 0)$(tput setaf 1):::::::::::::::::::::::$(tput sgr 0)$(tput setaf 3)|$(tput sgr 0)"
        echo "_____ \`\`--._ ''      . '---'``--._$(tput setaf 3)|$(tput sgr 0)$(tput setaf 1):::::::$(tput sgr 0)$(tput setaf 3)|$(tput sgr 0)$(tput setaf 1):::::::::::::::::::::::$(tput sgr 0)$(tput setaf 3)|$(tput sgr 0)"
        echo "----------\`\`--._         ''      \`\`--.._$(tput setaf 3)|$(tput sgr 0)$(tput setaf 1):::::::::::::::::::::::$(tput sgr 0)$(tput setaf 3)|$(tput sgr 0)"
        echo "\`\`--._ _________\`\`--._'      --     .   ''-----$(tput setaf 1)..............$(tput sgr 0)69'**********"
        echo "$(tput setaf 3)---------------------------------$(tput sgr 0)"
        echo "$(tput setaf 1)1$(tput sgr 0) - Get $(tput setaf 6)DOMAIN ICANN$(tput sgr 0)"
        echo "$(tput setaf 1)2$(tput sgr 0) - Other"
        echo "$(tput setaf 1)e$(tput sgr 0) - exit"
        echo "$(tput setaf 3)---------------------------------$(tput sgr 0)"
        echo -n "Enter your choice: "
        read -r choice

        case $choice in
            "1")
                while true; do
                    Clear_Screen
                    echo "$(tput setaf 3)----------------------------------$(tput sgr 0)"
                    echo "$(tput setaf 1)1$(tput sgr 0) - Add $(tput setaf 6)Domain Records$(tput sgr 0)"
                    echo "$(tput setaf 1)2$(tput sgr 0) - View $(tput setaf 6)Domain Records$(tput sgr 0)"
                    echo "$(tput setaf 1)3$(tput sgr 0) - Get $(tput setaf 6)NameServer IP$(tput sgr 0)"
                    echo "$(tput setaf 1)4$(tput sgr 0) - Delete $(tput setaf 6)Domain Records$(tput sgr 0)"
                    echo "$(tput setaf 1)5$(tput sgr 0) - Find $(tput setaf 6)Subdomains$(tput sgr 0)"
                    echo "$(tput setaf 1)back$(tput sgr 0) - go back to $(tput setaf 6)main menu$(tput sgr 0)"
                    echo "$(tput setaf 3)----------------------------------$(tput sgr 0)"
                    echo -n "Enter your choice: "
                    read -r sub_choice

                    case $sub_choice in
                        "1")
                            Clear_Screen
                            addRecord
                            Pause
                            ;;
                        "2")
                            Clear_Screen
                            viewAllRecords
                            Pause
                            ;;
                        "3")
                            Clear_Screen
                            Dig_Nameserver
                            Pause
                            ;;
                        "4")
                            Clear_Screen
                            DeleteRecord
                            Pause
                            ;;
                        "5")
                            Clear_Screen
                            FindSubdomains
                            Pause
                            ;;
                        "back")
                            break
                            ;;
                        [eE])
                            Clear_Screen
                            exit
                            ;;
                        *)
                            Clear_Screen
                            echo "Invalid choice"
                            Pause
                            ;;
                    esac
                done
                ;;
            "2")
                Clear_Screen
                echo "Choice 2"
                Pause
                ;;
            [eE])
                Clear_Screen
                exit
                ;;
            *)
                Clear_Screen
                echo "Invalid choice"
                Pause
                ;;
        esac
    done
}

while true; do
    Clear_Screen
    Main
done
