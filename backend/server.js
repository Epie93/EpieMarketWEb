/**
 * EPIEMARKET - Backend Stripe
 * 
 * Ce serveur crée des sessions Stripe Checkout pour les paiements carte.
 * 
 * OÙ METTRE LA CLÉ SECRÈTE Stripe ?
 * -> Dans le fichier .env à la racine du dossier backend/
 * -> Ligne: STRIPE_SECRET_KEY=sk_live_xxxx...
 * -> Ne JAMAIS mettre la clé secrète dans le code ou le frontend !
 */

const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const cors = require('cors');
const Stripe = require('stripe');

const app = express();
app.use(cors({ origin: true }));
app.use(express.json());

// Cle secrete - trim + suppression BOM/caracteres invisibles
let secretKey = (process.env.STRIPE_SECRET_KEY || '').trim().replace(/^\uFEFF/, '');
if (!secretKey || !secretKey.startsWith('sk_')) {
  console.error('ERREUR: STRIPE_SECRET_KEY manquante ou invalide dans backend/.env');
  process.exit(1);
}

const stripe = new Stripe(secretKey);

app.get('/health', (req, res) => {
  res.json({ ok: true });
});

app.post('/create-checkout-session', async (req, res) => {
  try {
    const { email, name, address, lineItems, totalCents, successUrl, cancelUrl } = req.body;

    if (!lineItems || !totalCents || totalCents < 50) {
      return res.status(400).json({ error: 'Donnees invalides' });
    }

    const baseUrl = req.headers.origin || 'http://localhost:8000';
    const succ = successUrl || `${baseUrl}/?stripe=success&session_id={CHECKOUT_SESSION_ID}`;
    const canc = cancelUrl || baseUrl;

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      line_items: [{
        price_data: {
          currency: 'eur',
          product_data: {
            name: `${lineItems.map(i => `${i.productName} (${i.plan})`).join(' + ')}`,
            description: `EpieMarket - ${lineItems.length} article(s)`,
          },
          unit_amount: totalCents,
        },
        quantity: 1,
      }],
      mode: 'payment',
      success_url: succ,
      cancel_url: canc,
      customer_email: email,
      metadata: {
        customerName: name,
        address: address || '',
        items: JSON.stringify(lineItems),
      },
    });

    if (!session.url) {
      return res.status(500).json({ error: 'Stripe na pas retourne de URL' });
    }
    res.json({ url: session.url });
  } catch (err) {
    console.error('Stripe error:', err);
    const msg = err.type === 'StripeAuthenticationError' 
      ? 'Cle secrete invalide. Verifie backend/.env - utilise la cle associee a ta cle publique dans le Dashboard Stripe.'
      : (err.message || 'Erreur Stripe');
    res.status(500).json({ error: msg });
  }
});

// Servir le frontend (index.html, success.html, adminepie.html) pour deploy Render
app.use(express.static(path.join(__dirname, '..')));

const PORT = process.env.PORT || 3001;
app.listen(PORT, async () => {
  console.log(`[OK] Backend Stripe sur http://localhost:${PORT}`);
  try {
    await stripe.customers.list({ limit: 1 });
    console.log('');
    console.log('>>> CLE PRIVEE ACCEPTEE <<<');
    console.log('');
  } catch (e) {
    console.log('');
    console.log('>>> CLE PRIVEE NON ACCEPTEE <<<');
    console.error('[ERREUR]', e.message);
    console.error('-> Va sur dashboard.stripe.com/apikeys');
    console.error('-> Revele la Secret key associee a ta cle publique');
    console.error('-> Copie-la dans backend/.env (sans espaces)');
    console.log('');
  }
});
