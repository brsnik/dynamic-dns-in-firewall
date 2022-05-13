#!/bin/sh

## Declaring an array with URI's of dynamic IP services
## New line each in double quotes
service=(
	"example.dynamic.dns.domain.tld"
)

## The port to be made available
port=22

## The service name which is used in the comments and helps with filtering the rules
## Example: SSH from Dynamic IP
name="SSH"

## If `true` AAAA records will also be fetched from the DNS
## Enabled on by default, if you do not want to check for IPv6 simply set to `false`
ipv6=true

## Declaring an array that will store logs messages
log=()

## When true an error was raised that needs to be reported
error=false

## Gets all the DNS records A and AAAA, then returns them as an array
function get_dns {
	log+=("- Fetching DNS...")

	## Fetches the A records
	a4=($(dig +short +noall +answer +multiline $1 A))

	## Will also fetch the AAAA record when IPv6 is enabled
	a6=()
	if [ "$ipv6" = true ]; then
		a6=($(dig +short +noall +answer +multiline $1 AAAA))
	fi

	dns=("${a4[@]}" "${a6[@]}")

	if [ ! ${#dns[@]} -eq 0 ]; then
		log+=("-- Successfully fetched DNS records!")
	else
		log+=("-- No DNS records fetched!")
		error=true
	fi
}

## Filters the firewall rules and extracts the index and address
function get_existing {
	log+=("- Fetching Firewall rules...")
	existing=()

	while read index ip; do 
		existing[index]=$ip;
	done < <(
		ufw status numbered | 
		grep -e ''"$port"'' |
		grep -i ''"$name"' from Dynamic IP ('"$1"')' | 
		awk '{gsub(/[][]/,""); print $1, $5}'
	)

	if [ ! ${#existing[@]} -eq 0 ]; then
                log+=("-- Successfully fetched existing rules!")
        else
                log+=("-- No rules fetched!")
        fi
}

## Check each service individually
for s in "${service[@]}"
do
	log+=("Processing $s...")
	
	get_dns	$s
	get_existing $s

	## Checking if any records exists for addresses in DNS record
	for a in "${dns[@]}"; do

		log+=("> Checking $a...")
		
		## Create a new rule if nothing was found for the address
		if [[ ! "${existing[*]}" =~ "$a" ]]; then
			
			log+=("-> No rules found! Adding...")
			create=$(ufw allow from $a to any port $port comment ''"$name"' from Dynamic IP ('"$s"')')

			## Make sure it was successfully created, if not log any errors
                	if [[ $create == *"Rule added"* || $c == *"Skipping adding existing rule"* ]]; then
				log+=("--> Successfully added!")
                	else
                        	log+=("--> Failed! Error: $create")
				error=true
                	fi
		else
			log+=("OK")
		fi
        done

	## Checking if addresses of any existing rules are in the DNS record
	for i in "${!existing[@]}"; do

		log+=("> Checking record [$i] -> ${existing[i]}...")
		
		## Delete the record if it's address is no longer in the DNS record
		if [[ ! "${dns[*]}" =~ "${existing[i]}" ]]; then
		
			log+=("-> Not found in DNS record! Deleting...")
			delete=$(ufw --force delete $i)
			
			## Make sure it was successfully deleted, if not log any errors
			if [[ $delete == *"Rule deleted"* ]]; then 
				log+=("--> Successfully deleted!")
			else 
				log+=("--> Failed! Error: $delete")
				error=true
			fi
		else
                        log+=("OK")
		fi
	done
done

## Check if any error have occurred
## Prints the log if there is an error and exits with an error coded
if [ "$error" = true ]; then
	for l in "${log[@]}"; do
		echo $l	
	done
	exit 1
else
	exit 0
fi