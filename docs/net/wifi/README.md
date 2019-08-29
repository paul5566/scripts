# WiFI

```bash
# ind wireless devices
lspci | egrep -i --color 'wifi|wlan|wireless'
# find the card(s) driver(s)
lspci | egrep -i --color 'wifi|wlan|wireless' \
      | cut -d' ' -f1 \
      | xargs lspci -k -s
# monitor link quality
watch -n 1 cat /proc/net/wireless
```

Bring a Wifi interface up i.e. `wlp3s0`

```bash
>>> dev=wlp3s0                              # interface name
>>> ip link set $dev up                     # bring the interface up
>>> ip link show $dev
#               ...the interface should go ↓↓ ...                                      
3: wlp3s0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc mq state DOWN mode DEFAULT group default qlen 1000
    link/ether 10:bf:48:4c:33:f8 brd ff:ff:ff:ff:ff:ff
```

## NetworkManager

GNOME NetworkManager configures and monitors Wifi network connections [1]:

```bash
nmcli radio wifi on|off                 # toggle Wifi
nmcli dev wifi                          # list available Wifi APs
```

Connect to Wifi using the **NetworkManager applet** [2].

Start the applet on session it within the **i3 Window Manager**:

```bash
# start NetworkManager applet
exec_always --no-startup-id nm-applet
```


### iw

`iw` (replaced `iwconfig`) (no uspport for WPA/WPA2)

```bash
iw list                                 # show wireless device capabilities
iw dev $dev scan | grep -i ssid         # scan for wireless APs
iw dev $dev link                        # link connection status
```

### wpa_supplicant

Connect to an encrypted (WEP, WPA, WPA2) wireless network with [wpa_supplicant][wpa]:

[wpa]: http://w1.fi/wpa_supplicant/

```bash
# default configuration file
/etc/wpa_supplicant/wpa_supplicant.conf
# example config file
/usr/share/doc/wpa_supplicant/wpa_supplicant.conf
# generate config for AP connection (add it to the config file)
wpa_passphrase "$ssid"
```

Simple example configuration

```bash
# AP specific configuration file (evnetually called like the SSID)
>>> file=/etc/wpa_supplicant/wavenet.conf
>>> cat $file
ctrl_interface=/var/run/wpa_supplicant
network={
        ssid="..--WAVENET--.."
        psk=3dc0853c7be5c2d7...........
}
```

Start the WiFi access client in background and get an IP address from DHCP:

```bash
# start in background
>>> wpa_supplicant -B -c $file -i $dev
>>> ip link show $dev
#                                            ... and state should go ↓↓...
3: wlp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP mode ....
    link/ether 10:bf:48:4c:33:f8 brd ff:ff:ff:ff:ff:ff
# query DHCP for an IP-address
>>> dhcpcd $dev
>>> ip link show $dev
3: wlp3s0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 10:bf:48:4c:33:f8 brd ff:ff:ff:ff:ff:ff
#        ↓↓↓↓↓↓↓↓↓↓↓ ... IP address should be visible
    inet 192.168.1.7/24 brd 192.168.1.255 scope global noprefixroute wlp3s0
       valid_lft forever preferred_lft forever
```


### rfkill

The rfkill subsystem registers devices capable of transmitting RF (WiFi, Bluetooth, GPS, FM, NFC)

* **hard blocked** reflects some physical disablement
* **soft blocked** is a software mechanism to enable or disable transmission

```bash
rfkill list                    # current state
rfkill block all               # turn off all RF
rfkill unblock all             # turn on all RF
```

Hard block can not be unblocked by software:

* Check the BIOS for WiFi related settings
* Use the physical switch or a keyboard shortcut (typically using the `Fn` key)
* Multiple keys can exist i.e. one for WiFi and another one for Bluetooth

`rfkill` kernel module configuration (check with `modinfo -p rfkill`)

```bash
>>> cat /etc/modprobe.d/modprobe.conf
options rfkill master_switch_mode=2
options rfkill default_state=1
```

# References

[1] GNOME Network Manager  
https://wiki.gnome.org/Projects/NetworkManager/

[2] NetworkManager Gnome Applet  
https://gitlab.gnome.org/GNOME/network-manager-applet