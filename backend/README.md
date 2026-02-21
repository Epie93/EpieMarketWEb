# EpieMarket - Backend Stripe

## Où mettre la clé secrète Stripe ?

**Fichier : `backend/.env`**

```
STRIPE_SECRET_KEY=sk_live_xxx_REMPLACE_PAR_TA_CLE
```

Remplace `sk_live_xxx...` par ta clé secrète Stripe.

## Lancer le backend

1. Ouvre un terminal dans le dossier `backend/`
2. `npm install`
3. `npm start`

Le serveur écoute sur `http://localhost:3001`.

## Lancer le site

Dans un autre terminal, à la racine du projet :
- `.\server.ps1` (PowerShell) ou ouvre `index.html` via un serveur

Pense à configurer `STRIPE_BACKEND_URL` dans `index.html` si ton backend n'est pas sur localhost:3001.
