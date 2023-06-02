#!/bin/bash
#
# Usage: ./vmotion.sh vcsa user fqdn 'vm1 vm2' 'ds1 ds2'

vms=($4)
datastores=($5)
host="$1"
user="$2"
esxi="$3"

echo Enter password for $user: && read -s pass

git clone https://github.com/vmware/pyvmomi-community-samples.git
cd pyvmomi-community-samples/samples

source ~/.virtualenvs/vmotion/bin/activate || python3 -m venv ~/.virtualenvs/vmotion && \
                                              source ~/.virtualenvs/vmotion/bin/activate

pip install -r ../../requirements.txt

i=0
for vm in ${vms[@]}; do
  python3 relocate_vm.py -s "$host" -u $user -p $pass -v $vm \
                         --datastore-name ${datastores[$(expr $i % ${#datastores[@]})]} -e $esxi &
  ((i+=1))
done
exit 0
