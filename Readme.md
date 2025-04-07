# Portainer install Always Restart

06 mars 2025

yannick SUDRIE

Vous trouverez plusieurs version de scripts permetant d'installer le gestionnaire de container Portainer version communeauty sur differentes distribution avec redémarrage automatique en cas de reboot. 



## Distribution UBUNTU + DOCKER

### installPortainerRestartAlways_DU.sh
Le script [installPortainerRestartAlways_DU.sh](installPortainerRestartAlways_DU.sh) très simple extrait de [portnair.io](https://portainer.io/install.html) pour installer Portnair pour Docker avec redémarrage automatique de Portnair sur distribution Ubuntu.

Note du 02/03/2025 :

+ Je vous conseille de ne plus l'utiliser à moins que votre distribution ne gére pas les cgroups.
+ Update vers Portainer Community Edition 2.27.1

### installPortainerRestartAlwaysLimit_DU.sh
Le script [installPortainerRestartAlwaysLimit_DU.sh](installPortainerRestartAlwaysLimit_DU.sh) a le Même objectif que le script précedent mais cette version permet de limiter l'empreinte mémoire et CPU dans une envelope de ressource prédéfinie et contrainte ... par défaut à 20 % d'un CPU, 10 Mo de RAM et 90 Mo de swap. Veuillez vérifier les commentaires dans le script avant de l'utiliser ou de modifier les valeurs.

Note du 10 Mars 2022 :

+ Update vers Portainer Community Edition 2.11.1

+ add a nota about error 'Your kernel does not support swap limit capabilities or the cgroup is not mounted. Memory limited without swap.'
They said :'if docker swap option is disable in cgroup you take the risk that the container was drop by docker if there is not enought ram in the container'
take a look at https://stackoverflow.com/questions/48685667/what-does-docker-mean-when-it-says-memory-limited-without-swap"

Note du 03 Mars 2025 :

+ Update vers Portainer Community Edition 2.27.1

-----


# Distribution ALPINE + PODMAN* en mode ROOTLESS

**Note 06/03/2025 : Attention Ce script est partiellement fonctionnel il reste des points à peaufiner, éclaircir et confirmer ...**


Le script [installPortainerRestartAlwaysLimit_PA01.sh](installPortainerRestartAlwaysLimit_PA01.sh) même objectif que le script précedent mais dans un environement rootless cette version permet de limiter l'empreinte mémoire et CPU dans une envelope de ressource prédéfinie et contrainte ... par défaut à 20 % d'un CPU, 150 Mo de RAM et 200 Mo de swap. Veuillez vérifier les commentaires dans le script avant de l'utiliser ou de modifier les valeurs.

*Podman est l'équivalent de Docker en version libre et opensource.  

Activer le mode Debug de podman : ```podman info --log-level=debug```

Point #1 (A confirmer) : Si on exécute le script d'installation de Portainer il semble que si on ne se connecte pas dans un délais rapide (envion 5 minutes) au container Portainer pour fixer au minimum le login / password d'administration alors le container s'arrête et ne redemarera pas au prochain reboot. Ce comportement qui va à l'encontre de la directive ```---restart=always``` semble implanté au sein du container  ```podman logs Portainer``` pour des raison de sécurité ```2025/03/01 03:46AM INF github.com/portainer/portainer/api/adminmonitor/admin_monitor.go:62 > the Portainer instance timed out for security purposes, to re-enable your Portainer instance, you will need to restart Portainer``` 

Log de Portainer à sa création : 
```
2025/03/01 03:41AM // note perso création du containeur viale script !
2025/03/01 03:41AM INF github.com/portainer/portainer/api/cmd/portainer/main.go:310 > encryption key file not present | filename=portainer
2025/03/01 03:41AM INF github.com/portainer/portainer/api/cmd/portainer/main.go:334 > proceeding without encryption key |
2025/03/01 03:41AM INF github.com/portainer/portainer/api/database/boltdb/db.go:133 > loading PortainerDB | filename=portainer.db
2025/03/01 03:41AM INF github.com/portainer/portainer/api/internal/ssl/ssl.go:79 > no cert files found, generating self signed SSL certificates |
2025/03/01 03:41AM INF github.com/portainer/portainer/api/chisel/service.go:228 > generated a new Chisel private key file | private-key=/data/chisel/private-key.pem
2025/03/01 03:41:47 server: Reverse tunnelling enabled
2025/03/01 03:41:47 server: Fingerprint E5POg1bdHl7dXj17Ahb31zuNTsbJM9NscbCB9kITRb4=
2025/03/01 03:41:47 server: Listening on http://0.0.0.0:8000
2025/03/01 03:41AM INF github.com/portainer/portainer/api/cmd/portainer/main.go:601 > starting Portainer | build_number=164 go_version=1.23.5 image_tag=2.27.1-linux-amd64 nodejs_version=18.20.7 version=2.27.1 webpack_version=5.88.2 yarn_version=1.22.22
2025/03/01 03:41AM INF github.com/portainer/portainer/api/http/server.go:363 > starting HTTPS server | bind_address=:9443
2025/03/01 03:41AM INF github.com/portainer/portainer/api/http/server.go:347 > starting HTTP server | bind_address=:9000
2025/03/01 03:46AM INF github.com/portainer/portainer/api/adminmonitor/admin_monitor.go:62 > the Portainer instance timed out for security purposes, to re-enable your Portainer instance, you will need to restart Portainer
```
Pour configurer Portainer un ```podman restart Portainer``` permet d'accédere à son interface web ```http://XX.XX.XX.XX:9000```

Point #2 (A éclaircir) : Si je me référe aux informations de [Daniel Schier sur Podman - Portainer en mode ROTTFULL & ROOTLESS](https://blog.while-true-do.io/podman-portainer/)
Je pense avoir un pb sur mon script sur Alpine qui pointe vers /run/podman/podman.sock qui est la proprieté de root à la place d'un sock qui à juste les droits de base de l'utilisateur donc sur un truc du style /run/user/$UID/podman/podman.sock -> pb dans mon script d'install ROOTLESS ??? 
 
Socket Rootful vs Rootless

Rootful : Le socket /run/podman/podman.sock appartient à root. Cela signifie qu'il est utilisé pour les opérations Podman en mode rootful, où Podman est exécuté avec des privilèges root.
Rootless : En mode rootless, Podman devrait utiliser un socket spécifique à l'utilisateur, généralement situé dans un répertoire comme /run/user/$UID/podman/podman.sock. Cela permet à chaque utilisateur d'avoir son propre socket Podman, isolé des autres utilisateurs.

Permissions et Propriétaire :

Permissions : Le socket /run/podman/podman.sock appartient à root et a des permissions restrictives (srw-------), ce qui signifie que seul l'utilisateur root peut y accéder. Cela ne convient pas pour une utilisation rootless, où l'utilisateur non-root doit pouvoir interagir avec le socket.
Utilisateur Rootless : En mode rootless, le socket doit être accessible par l'utilisateur non-root qui exécute Podman. Cela implique que le socket doit être situé dans un répertoire appartenant à cet utilisateur et avoir les permissions appropriées.

Configuration Rootless

Création du Socket Rootless : Pour utiliser Podman en mode rootless, on doit s'assurer que le socket est créé dans le répertoire utilisateur approprié. Cela peut nécessiter de configurer le service utilisateur pour Podman. (probalement ici mon PB !!) 
Vérification : Vérifier si le socket rootless est correctement configuré en exécutant des commandes Podman en tant qu'utilisateur non-root et en vérifiant l'emplacement du socket.

```podman info | grep -A2 -B2 -i sock```

```remoteSocket:
    exists: true
    path: /tmp/storage-run-1000/podman/podman.sock
  rootlessNetworkCmd: pasta
  security:
```

Conclusion
En mode rootless, Podman devrait utiliser un socket spécifique à l'utilisateur, et non un socket appartenant à root ```podman/podman.sock```. Le fait de ne pas trouver le socket /run/podman/podman.sock appartenant à root indiquerait que Podman n'est pas configuré pour fonctionner en mode rootless pour l'utilisateur ... sauf que selon ```podman info | grep -A2 -B2 -i rootless``` : 

    ```exists: true
    path: /tmp/storage-run-1000/podman/podman.sock
  rootlessNetworkCmd: pasta
  security:
    apparmorEnabled: false
    capabilities: CAP_CHOWN,CAP_DAC_OVERRIDE,CAP_FOWNER,CAP_FSETID,CAP_KILL,CAP_NET_BIND_SERVICE,CAP_SETFCAP,CAP_SETGID,CAP_SETPCAP,CAP_SETUID,CAP_SYS_CHROOT
    rootless: true
    seccompEnabled: true
    seccompProfilePath: /etc/containers/seccomp.json```

Le mode rootless à la valeur true ```rootless: true``` !!!!

### installPortainerRestartAlwaysLimit_PA.sh
Le script [installPortainerRestartAlwaysLimit_PA.sh](installPortainerRestartAlwaysLimit_PA.sh) automatise l'installation de Portainer avec Podman en mode rootless sur une distribution Alpine Linux et configure Portainer pour qu'il redémarre automatiquement au démarrage tout en limitant les ressources CPU, mémoire, swap ...  du container Portainer. 

_Note : Si vous utilisez des conteneurs qui consomment beaucoup de ressources hôte exemple un modéle IA ... vous devriez envisager de limiter sa capacité à phagociter les ressources de votre hôte ...
_
## Prérequis

- Alpine Linux v3.21.
- [Podman sur votre Alpine en mode ROOTLESS](https://github.com/sudtek/mesScriptsBash/tree/136ecd972dfbcb708babcf512d78de23b82efea8/podmanInstallPourAlpine).
- Accès utilisateur avec les droits minimum nécessaires pour pouvoir exécuter la commande podman.

## Instructions d'Utilisation

### 1. Vérification des Prérequis

Avant d'exécuter le script, assurez-vous que Podman est installé et configuré en mode rootless. Vous pouvez vérifier cela en exécutant :

```sh podman info```

Assurez-vous que le socket Podman est accessible :

```ls -l /run/podman/podman.sock```

### 2. Exécution du Script

Téléchargez le script et exécutez-le dans votre terminal. ATTENTION Ne pas exécuter ce script avec sudo ou doas, car cela empêcherait Portainer de fonctionner en mode rootless.

```./install_portainer.sh```

### 3. Vérifications Avant Installation
Le script effectue les vérifications suivantes avant d'installer Portainer :

Port 9000 : Vérifie si le port 9000 est disponible. Si le port est utilisé, le script affiche un message d'avertissement.

Conteneur Portainer : Vérifie si un conteneur nommé "Portainer" est en cours d'exécution. Si c'est le cas, le script l'arrête et le supprime.

### 4. Installation de Portainer

Le script configure et lance un conteneur Portainer avec les paramètres suivants :

Nom du Conteneur : Portainer
Ports : 9000:9000
Volume : portainer_data
Limites de Ressources :
Mémoire : 150 Mo # La version V2.27.1 est plus gourmande que la 2.11.1
Swap : 200 Mo
CPU : 0.2

### 5. Vérification de l'Installation
Pour vérifier que Portainer est correctement installé et que les limites de ressources sont appliquées, utilisez la commande suivante :

```podman stats```

**Notes Importantes**
Mode Rootless : Ce script doit être exécuté sans sudo ou doas pour que Portainer s'execute dans un Podman avec des droits de bases.
Erreurs de Swap : Si vous rencontrez l'erreur "Your kernel does not support swap limit capabilities or the cgroup is not mounted," consultez la documentation de Podman et vérifiez les options de cgroup disponibles sur votre système via ```podman info```.
Volume de Données : Le script supprime et recrée le volume de données portainer_data. Assurez-vous de ne pas avoir de données importantes dans ce volume avant d'exécuter le script.

## Conclusion
Ce script facilite l'installation de Portainer avec Podman en mode rootless sur Alpine Linux. En suivant ces instructions, vous pouvez gérer vos conteneurs via l'interface web de Portainer exactement comme sous docker.

---------

# ATTENTION AVEC LE MODE ROOTLESS

Le mode ROOTLESS présente une subtilité importante : Par habitude en venant d'ubuntu il est facile de se pieger tout seul et d'exécuter le script ou l'install manuel d'un nouveau container via doas ou sudo ... (je me suis fait avoir plusieurs fois donc j'ai ajouté un garde-fou en debut du script). via sudo /doas un container ne s'exécutera pas sous l'utilisateur base mais sous l'utilisateur root. Par conséquent, votre utilisateur base ne pourra plus voir le conteneur en cours d'exécution. Si vous relancez l'installation du conteneur via le script, vous risquez de rencontrer des erreurs plus ou moins explicites et biensur vous ne pourrez plus par manque de droit écraser le conteneur précédent qui occupera toujours le port local 9000. Si vous pensez être confronté à cette situation, effectuez les vérifications suivantes pour clarifier la situation :

Via l'**utilisateur base donc sans sudo ni doas (et encore moins en root...) **vérifier la disponiblité du port local 9000 !

Si la commande ```netstat -lap```confirme que le port 9000 existe sans PID -

```
Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:9000            0.0.0.0:*               LISTEN      -
```

Faites une vérification via la commande ```podman stats -a``` plus de container nommé 'Portainer' en éxécution :

```
ID          NAME        CPU %       MEM USAGE / LIMIT  MEM %       NET IO      BLOCK IO    PIDS        CPU TIME    AVG CPU
```

Si la commande 'stats -a' confirme qu'il n'y a aucun conteneur nommé **Portainer** et aucun PIDS commun avec le port local 9000 visible et juste un **-**  alors depuis votre user refaites les mêmes manip mais avec doas ou sudo (en fonction de ce que vous avez implémentez sur votre ALpine) !

```
doas netstat -lap

Proto Recv-Q Send-Q Local Address           Foreign Address         State       PID/Program name
tcp        0      0 0.0.0.0:9000            0.0.0.0:*               LISTEN      6579/pasta
```
et 
```
doas podman stats -a

ID            NAME        CPU %       MEM USAGE / LIMIT  MEM %       NET IO        BLOCK IO           PIDS        CPU TIME      AVG CPU %
b29bc65098c0  Portainer   0.29%       111.3MB / 4.082GB  2.73%       0B / 4.086kB  61.99MB / 2.646MB  58          4m39.892525s  0.18%
```

Si vous voyez cela c'est que vous avez merdé et lancé votre prècédente installation de Portainer en invoquant doas ou sudo !!!

Vous devez impérativement tout nettoyer manuellement* en faisant doas ou sudo puisque votre Portainer a été lancé avec des droits plus élevès que l'utilisateur de base qui avait juste le droit de jouer avec Podman :

- 1) Arréter le container Portainer.
- 2) Supprimer le container Portainer.
- 3) Supprimer le volume Portainer_DATA et faire le ménage via doas ou sudo.
- 4) relancer le script en utilisateur normal de base.

---

* Vu que j'ai pas fait de script de netoyage mais bon comme je suis pas chien je vous mâche le boulot :

```
# ----------------------------------------------------------------------------------------------------------------------------------------
# On verifie s'il existe un container VISIBLE entrain de tourner avec un processus et on essaye de le stoper proprement !
CONTAINER_RUN=$(podman ps | grep -i "$CONTAINER_NAME\b")
#
if [ -n "$CONTAINER_RUN" ]; then
    echo -e "\nATTENTION : Le container : $CONTAINER_RUN est actuellement lancé !"
    echo -e "\n $CONTAINER_RUN"
    # On arrete le conteneur
    $(podman stop ${CONTAINER_NAME})
else
   echo -e "\nOK : Le container $CONTAINER_NAME ne semble pas être lancé."
fi

# On verifie si le port local exemple 9000 est déja utilisé
PORT_IN_USE=$(netstat -tuln | grep ":$CONTAINER_OUTSIDE_PORT\b")
#
if [ -n "$PORT_IN_USE" ]; then
    echo -e "\nATTENTION : Le port $CONTAINER_OUTSIDE_PORT est actuellement connecté !"
    echo -e "\n $PORT_IN_USE"
else
    echo -e "\nOK : Le port $CONTAINER_OUTSIDE_PORT est libre."
fi


# On affiche tous les containers pour chercher portainer et le supprimer
CONTAINER_EXIST=$(podman ps -all | grep -i "$CONTAINER_NAME\b")
#
if [ -n "$CONTAINER_EXIST" ]; then
    echo -e "\nATTENTION : Le container $CONTAINER_NAME existe et va être définitivement supprimé !"
    echo -e "\n $CONTAINER_EXIST"
    # On efface le conteneur
    $(podman rm -f ${CONTAINER_NAME})
else
    echo -e "\nAucun container nommé '$CONTAINER_NAME' à supprimer."
fi
# ----------------------------------------------------------------------------------------------------------------------------------------
```

