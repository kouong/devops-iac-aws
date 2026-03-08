#!/bin/bash

# Arrêter tous les processus en cours d'exécution qui correspondent à "app.py" dans leur ligne de commande
# Le "|| true" assure que le script n'échoue pas si aucun processus correspondant n'est trouvé
pkill -f app.py || true
