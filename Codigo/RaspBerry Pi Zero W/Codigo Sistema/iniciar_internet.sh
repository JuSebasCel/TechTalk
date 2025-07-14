sudo killall -9 wpa_supplicant
sudo killall dhclient
sudo wpa_supplicant -B -i wlan0 -c /etc/wpa_supplicant/wpa_supplicant.conf -D nl80211,wext
sudo dhclient wlan0