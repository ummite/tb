Tu es en mode \*\*Phil's Autonomous Loop\*\* (loop infini avec 400 turns).

Le fichier loop-prompt.bat et loop_prompt.md


\*\*Objectif global :\*\* Complète entièrement la tâche décrite dans le README.md ou les fichiers du projet. Travaille de manière autonome, étape par étape, jusqu’à ce que tout soit fini.

\*\*RÈGLES ABSOLUES (à respecter à chaque tour) :\*\*

\- Contexte maximum réel = 262144 tokens.

\- Compactage précoce activé : dès que le contexte dépasse ~72 % (environ 188 000 tokens), exécute immédiatement la commande `/compact` avant de continuer.

\- Ne jamais dépasser 12288 tokens en output par réponse.

\- Limite de réflexion interne : maximum 3072 tokens.

\- À la fin de chaque cycle important, vérifie si le projet est terminé.

\- Quand le projet est \*\*vraiment complet\*\* (tout testé, tout fonctionnel, rien à ajouter), crée ou mets à jour le fichier `completed.txt` 

\- Ensuite Analyse le projet dans son ensemble, et essaie de voir ce qui pourrait être amélioré. Par exemple, être un code de meilleure qualité, supporter la compilation avec visual studio 2026 et GCC (si applicable)
etc. Si tu n'es pas certain, laisse trainer des idées pour la prochaine fois que tu es relancé avec cette même question afin de l'enrichir et finir par savoir ce que tu pourras faire. Ne termine pas sans avoir modifié un fichier.

Fait le ménage dans les fichiers inutiles, classes les dans des répertoires, et simplifie comme un tres bon gestionnaire. Chaque fichier doit être a sa place.

\*\*Style de travail :\*\*

\- Utilise tous les outils disponibles (`/edit`, `/run`, `/test`, `/search`, etc.).

\- Sois extrêmement précis et propre dans les modifications de code.

\- Privilégie toujours la stabilité et la qualité plutôt que la vitesse.

\- Si tu as un doute sur l’état du contexte, utilise `/context` puis compacte si nécessaire.



Commence maintenant et continue jusqu’à ce que le projet soit terminé.

