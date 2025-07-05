const express = require('express');
const router = express.Router();
const pool = require('../db');

// Add a sale
router.post('/add', async (req, res) => {
  const {
    vehicle_id,
    customer_id,
    sale_date,
    sale_price,
    payment_method,
    finance_term,
    notes
  } = req.body;

  try {
    // Get the last sale_id from the database
    const lastSale = await pool.query('SELECT sale_id FROM sales ORDER BY sale_id DESC LIMIT 1');

    let newSaleId;
    if (lastSale.rows.length > 0) {
      const lastSaleId = lastSale.rows[0].sale_id; // e.g., "S1105"
      const numericPart = parseInt(lastSaleId.substring(1), 10); // Extract numeric part (1105)
      newSaleId = `S${numericPart + 1}`; // Increment and prepend "S"
    } else {
      newSaleId = 'S1'; // Default for the first sale
    }

    // Insert the new sale into the database
    const result = await pool.query(
      `INSERT INTO sales (
         sale_id, vehicle_id, customer_id, sale_date, sale_price,
         payment_method, finance_term, notes
       ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
       RETURNING *`,
      [newSaleId, vehicle_id, customer_id, sale_date, sale_price, payment_method, finance_term, notes]
    );

    res.status(201).json({ message: 'Sale recorded', sale: result.rows[0] });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Get all sales
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM sales');
    res.json(result.rows);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});


module.exports = router;
