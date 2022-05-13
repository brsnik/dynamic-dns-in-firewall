# Dynamic DNS in Firewall

Automatically set traffic rules from a Dynamic DNS Domain with Dynamic IP Addresses

> Currently only works with `UFW`, but could be easily adapted to `IPTABLES`. Feel free to contribute!

## How it works

Allows traffic from IPv4 and optionally IPv6 addesses for a given domain. 

```
$ ufw status
22                        ALLOW IN    1111:1:1::1          # SSH from Dynamic IP (one.dynamic.dns.domain.tld)
22                        ALLOW IN    2.2.2.2              # SSH from Dynamic IP (two.dynamic.dns.domain.tld)
22                        ALLOW IN    2222:2:2::2          # SSH from Dynamic IP (two.dynamic.dns.domain.tld)
```

Multiple addresses supported per domain!

As well as multiple domains supported! Add as many Dynamic DNS domains as you want!

Firewall rules for addresses no longer in the DNS records are removed.

## Required packages
- ufw
- dig
- grep
- awk

## "Install"/Schedule Cron 

1. Download the latest release
2. Copy to your desired location—for this example we will use `/var/cron`
3. Run it to make sure it works without any errors `bash /var/cron/dynamic-dns-in-ufw.sh`
4. Then enter crontab `$ sudo vim /etc/crontab`
5. To the end of the line add one of the following:
  - To run every hour add `0  *  *  *  *   root    /var/cron/dynamic-dns-in-ufw.sh`
  - Or for every half hour add `*/30  *  *  *  *   root    /var/cron/dynamic-dns-in-ufw.sh`
6. Save and exit vim `:wq`
  --------
## Notes

- When you remove a domain you no longer need, the script will not remove the rules from your firewall. They need to be manually removed.
- Slack notifications upon error will be added soon!


