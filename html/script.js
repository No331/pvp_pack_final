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
        console.log('PVP Menu - Message reçu:', data);
        
        if (data.action === 'openArenaMenu') {
            console.log('PVP Menu - Ouverture du menu arène');
            console.log('PVP Menu - Arènes reçues:', data.arenas);
            showMenu();
        } else if (data.action === 'closeArenaMenu') {
            console.log('PVP Menu - Fermeture du menu arène');
            hideMenu();
        }
    });

    // Afficher le menu
    function showMenu() {
        console.log('PVP Menu - Affichage du menu');
        arenaMenu.classList.remove('hidden');
        document.body.style.overflow = 'hidden';
    }

    // Cacher le menu
    function hideMenu() {
        console.log('PVP Menu - Masquage du menu');
        arenaMenu.classList.add('hidden');
        document.body.style.overflow = 'auto';
        
        // Envoyer message à FiveM
        fetch(`https://pvp_pack/closeMenu`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({})
        }).catch(error => {
            console.error('PVP Menu - Erreur fermeture menu:', error);
        });
    }

    // Rejoindre une arène
    function joinArena(arenaIndex) {
        console.log('PVP Menu - Tentative de rejoindre arène:', arenaIndex);
        
        if (!arenaIndex || arenaIndex < 1 || arenaIndex > 4) {
            console.error('PVP Menu - Index arène invalide:', arenaIndex);
            return;
        }
        
        fetch(`https://pvp_pack/selectArena`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                index: parseInt(arenaIndex)
            })
        }).then(response => {
            console.log('PVP Menu - Réponse sélection arène:', response.status);
            hideMenu();
        }).catch(error => {
            console.error('PVP Menu - Erreur sélection arène:', error);
            hideMenu();
        });
    }

    // Event listeners pour les cartes d'arène
    arenaCards.forEach(card => {
        const arenaIndex = parseInt(card.dataset.arena);
        
        card.addEventListener('click', function(e) {
            e.preventDefault();
            console.log('PVP Menu - Carte arène cliquée:', arenaIndex);
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
            console.log('PVP Menu - Bouton rejoindre cliqué:', arenaIndex);
            joinArena(arenaIndex);
        });
    });

    // Bouton fermer
    closeBtn.addEventListener('click', function(e) {
        e.preventDefault();
        console.log('PVP Menu - Bouton fermer cliqué');
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

    console.log('PVP Menu - Tous les event listeners ajoutés');
});

