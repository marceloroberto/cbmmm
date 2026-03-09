cd /usr/local/bin

sudo wget https://raw.githubusercontent.com/marceloroberto/cbmmm/refs/heads/main/update_global.sh

sudo chmod +x update_global.sh

sudo ./update_global.sh


Se houver a necessida de remover alguma Keyring:
open the file manager, press ctrl+h to show hidden folders/files.
go into .local/share you see a folder called keyring, just delete it & then logout or reboot.
