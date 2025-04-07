#!/bin/sh

# 06_mars_2025
# yannick Sudrie
# V_0.2
#
# BUT : Installer un container Portainer dans podman sur la distribution Alpine en ROOTLESS.
# 
#       Tested on:
#       Alpine Linux v3.21
#       podman version 5.3.2
#       OS/Arch: linux/amd64
#
#       Information utile sur Podman en rootless à cette adresse https://blog.while-true-do.io/podman-portainer/
#       commande '$(podman info)' '$(podman info --log-level=debug)'
#
# ATTENTION : Ce scrip ne doit pas être lancé ni en ROOT ni en invoquant sudo ou doas !!! Sinon le conteneur Portainer ne sera ni visible ni managé en ROOTLESS.
#             En mode ROOTLESS les conteneurs, overlays, volume ... sont dans le repertoire '/tmp/storage-run-1000/containers' il a cette arborescence :
# .
# ├── networks
# │   └── rootless-netns
# ├── overlay
# │   ├── idmapped-lower-dir-false
# │   ├── metacopy()-false
# │   ├── native-diff()-true
# │   ├── overlay-true
# │   └── volatile-true
# ├── overlay-containers
# │   └── b29bc65098c082f63746942d5a5a163f11cc395508871c9af46cdf85d7eb0f25
# │       └── userdata
# ├── overlay-layers
# │   └── mountpoints.lock
# └── overlay-locks
#
#

# Si votre connexion internet est trés lentes et genere des time out lors du pull de container décommenter cette section :
# -------------------------------------------------------
# Délai de connexion TCP (en secondes)
#export CONTAINERS_CONNECTION_TIMEOUT="60"

# Délai global de téléchargement des layers (en secondes)
#export CONTAINERS_DOWNLOAD_TIMEOUT="1800"  # 30 minutes

# Délai entre les tentatives de retry (en secondes)
#export CONTAINERS_RETRY_TIMEOUT="10"

# Nombre de tentatives de retry
#export CONTAINERS_RETRY="5"
# ------------------------------------------------------

clear

# Vérifie avant tout si le script est exécuté en tant que root
if [ "$(id -u)" -eq 0 ]; then
    echo "ATTENTION !!!! Ce script ne doit pas être exécuté avec sudo ou doas ou en root. Veuillez l'exécuter avec les droits utilisateur basique  qui peut invoquer podman !!!!"
    exit 1
fi

clear 

# 03 mars 2025 bloc à concerver le temps de faire des tests et verifications :
# Tests to ensure your user has the rights to access the socket /run/podman/podman.sock in rootless mode
#	PODMAN_SOCK_PERMISION=$(ls -l /run/podman/podman.sock) # Check permissions if root, use doas!
#	PODMAN_SOCK_REMOTE=$(podman info --format '{{.Host.RemoteSocket.Path}}')
#
#	if ! PODMAN_SOCK_REMOTE=$(podman info --format '{{.Host.RemoteSocket.Path}}'); then
#    		echo -e "\nErreur : impossible de récupérer le socket Podman."
#    	exit 1
#	fi
# 05 mars 2025 NON /tmp/storage-run-1000/podman/podman.sock n'existe pas !! c'est ailleur !!!


# Chemin vers le socket rootless de podman
#
PODMAN_SOCK_ROOTLESS="/run/podman/podman.sock"
# 05 mars 2025 : OK fonctionne mais ne semble ni être le chemin recommandé ni le bon sock en rootless https://blog.while-true-do.io/podman-portainer/ 
# car on pointe vers un podman.socks avec des droits root : $(ls -al /run/podman/podman.sock)
# srw-------    1 root     root             0 Mar  3 02:41 /run/podman/podman.sock
#
# VS vers un socket avec des droits de l'utilisateur courant de base style : "/run/$(user)/$(id -u)/podman/podman.sock"  mais qui existe pas sur alpine !!!!


# On teste si le path et le sock vers podman sont valides :
if [ ! -S "$PODMAN_SOCK_ROOTLESS" ]; then
    echo -e "\nErreur : impossible de récupérer le socket Podman, KO !"
    exit 1
else 
    echo -e "\nOK -> Le socket Podman existe : ${PODMAN_SOCK_ROOTLESS}"
fi


# Portainer configuration de base
PORTAINER_REPOSITORY="portainer/portainer-ce"
#PORTAINER_VERSION="2.11.1" # OK mais vielle version
# version au 27/fev/2025
PORTAINER_VERSION="2.27.1"
CONTAINER_NAME="Portainer"
CONTAINER_INSIDE_PORT="9000"
CONTAINER_OUTSIDE_PORT="9000"

CONTAINER_VOLUME_NAME="portainer_data"
# Note : Le point de montage "Mountpoint" est ici : "/home/$user/.local/share/containers/storage/volumes/portainer_data/_data" alias "~/.local/share/containers/storage/volumes"

# Limiter / contraindre les ressources hote 
# Take a look at 'doas podman update --help' for more options (limit IO could be useful on SD cards)
# Au besoin voir doc docker idem que podman  https://docs.docker.com/config/containers/resource_constraints/
# Note : 'podman info' vous informera de toutes les possibilitées cgroup V2 de votre bécane exemple :
# $podman info
# host:
#  ...
#  cgroupControllers:
#  - cpuset
#  - cpu
#  - io
#  - memory
#  - hugetlb
#  - pids
#  cgroupManager: cgroupfs
#  cgroupVersion: v2
#  ...
#
# Note : Extrait de la documentation de arch  https://wiki.archlinux.org/title/Cgroups pour groupes c pour sytemd et pas pour openrc !!!
#
# 2.7.1 En tant qu'utilisateur non privilégié :
#       Les utilisateurs non privilégiés peuvent diviser les ressources qui leur sont fournies en nouveaux groupes, si certaines conditions sont remplies :
#       Cgroups v2 doit être utilisé pour qu'un utilisateur non root soit autorisé à gérer les ressources du groupe de contrôle.
#       Les utilsateurs sans priviléges peuvent diviser les ressources presentes dasn un nouveau cgroups, si certaines conditions sont satisfaites.
# 2.7.2 Types de contrôleurs:
#       Toutes les ressources ne peuvent pas être contrôlées par l'utilisateur





# Memory limit
MEMORY_LIMIT="150m"
SWAP_LIMIT="200m"
#
# CPU limit
CPU_LIMIT=".2"

# Ecrasement du volume data Portainer si une version precedente existe !
if podman volume exists $CONTAINER_VOLUME_NAME; then
 echo "ATTENTION Volume $CONTAINER_VOLUME_NAME existe déjà on l'efface !"
 # <A_FAIRE> : Ajouter une demande de confirmation explicite à l'utilisateur avant destruction ( caractéres de confirmation  Y y O o)  avant de continuer le script sinon exit ! </A_FAIRE>
 podman volume rm $CONTAINER_VOLUME_NAME
fi
#
# Création d'un nouveau volume data pour portainer
podman volume create $CONTAINER_VOLUME_NAME
echo "Volume ${CONTAINER_VOLUME_NAME} créé !"

# Installation de Portainer en mode resident permanent redemarage automatique au reboot.
# Note du 28 fev 2025 l'option '--replace' semble poser pb et/ou ne pas faire son taf en libérant le port local et écrasant le conteneur 'Portainer' précedement créé !
# Note du 01 mars 2025 non en fait c'est un pb de lancement de script en doas VS ROOTLESS ...

podman run -d --replace --name=${CONTAINER_NAME} --restart=always -p ${CONTAINER_INSIDE_PORT}:${CONTAINER_OUTSIDE_PORT} -v ${PODMAN_SOCK_ROOTLESS}:/var/run/docker.sock -v ${CONTAINER_VOLUME_NAME}:/data ${PORTAINER_REPOSITORY}:${PORTAINER_VERSION}
#DEBUG echo "podman run -d --replace --name=${CONTAINER_NAME} --restart=always -p ${CONTAINER_INSIDE_PORT}:${CONTAINER_OUTSIDE_PORT} -v ${PODMAN_SOCK_ROOTLESS}:/var/run/docker.sock -v ${CONTAINER_VOLUME_NAME}:/data ${PORTAINER_REPOSITORY}:${PORTAINER_VERSION}"


# Apply memory and CPU limits (cgroups)
podman update $CONTAINER_NAME --memory $MEMORY_LIMIT --memory-swap $SWAP_LIMIT
podman update $CONTAINER_NAME --cpus $CPU_LIMIT


echo "Pour accéder à l'interface Portainer, utilisez votre navigateur web : http://@ipportainer:$CONTAINER_OUTSIDE_PORT"
echo "Lors de la configuration de Portainer, choisissez l'option 'localport' pour le point de terminaison !"
echo "Pour vérifier si les limitations sont correctement appliquées à votre conteneur $CONTAINER_NAME, utilisez la commande :"
echo "podman stats"
echo "------------------------------------------------------------------------------------------------------"
echo "NOTE : Si vous obtenez l'erreur :"
echo "'Votre noyau ne supporte pas les capacités de limitation de swap ou le cgroup n'est pas monté. Mémoire limitée sans swap.'"
echo "'Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.'"
echo "utilisez la commande 'podman info' pour en savoir plus sur vos options/possibilités de cgroups !"
echo "Consultez https://stackoverflow.com/questions/48685667/what-does-docker-mean-when-it-says-memory-limited-without-swap"
echo "Si l'option de swap de podman est désactivée dans le cgroup, vous risquez que le conteneur soit arrêté par podman s'il n'y a pas assez de RAM dans le conteneur."
