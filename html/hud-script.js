document.addEventListener('DOMContentLoaded', function() {
    console.log('PVP HUD Script loaded');

    // Éléments DOM
    const hudElement = document.getElementById('pvpHud');
    const killsElement = document.getElementById('killsCount');
    const deathsElement = document.getElementById('deathsCount');
    const assistsElement = document.getElementById('assistsCount');
    const kdaElement = document.getElementById('kdaRatio');
    const kdaFillElement = document.getElementById('kdaFill');
    const arenaNameElement = document.getElementById('arenaName');

    // État du HUD
    let currentStats = {
        kills: 0,
        deaths: 0,
        assists: 0,
        kda: 0.00
    };

    let isVisible = false;

    // Nom de la ressource
    const resourceName = 'pvp_pack';

    // Écouter les messages de FiveM
    window.addEventListener('message', function(event) {
        const data = event.data;
        console.log('HUD Message reçu:', data);
        
        switch(data.action) {
            case 'showHud':
                showHud(data.arenaName || 'ARENA');
                break;
                
            case 'hideHud':
                hideHud();
                break;
                
            case 'updateStats':
                updateStats(data.kills || 0, data.deaths || 0, data.assists || 0);
                break;
                
            case 'updateKill':
                animateStatUpdate('kills', data.kills || 0);
                break;
                
            case 'updateDeath':
                animateStatUpdate('deaths', data.deaths || 0);
                break;
                
            case 'updateAssist':
                animateStatUpdate('assists', data.assists || 0);
                break;
        }
    });

    // Afficher le HUD
    function showHud(arenaName = 'ARENA') {
        if (isVisible) return;
        
        isVisible = true;
        arenaNameElement.textContent = arenaName.toUpperCase();
        hudElement.classList.remove('hidden');
        
        // Animation d'entrée
        hudElement.style.animation = 'slideInLeft 0.5s ease-out';
        
        console.log('HUD affiché pour l\'arène:', arenaName);
    }

    // Cacher le HUD
    function hideHud() {
        if (!isVisible) return;
        
        isVisible = false;
        
        // Animation de sortie avant de cacher
        hudElement.style.animation = 'slideOutLeft 0.3s ease-in';
        
        setTimeout(() => {
            hudElement.classList.add('hidden');
            // Reset des stats après l'animation
            resetStats();
        }, 300);
        console.log('HUD masqué');
    }

    // Mettre à jour les statistiques
    function updateStats(kills, deaths, assists) {
        // Vérifier les changements pour les animations
        const killsChanged = kills !== currentStats.kills;
        const deathsChanged = deaths !== currentStats.deaths;
        const assistsChanged = assists !== currentStats.assists;

        // Mettre à jour les valeurs
        currentStats.kills = kills;
        currentStats.deaths = deaths;
        currentStats.assists = assists;

        // Calculer KDA
        calculateKDA();

        // Mettre à jour l'affichage
        updateDisplay(killsChanged, deathsChanged, assistsChanged);
    }

    // Animation pour une stat spécifique
    function animateStatUpdate(statType, newValue) {
        const statItem = document.querySelector(`.stat-item.${statType}`);
        const statValue = document.getElementById(`${statType}Count`);
        
        if (statItem && statValue) {
            // Animation de la valeur
            statValue.classList.add('updated');
            statValue.textContent = newValue;
            
            // Animation de l'item
            statItem.classList.add(`${statType.slice(0, -1)}-update`);
            
            // Nettoyer les classes après l'animation
            setTimeout(() => {
                statValue.classList.remove('updated');
                statItem.classList.remove(`${statType.slice(0, -1)}-update`);
            }, 500);
        }
        
        // Mettre à jour les stats internes
        currentStats[statType] = newValue;
        calculateKDA();
        updateKDADisplay();
    }

    // Calculer le ratio KDA
    function calculateKDA() {
        const { kills, deaths, assists } = currentStats;
        
        if (deaths === 0) {
            currentStats.kda = kills + assists;
        } else {
            currentStats.kda = parseFloat(((kills + assists) / deaths).toFixed(2));
        }
    }

    // Mettre à jour l'affichage
    function updateDisplay(killsChanged, deathsChanged, assistsChanged) {
        // Mettre à jour les compteurs avec animations si nécessaire
        if (killsChanged) {
            killsElement.textContent = currentStats.kills;
            killsElement.classList.add('updated');
            setTimeout(() => killsElement.classList.remove('updated'), 500);
        }
        
        if (deathsChanged) {
            deathsElement.textContent = currentStats.deaths;
            deathsElement.classList.add('updated');
            setTimeout(() => deathsElement.classList.remove('updated'), 500);
        }
        
        if (assistsChanged) {
            assistsElement.textContent = currentStats.assists;
            assistsElement.classList.add('updated');
            setTimeout(() => assistsElement.classList.remove('updated'), 500);
        }

        updateKDADisplay();
    }

    // Mettre à jour l'affichage KDA
    function updateKDADisplay() {
        kdaElement.textContent = currentStats.kda.toFixed(2);
        
        // Calculer le pourcentage pour la barre (max 5.0 = 100%)
        const percentage = Math.min((currentStats.kda / 5.0) * 100, 100);
        kdaFillElement.style.width = percentage + '%';
        
        // Changer la couleur selon le ratio
        let color = '#ff4444'; // Rouge par défaut
        if (currentStats.kda >= 2.0) {
            color = '#00ff88'; // Vert pour bon ratio
        } else if (currentStats.kda >= 1.0) {
            color = '#ffaa00'; // Orange pour ratio moyen
        }
        
        kdaFillElement.style.background = `linear-gradient(90deg, ${color}, ${color}88)`;
        kdaElement.style.color = color;
    }

    // Reset des statistiques
    function resetStats() {
        currentStats = {
            kills: 0,
            deaths: 0,
            assists: 0,
            kda: 0.00
        };
        
        killsElement.textContent = '0';
        deathsElement.textContent = '0';
        assistsElement.textContent = '0';
        kdaElement.textContent = '0.00';
        kdaFillElement.style.width = '0%';
        arenaNameElement.textContent = 'ARENA';
    }

    // Initialisation
    console.log('HUD System initialized');
});