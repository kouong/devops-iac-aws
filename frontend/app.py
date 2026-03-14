"""
Une simple application Flask pour la démonstration du déploiement AWS.

Cette application fournit une page d'accueil basique qui peut être utilisée pour vérifier
le déploiement réussi sur les instances EC2 via AWS CodeDeploy.
"""

from flask import Flask
app = Flask(__name__)

@app.route("/")
def home():
    """
    Gestionnaire de route d'accueil qui sert la page d'accueil principale de l'application web.

    Cette fonction est un gestionnaire de route Flask qui répond aux requêtes HTTP GET 
    à l'URL racine ("/"). Elle retourne une réponse HTML simple contenant un 
    message de bienvenue et des informations de version, stylisées avec un fond bleu clair.

    Returns:
        str: Une chaîne de caractères HTML contenant un en-tête avec un message de bienvenue, 
             un paragraphe affichant le numéro de version actuel, et le style CSS 
             qui définit la couleur de fond en bleu clair. Le message 
             indique que l'application s'exécute sur EC2 et a été déployée 
             en utilisant AWS CodeDeploy.

    Note:
        Ceci est généralement utilisé comme point de terminaison de vérification d'intégrité ou page d'accueil 
        simple pour vérifier que l'application web s'exécute correctement après 
        le déploiement. La page est stylisée visuellement avec un fond bleu clair.
    """
    return """
    <html>
    <head>
        <style>
            body {
                background-color: green;
                font-family: Arial, sans-serif;
                padding: 20px;
            }
        </style>
    </head>
    <body>
        <h1>Bienvenu au Webinaire de AWS Users Group Congo Brazzaville!</h1>
        <p>Version 1</p>
    </body>
    </html>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)
