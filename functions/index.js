const functions = require("firebase-functions");
const express = require("express");
const admin = require("firebase-admin");
const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

admin.initializeApp();
const db = admin.database();
const app = express();

app.post("/webhook", express.json({type: "application/json"}),
    async (request, response) => {
      const sig = request.headers["stripe-signature"];

      let event;
      try {
        event = stripe.webhooks.constructEvent(request.rawBody,
            sig, process.env.STRIPE_WEBHOOK_SECRET);
      } catch (err) {
        console.error("⚠️  Webhook signature verification failed.",
            err.message);
        return response.status(400).send(`Webhook Error: ${err.message}`);
      }

      // Handle the event
      switch (event.type) {
        case "checkout.session.completed": {
          // Listening to Checkout Session completion
          const session = event.data.object;
          console.log("Checkout Session was completed!", session);

          const sessionId = session.id; // Use the sessionId
          const paymentIntentId = session.payment_intent;
          const amountTotal = session.amount_total || 0;
          const currency = session.currency || "USD";
          const userId = session.client_reference_id || "unknown_user";

          // Save the payment information to Realtime Database using sessionId
          await db.ref("payments/" + sessionId).set({
            userId: userId,
            paymentIntentId: paymentIntentId,
            amount_total: amountTotal,
            currency: currency,
            status: "completed",
            created: admin.database.ServerValue.TIMESTAMP,
          });

          break;
        }
        case "payment_method.attached": {
          const paymentMethod = event.data.object;
          console.log("PaymentMethod was attached!", paymentMethod);
          break;
        }
        default: {
          console.log(`Unhandled event type ${event.type}`);
        }
      }

      // Return a response to acknowledge receipt of the event
      response.json({received: true});
    });

exports.newStripeWebhook = functions.https.onRequest(app);


// const functions = require("firebase-functions");
// const express = require("express");
// const admin = require("firebase-admin");
// const stripe = require("stripe")(process.env.STRIPE_SECRET_KEY);

// admin.initializeApp();
// const db = admin.firestore();
// const app = express();

// app.post("/webhook", express.json({type: "application/json"}),
//     async (request, response) => {
//       const sig = request.headers["stripe-signature"];

//       let event;
//       try {
//         event = stripe.webhooks.constructEvent(request.rawBody,
//             sig, process.env.STRIPE_WEBHOOK_SECRET);
//       } catch (err) {
//         console.error("⚠️  Webhook signature verification failed.",
//             err.message);
//         return response.status(400).send(`Webhook Error: ${err.message}`);
//       }

//       // Save the event data to Firestore
//       await db.collection("stripeEvents").add(event);

//       // Handle the event
//       switch (event.type) {
//         case "checkout.session.completed": {
//           // Listening to Checkout Session completion
//           const session = event.data.object;
//           console.log("Checkout Session was completed!", session);

//           const sessionId = session.id; // Use the sessionId
//           const paymentIntentId = session.payment_intent;
//           const amountTotal = session.amount_total || 0;
//           const currency = session.currency || "USD";
//           const userId = session.client_reference_id || "unknown_user";

//           // Save the payment information to Firestore using sessionId
//           await db.collection("payments").doc(sessionId).set({
//             userId: userId,
//             paymentIntentId: paymentIntentId,
//             amount_total: amountTotal,
//             currency: currency,
//             status: "completed",
//             created: admin.firestore.FieldValue.serverTimestamp(),
//           });

//           break;
//         }
//         case "payment_method.attached": {
//           const paymentMethod = event.data.object;
//           console.log("PaymentMethod was attached!", paymentMethod);
//           break;
//         }
//         default: {
//           console.log(`Unhandled event type ${event.type}`);
//         }
//       }

//       // Return a response to acknowledge receipt of the event
//       response.json({received: true});
//     });

// exports.newStripeWebhook = functions.https.onRequest(app);

