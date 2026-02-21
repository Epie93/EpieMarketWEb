const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const Stripe = require('stripe');
const key = (process.env.STRIPE_SECRET_KEY || '').trim().replace(/^\uFEFF/, '');
if (!key || !key.startsWith('sk_')) {
  console.log('INVALID');
  process.exit(1);
}
const stripe = new Stripe(key);
stripe.customers.list({ limit: 1 })
  .then(() => { console.log('VALID'); process.exit(0); })
  .catch(() => { console.log('INVALID'); process.exit(1); });
