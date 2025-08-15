document.addEventListener('DOMContentLoaded', function() {
    const arenaMenu = document.getElementById('arenaMenu');
    const closeBtn = document.getElementById('closeBtn');
    const arenaCards = document.querySelectorAll('.arena-card');
    const joinBtns = document.querySelectorAll('.join-btn');

    console.log('PVP Script loaded');

    // Nom de la ressource
    const resourceName = 'pvp_pack';

    // Écouter les messages de FiveM
    window.addEventListener('message', function(event) {
        const data = event.data;
        console.log('Message reçu:', data);
        
        if (data.action === 'openArenaMenu') {
            console.log('Ouverture du menu arène');
            showMenu();
        } else if (data.action === 'closeArenaMenu') {
            console.log('Fermeture du menu arène');
            hideMenu();
        }
    });

    // Afficher le menu
    function showMenu() {
        arenaMenu.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    // Cacher le menu
    function hideMenu() {
        arenaMenu.classList.add('hidden');
        document.body.style.overflow = 'auto';
        
        // Envoyer message à FiveM
        fetch(`https://${resourceName}/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        }).catch(error => {
            console.error('Erreur fermeture menu:', error);
        });
    }

    // Rejoindre une arène
    function joinArena(arenaIndex) {
        console.log('Tentative de rejoindre arène:', arenaIndex);
        
        if (!arenaIndex || arenaIndex < 1 || arenaIndex > 4) {
            console.error('Index arène invalide:', arenaIndex);
            return;
        }
        
        fetch(`https://${resourceName}/selectArena`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                index: parseInt(arenaIndex)
            })
        }).then(response => {
            console.log('Réponse sélection arène:', response.status);
            hideMenu();
        }).catch(error => {
            console.error('Erreur sélection arène:', error);
            hideMenu();
        });
    }

    // Event listeners pour les cartes d'arène
    arenaCards.forEach(card => {
        const arenaIndex = parseInt(card.dataset.arena);
        
        card.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('Carte arène cliquée:', arenaIndex);
            joinArena(arenaIndex);
        });
    });

    // Event listeners pour les boutons rejoindre
    joinBtns.forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            const card = e.target.closest('.arena-card');
            const arenaIndex = parseInt(card.dataset.arena);
            console.log('Bouton rejoindre cliqué:', arenaIndex);
            joinArena(arenaIndex);
        });
    });

    // Bouton fermer
    closeBtn.addEventListener('click', function(e) {
        e.preventDefault();
        console.log('Bouton fermer cliqué');
        hideMenu();
    });

    // Fermer avec Échap
    document.addEventListener('keydown', function(event) {
        if (event.key === 'Escape') {
            hideMenu();
        }
    });

    // Fermer en cliquant sur l'arrière-plan
    arenaMenu.addEventListener('click', function(e) {
        if (e.target === arenaMenu) {
            hideMenu();
        }
    });

    console.log('Tous les event listeners ajoutés');
});

