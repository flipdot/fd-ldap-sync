#!/bin/bash
set -e

service slapd start

cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: cn=config
changetype: modify
add: olcServerID
olcServerID: 2
EOF


cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: {1}syncprov.la
EOF



cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcRootPW
olcRootPW: $LDAP_PASSWORD
EOF



cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: cn=config
changetype: modify
replace: olcServerID
olcServerID: 1 ldaps://$LDAP1_NAME/
olcServerID: 2 ldaps://$LDAP2_NAME/
EOF



cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: olcOverlay=syncprov,olcDatabase={0}config,cn=config
changetype: add
objectClass: olcOverlayConfig
objectClass: olcSyncProvConfig
olcOverlay: syncprov
EOF



cat <<EOF | ldapmodify -Y EXTERNAL -H ldapi:///
dn: olcDatabase={0}config,cn=config
changetype: modify
add: olcSyncRepl
olcSyncRepl: rid=001 provider=ldaps://$LDAP1_NAME/ binddn="cn=config" 
  bindmethod=simple credentials=$LDAP_PASSWORD 
  searchbase="cn=config" type=refreshAndPersist
  retry="5 5 300 5" timeout=1
olcSyncRepl: rid=002 provider=ldaps://$LDAP2_NAME/ binddn="cn=config" 
  bindmethod=simple credentials=$LDAP_PASSWORD 
  searchbase="cn=config" type=refreshAndPersist
  retry="5 5 300 5" timeout=1
-
add: olcMirrorMode
olcMirrorMode: FALSE
EOF

service slapd stop
killall -9 slapd

sleep 3